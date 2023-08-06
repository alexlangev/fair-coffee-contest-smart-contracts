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

    event ParticipationAdded(
        address indexed buyer,
        uint256 participationsAdded,
        uint256 requestId
    );
    event ParticipationRedeemed();
    event RequestSent(
        uint256 indexed requestId,
        uint32 numWords,
        address indexed user
    );

    function setUp() external {
        DeployContest deployer = new DeployContest();
        (contest, configHelper) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        (
            subscriptionId,
            gasLane,
            callbackGasLimit,
            aggregatorV3Interface,
            vrfCoordinatorV2,
            link,
            deployerKey
        ) = configHelper.s_activeNetworkConfig();
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
    // VRF FUNCTIONS ////////////
    /////////////////////////////
    function testRequestRandomWordsRequestId() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(contest));
        emit RequestSent(1, 1, msg.sender); // hardcoded values
        uint256 requestId = contest.requestRandomWords(1);
        vm.stopPrank();
        assert(requestId != 0);
    }

    function testFulfillRandomWords() public {
        vm.startPrank(PLAYER);
        uint256 requestId1 = contest.requestRandomWords(1);
        uint256 requestId2 = contest.requestRandomWords(5);
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            1,
            address(contest)
        );
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            2,
            address(contest)
        );
        (bool requestFulfiled1, uint256[] memory randomWords1, ) = contest
            .getRequestStatus(requestId1);
        (bool requestFulfiled2, uint256[] memory randomWords2, ) = contest
            .getRequestStatus(requestId2);
        assertEq(requestFulfiled1, true);
        assertEq(requestFulfiled2, true);
        assertEq(randomWords1.length, 1);
        assertEq(randomWords2.length, 5);
        assertEq(contest.getUserUnclaimedRandomWords().length, 6);
        vm.stopPrank();
    }

    function testRevertWhenFulfillRandomWordWithInvalidRequestId() public {
        vm.startPrank(PLAYER);
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            1,
            address(contest)
        );
        vm.stopPrank();
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
        emit ParticipationAdded(address(PLAYER), 1, 1);
        uint256 requestId = contest.buyCofees{value: 1 ether}(1);
        vm.stopPrank();
    }

    function testContestBuyingMultipleCoffees() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(contest));
        emit ParticipationAdded(address(PLAYER), 5, 1);
        contest.buyCofees{value: 1 ether}(5);
        vm.stopPrank();
    }

    /////////////////////////////
    // Redeem Participation /////
    /////////////////////////////

    function testContestRevertWhenRedeemingRandomNumberWithoutAny() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(Contest.Contest__NotEnoughParticipations.selector);
        contest.redeemParticipation();
        vm.stopPrank();
    }

    function testEventEmittedWhenRedeemingParticipation() public {
        vm.startPrank(PLAYER);
        contest.buyCofees{value: 1 ether}(1);

        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            1,
            address(contest)
        );

        vm.expectEmit(true, false, false, false, address(contest));
        emit ParticipationRedeemed();
        contest.redeemParticipation();
        vm.stopPrank();
    }
}
