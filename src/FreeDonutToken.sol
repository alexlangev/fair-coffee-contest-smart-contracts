//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// TODO should the contract be owned by the contest?
contract FreeDonutToken is ERC20 {
    string public constant TOKEN_NAME = "Free Donut Token";
    string public constant TOKEN_SYMBOL = "FDT";

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) {}
}
