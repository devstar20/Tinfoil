// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ILock {
    event Joined(
        address indexed user,
        uint256 amount,
        uint256 total
    );
    event Left(
        address indexed user,
        uint256 amount,
        uint256 total
    );

    function join(
        address user,
        uint256 amount
    ) external;

    function joinFor(
        address sender,
        address user,
        uint256 amount
    ) external;

    function leave(
        address staker,
        uint256 amount
    ) external;

    function totalStakedFor(address addr) external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function token() external view returns (address);

    
}
