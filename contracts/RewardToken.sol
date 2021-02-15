pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is Ownable, ERC20 {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 initialSupply
    ) public ERC20(_tokenSymbol, _tokenName) {
        require(initialSupply > 0, "Tinfoil Reward: initialSupply is zero");
        _mint(msg.sender, initialSupply);
    }
}
