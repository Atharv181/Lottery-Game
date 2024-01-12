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

    address public PLAYER = makeAddr("PLAYER");

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle,helperConfig) = deployRaffle.run();

        (entranceFee, 
        interval,
        vrfCoordinator,
        keyHash,
        subscriptionId, 
        callbackGasLimit) = helperConfig.activeNetworkConfig();
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
        vm.deal(PLAYER, entryFee);
        raffle.enterRaffle{value: entryFee}();
        assert(raffle.getPlayerCount() == 1);
        assert(raffle.getPlayerByIndex(0) == PLAYER);
    }

    function testEmitEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER, entranceFee);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}