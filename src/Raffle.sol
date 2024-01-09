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
error Raffle__CALCULATINGWINNER();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

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
    RaffleState private s_raffleState;
    
    enum RaffleState{
        OPEN,
        CALCULATING
    }
    //////////////
    /// Events /// 
    //////////////

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 requestId);
    
    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator,bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator){
        i_raffleEntranceFee = entranceFee;
        i_interval = interval;
        s_lastimestamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    /////////////////
    /// Functions /// 
    /////////////////

    function enterRaffle() public payable{
        if (i_raffleEntranceFee > msg.value) {
            revert Raffle__NOTENOUGHSENT();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CALCULATINGWINNER(); 
        }
        s_players.push(msg.sender);
        emit RaffleEnter(msg.sender);
    }

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */){
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_RANDOM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /* _requestId */, uint256[] memory _randomWords) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address winner = s_players[indexOfWinner];
        s_raffleState = RaffleState.OPEN;
        s_players = new address[](0);
        s_lastimestamp = block.timestamp;
        (bool success,) = winner.call{value:address(this).balance}("");
        if (!success){
            revert Raffle__TRANSFERFAILED();
        }
        emit WinnerPicked(winner);
    }

    ////////////////////////
    /// Getter Functions /// 
    ////////////////////////

    function getEntranceFee() external view returns(uint256){
        return i_raffleEntranceFee;
    }
}

