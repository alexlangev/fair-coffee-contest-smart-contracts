//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Contest} from "../../src/Contest.sol";
import {FreeCoffeeToken} from "../../src/FreeCoffeeToken.sol";
import {FreeDonutToken} from "../../src/FreeDonutToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "../mocks/MockAggregatorV3Interface.sol";

contract ContestTest is StdCheats, Test {
    ///////////////////////
    // Anvil configs //////
    ///////////////////////
    // Replace all of this in a helper config contract

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public constant DEFAULT_ANVIL_USER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public constant STARTING_USER_BALANCE = 1 ether;
    uint256 public constant COFFEE_PRICE_IN_USD = 150; // in cents 150 = 1.50 $
    uint256 public constant TOTAL_NUMBER_OF_FREE_COFFEES = 50e3;
    uint256 public constant TOTAL_NUMBER_OF_FREE_DONUTS = 50e3;

    FreeCoffeeToken public s_freeCoffeeToken;
    FreeDonutToken public s_freeDonutToken;
    Contest public s_contest;
    MockV3Aggregator public s_ethUsdPriceFeed;

    //temp vrf stuff
    // vrfCoordinatorV2: address(vrfCoordinatorV2Mock),

    function setUp() external {
        vm.startBroadcast(DEFAULT_ANVIL_KEY);
        s_freeCoffeeToken = new FreeCoffeeToken();
        s_freeDonutToken = new FreeDonutToken();
        s_ethUsdPriceFeed = new MockV3Aggregator(8, 1852 * 1e8);

        s_contest = new Contest(
            COFFEE_PRICE_IN_USD,
            TOTAL_NUMBER_OF_FREE_COFFEES,
            TOTAL_NUMBER_OF_FREE_DONUTS, 
            address(s_freeCoffeeToken), 
            address(s_freeDonutToken),
            address(s_ethUsdPriceFeed)
        );
        vm.stopBroadcast();
    }
}

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables  1- constants 2- immutables 3- state
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
