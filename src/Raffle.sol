// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;


error Raffle__NOTENOUGHSENT();

/** @title A sample Raffle contract 
 *  @author Atharv Bobade
 *  @notice The Raffle contract
 *  @dev Implementation of Raffle contract using chainlink VRFv2
*/
contract Raffle {

    uint256 public immutable i_raffleEntranceFee;
    address private s_recentWinner;
    address[] private s_players;

    //////////////
    /// Events /// 
    //////////////

    event RaffleEnter(address indexed player);
    
    constructor(uint256 entranceFee){
        i_raffleEntranceFee = entranceFee;
    }

    /////////////////
    /// Functions /// 
    /////////////////

    function enterRaffle() public payable{
        if (i_raffleEntranceFee > msg.value) {
            revert Raffle__NOTENOUGHSENT();
        }
        s_players.push(msg.sender);
        emit RaffleEnter(msg.sender);
    }

    function pickWinner() public {}

    ////////////////////////
    /// Getter Functions /// 
    ////////////////////////

    function getEntranceFee() external view returns(uint256){
        return i_raffleEntranceFee;
    }
}

