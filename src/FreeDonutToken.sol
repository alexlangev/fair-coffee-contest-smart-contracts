//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FreeDonutToken is ERC20Burnable, Ownable {
    string public constant TOKEN_NAME = "Free Donut Token";
    string public constant TOKEN_SYMBOL = "FDT";

    error FreeDonutToken__NotZeroAddress();
    error FreeDonutToken__MustBeGreaterThanZero();
    error FreeDonutToken__BurnAmountExceedsBalance();

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) {}

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool){
        if(_to == address(0)){
                revert FreeDonutToken__NotZeroAddress();
            }
            if(_amount <= 0) {
                revert FreeDonutToken__MustBeGreaterThanZero();
            }
            _mint(_to, _amount);
            return true;
    }
    

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert FreeDonutToken__MustBeGreaterThanZero();
        }
        if (balance < _amount) {
            revert FreeDonutToken__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }
}
