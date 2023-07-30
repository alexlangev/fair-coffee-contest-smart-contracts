//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {FreeCoffeeToken} from "./FreeCoffeeToken.sol";
import {FreeDonutToken} from "./FreeDonutToken.sol";

contract Contest {
    ///////////////////////
    // Type Declarations //
    ///////////////////////

    ///////////////////////
    // Errors /////////////
    ///////////////////////

    ///////////////////////
    // State Variables ////
    ///////////////////////
    uint256 private immutable i_TotalNumberOfFreeCoffeePrizes;
    uint256 private immutable i_TotalNumberOfFreeDonutPrizes;
    FreeCoffeeToken private immutable i_fct;
    FreeDonutToken private immutable i_fdt;

    ///////////////////////
    // Events /////////////
    ///////////////////////

    ///////////////////////
    // Functions //////////
    ///////////////////////
    constructor(
        uint256 _totalNumberOfFreeCoffeePrizes,
        uint256 _totalNumberOfFreeDonutPrizes,
        address _freeCoffeeTokenAddress,
        address _freeCoffeeDonutAddress
    ) {
        i_TotalNumberOfFreeCoffeePrizes = _totalNumberOfFreeCoffeePrizes;
        i_TotalNumberOfFreeDonutPrizes = _totalNumberOfFreeDonutPrizes;
        i_fct = FreeCoffeeToken(_freeCoffeeTokenAddress);
        i_fdt = FreeDonutToken(_freeCoffeeDonutAddress);
    }

    function getTotalNumberOfFreeCoffeePrizes() public view returns (uint256) {
        return i_TotalNumberOfFreeCoffeePrizes;
    }

    function getTotalNumberOfFreeDonutPrizes() public view returns (uint256) {
        return i_TotalNumberOfFreeDonutPrizes;
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
