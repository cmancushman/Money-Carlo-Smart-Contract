// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Simcade is Ownable {
    uint256 public GAME_FEE = 500; // gas fee paid to team wallet to validate each game
    uint256 public MAX_BET_SIZE = 100000; // maximum bet size

    uint256 totalPlayerValue = 0;
    mapping(string => bool) games; // a mapping of each game to if it is valid
    mapping(address => uint256) balances; // a mapping of each address to its balance

    constructor() {}

    /**
     * @dev Gets the balance of the smart contract.
     * @return the balance of the smart contract
     */
    function getBalance() public view returns (uint256) {
        uint256 currentBalance = address(this).balance;
        return currentBalance;
    }

    /**
     * @dev Gets the total sum of all player balances.
     * @return the total sum of all player balances
     */
    function getTotalPlayerValue() public view returns (uint256) {
        return totalPlayerValue;
    }

    /**
     * @dev Verifies that the caller of a function has sufficient funds.
     */
    modifier sufficientFunds(uint256 amount) {
        require(balances[msg.sender] >= amount, "Insufficient funds.");
        _;
    }

    /**
     * @dev Verifies that the bet size is less than the maximum bet size.
     */
    modifier betSizeIsAllowed(uint256 betSize) {
        require(betSize < MAX_BET_SIZE, "This bet is too large.");
        _;
    }

    /**
     * @dev Gets the balance of a user.
     * @return the balance of address
     */
    function getUserBalance(address adr) public view returns (uint256) {
        return balances[adr];
    }

    /**
     * @dev Deposit funds into address.
     */
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        totalPlayerValue += msg.value;
    }

    /**
     * @dev Withdraw funds from address.
     * @param withdrawlAmount the amout to be withdrawn
     */
    function withdraw(uint256 withdrawlAmount)
        public
        sufficientFunds(withdrawlAmount)
        returns (bool)
    {
        require(
            getBalance() >= withdrawlAmount,
            "Insufficient reserves to process this withdrawl."
        );
        address payable withdrawlAddress = payable(msg.sender);
        (bool sent, ) = withdrawlAddress.call{value: withdrawlAmount}("");

        if (sent) {
            balances[msg.sender] -= withdrawlAmount;
            totalPlayerValue -= withdrawlAmount;
        }
        return sent;
    }

    /**
     * @dev Initialize one player game, reduces balance and maps bet size to game id
     * @param betSize the amount of money being bet
     * @param gameId the unique id of the game
     */
    function initializeOnePlayerGame(uint256 betSize, string memory gameId)
        public
        sufficientFunds(betSize + GAME_FEE)
        betSizeIsAllowed(betSize)
    {
        require(getBalance() >= GAME_FEE, "Insufficient reserves to play game.");
        address payable gameFeeBeneficiary = payable(owner());
        (bool sent, ) = gameFeeBeneficiary.call{value: GAME_FEE}("");

        if (sent) {
            balances[msg.sender] -= (betSize + GAME_FEE);
            totalPlayerValue -= (betSize + GAME_FEE);
            games[gameId] = true;
        }
    }

    /**
     * @dev After the winner has received its earnings,
     * send the remaining balance to the contract owner's wallet.
     */
    function determineOutputOfOnePlayerGame(
        address player,
        string memory gameId,
        bool playerDidWin,
        uint256 betPayout
    ) public onlyOwner betSizeIsAllowed(betPayout) {
        require(games[gameId] == true, "Game not valid.");

        if (playerDidWin == true) {
            balances[player] += betPayout;
            totalPlayerValue += betPayout;
        }

        games[gameId] = false;
    }
}
