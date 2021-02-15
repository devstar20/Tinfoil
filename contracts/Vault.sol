// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value)
        external
        onlyOwner
        returns (bool)
    {
        return token.transfer(to, value);
    }

    function rescue(address to, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        return token.transfer(to, amount);
    }

    function rescueOthers(
        address otherToken,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        return IERC20(otherToken).transfer(to, amount);
    }
}
