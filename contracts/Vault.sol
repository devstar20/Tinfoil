// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The owner of this contract it's going to be the Farm so no external user can call it directly
// There are multiple vaults used in the Farm contract
// Initially all TIN rewards will be available in a locked vault
// From time to time, a part of the TIN rewards is moved into an unlocked vault
// When users leave the farm, a portion of this unlocked vault is distributed to them
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

    function rescueOthers(
        address otherToken,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        return IERC20(otherToken).transfer(to, amount);
    }
}
