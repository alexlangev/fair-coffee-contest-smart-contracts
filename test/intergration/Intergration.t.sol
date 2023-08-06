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

contract ContestIntergrationTest is StdCheats, Test {
    address public ALICE = makeAddr("Alice");
    address public BOB = makeAddr("Bob");
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
        vm.deal(ALICE, STARTING_USER_BALANCE);
        vm.deal(BOB, STARTING_USER_BALANCE);

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

    // deploy, no one buys => no lottery
    function testContestRunsWithoutAnyParticipants() public {}
    // deploy, lottery first day, lottery second day, end after 30 days
}
