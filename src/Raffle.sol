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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/dev/VRFConsumerBaseV2.sol";

error Raffle__NOTENOUGHSENT();
error Raffle__NOTENOUGHTIMEPASSED();
error Raffle__TRANSFERFAILED();

/** @title A sample Raffle contract 
 *  @author Atharv Bobade
 *  @notice The Raffle contract
 *  @dev Implementation of Raffle contract using chainlink VRFv2
*/
contract Raffle is VRFConsumerBaseV2{

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_RANDOM_WORDS = 2;

    uint256 private immutable i_raffleEntranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastimestamp;
    address private s_recentWinner;
    address[] private s_players;
    
    
    //////////////
    /// Events /// 
    //////////////

    event RaffleEnter(address indexed player);
    
    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator,bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator){
        i_raffleEntranceFee = entranceFee;
        i_interval = interval;
        s_lastimestamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
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

    function pickWinner() external {
        if (block.timestamp - s_lastimestamp < i_interval) {
            revert Raffle__NOTENOUGHTIMEPASSED();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_RANDOM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address winner = s_players[indexOfWinner];
        (bool success,) = winner.call{value:address(this).balance}("");
        if (!success){
            revert Raffle__TRANSFERFAILED();
        }
    }

    ////////////////////////
    /// Getter Functions /// 
    ////////////////////////

    function getEntranceFee() external view returns(uint256){
        return i_raffleEntranceFee;
    }
}

