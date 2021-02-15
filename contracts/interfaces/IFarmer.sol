// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IFarmer {
    /*events*/
    event FarmAdded(address indexed owner, address indexed farm, address asset);
    event FarmJoined(
        address indexed user,
        address indexed asset,
        uint256 amount
    );
    event FarmLeft(address indexed user, address indexed asset, uint256 amount);

    /*BASE METHODS*/
    function addFarm(address asset, address farm) external;

    function join(address[] calldata assets, uint256[] calldata values)
        external;

    function leave(address[] calldata assets, uint256[] calldata values)
        external;

    /*GETTERS METHODS - single farm*/
    function getJoined(address asset) external view returns (uint256);

    function getCurrentUserRewards(
        address[] calldata assets,
        uint256[] calldata values
    ) external returns (address[] memory, uint256[] memory);

    function getFarmClaimedRewards(address asset)
        external
        view
        returns (uint256);

    /*GETTERS METHODS - multiple farms*/
    function getAllFarmsClaimedRewards()
        external
        view
        returns (address[] memory, uint256[] memory);

    function getAllFarmsJoined()
        external
        view
        returns (address[] memory, uint256[] memory);
}
