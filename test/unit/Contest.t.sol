//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Contest} from "../../src/Contest.sol";
import {FreeCoffeeToken} from "../../src/FreeCoffeeToken.sol";
import {FreeDonutToken} from "../../src/FreeDonutToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "../mocks/MockAggregatorV3Interface.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {ConfigHelper} from "../../script/ConfigHelper.s.sol";
import {DeployContest} from "../../script/DeployContest.s.sol";

contract ContestTest is StdCheats, Test {
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    Contest public contest;
    ConfigHelper public configHelper;

    uint64 subscriptionId;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    address aggregatorV3Interface;
    address vrfCoordinatorV2;
    address link;
    uint256 deployerKey;

    event ParticipationAdded(address buyer, uint256 participationsAdded);
    event ParticipationRedeemed();
    event RequestSent(uint256 requestId, uint32 numWords);

    function setUp() external {
        DeployContest deployer = new DeployContest();
        (contest, configHelper) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        (subscriptionId, gasLane, callbackGasLimit, aggregatorV3Interface, vrfCoordinatorV2, link, deployerKey) =
            configHelper.s_activeNetworkConfig();
    }


    /////////////////////////////
    // Initial state ////////////
    /////////////////////////////
    function testInitialStateAfterDeployment() public {
        assert(contest.getContestStatus() == Contest.Status.Open);
        assert(contest.getDailyLotteryParticipants().length == 0);
        assertEq(contest.getUsdCoffeePrice(), 150);
        assertEq(contest.getTotalNumberOfFreeCoffeePrizes(), 50000);
        assertEq(contest.getTotalNumberOfFreeDonutPrizes(), 50000);
    }


    /////////////////////////////
    // Prices ///////////////////
    /////////////////////////////
    function testGetLatestUsdPrice() public {
        uint256 latestPrice = contest.getLatestEthUsdPrice();
        assert(latestPrice > 0);
        assertEq(contest.getLatestEthUsdPrice(), 1852e8);
    }

    function testGetEthCoffeePrice() public view {
        uint256 ethCoffeePrice = contest.getEthCoffeePrice();
        assert(ethCoffeePrice > 0);
    }


    /////////////////////////////
    // Buying coffees ///////////
    /////////////////////////////
    function testContestRevertWhenNotEnoughEth() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(Contest.Contest__NotEnoughEthToBuyCoffee.selector);
        contest.buyCofees{value: 1 wei}(1);
        vm.stopPrank();
    }

    function testContestRevertWhenBuyingInvalidNumberOfCoffees() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(Contest.Contest__InvalidNumberOfCoffees.selector);
        contest.buyCofees{value: 1 ether}(0);
        vm.expectRevert(Contest.Contest__InvalidNumberOfCoffees.selector);
        contest.buyCofees{value: 1 ether}(6);
        vm.stopPrank();
    }

    function testContestBuyingOneCoffee() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(contest));
        emit ParticipationAdded(PLAYER, 1);
        contest.buyCofees{value: 1 ether}(1);
        assertEq(contest.getParticipationCount(), 1);
        vm.stopPrank();
    }

    function testContestBuyingMultipleCoffees() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(contest));
        emit ParticipationAdded(PLAYER, 5);
        contest.buyCofees{value: 1 ether}(5);
        assertEq(contest.getParticipationCount(), 5);
        vm.stopPrank();
    }

    /////////////////////////////
    // Redeem Participation /////
    /////////////////////////////
    function testContestRevertWhenRedeemingParticipationWithNoParticipations() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(Contest.Contest__NotEnoughParticipations.selector);
        contest.redeemParticipation();
        vm.stopPrank();
    }

    function testEventEmittedWhenRedeemingParticipation() public{
        vm.startPrank(PLAYER);
        contest.buyCofees{value: 1 ether}(1);
        vm.expectEmit(true, false, false, false, address(contest));
        emit ParticipationRedeemed();
        contest.redeemParticipation();
        vm.stopPrank();
    }

    /////////////////////////////
    // VRF FUNCTIONS ////////////
    /////////////////////////////
    function testRequestRandomWordsRequestId() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(contest));
        emit RequestSent(1,1);// hardcoded values
        uint256 requestId = contest.requestRandomWords(); 
        vm.stopPrank();
        assert(requestId != 0);
    }

    function testFulfillRandomWords() public {
        vm.startPrank(PLAYER);
        uint256 requestId = contest.requestRandomWords(); 
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(1, address(contest));
        vm.stopPrank();
        (bool requestFulfiled, uint256 randomWord) = contest.getRequestStatus(requestId);
        assertEq(requestFulfiled, true);
        assert(randomWord != uint256(0));
    }
}