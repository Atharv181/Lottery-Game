//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {

    event RaffleEnter(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee; 
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId; 
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("PLAYER");

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle,helperConfig) = deployRaffle.run();

        (entranceFee, 
        interval,
        vrfCoordinator,
        keyHash,
        subscriptionId, 
        callbackGasLimit,
        link) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, entranceFee);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testEnterRaffleWhenYouDontSendEnoughEth() public {
        uint256 entryFee = raffle.getEntranceFee();
        vm.assume(entryFee > 1);
        vm.expectRevert();
        raffle.enterRaffle{value: entryFee - 1}();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        uint256 entryFee = raffle.getEntranceFee();
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        assert(raffle.getPlayerCount() == 1);
        assert(raffle.getPlayerByIndex(0) == PLAYER);
    }

    function testEmitEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER,  1 ether);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__CALCULATINGWINNER.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }
}