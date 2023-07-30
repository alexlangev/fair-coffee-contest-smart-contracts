//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Contest} from "../../src/Contest.sol";
import {FreeCoffeeToken} from "../../src/FreeCoffeeToken.sol";
import {FreeDonutToken} from "../../src/FreeDonutToken.sol";
import {Contest} from "../../src/Contest.sol";

contract ContestTest is Test {
    // Replace all of this in a helper config contract
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public constant TOTAL_NUMBER_OF_FREE_COFFEES = 50e3;
    uint256 public constant TOTAL_NUMBER_OF_FREE_DONUTS = 50e3;

    FreeCoffeeToken public s_freeCoffeeToken;
    FreeDonutToken public s_freeDonutToken;
    Contest public s_contest;

    function setUp() external {
        vm.startBroadcast(DEFAULT_ANVIL_KEY);
        s_freeCoffeeToken = new FreeCoffeeToken();
        s_freeDonutToken = new FreeDonutToken();
        s_contest = new Contest(
            TOTAL_NUMBER_OF_FREE_COFFEES,
            TOTAL_NUMBER_OF_FREE_DONUTS, 
            address(s_freeCoffeeToken), 
            address(s_freeDonutToken)
        );
        vm.stopBroadcast();
    }

    function testContestInitialState() public {
        uint256 _numCoffeePrizes = s_contest.getTotalNumberOfFreeCoffeePrizes();
        uint256 _numDonutPrizes = s_contest.getTotalNumberOfFreeDonutPrizes();

        assertEq(TOTAL_NUMBER_OF_FREE_COFFEES, _numCoffeePrizes);
        assertEq(TOTAL_NUMBER_OF_FREE_DONUTS, _numDonutPrizes);
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
