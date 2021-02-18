// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFarmer.sol";
import "./Farm.sol";

// This contract aggregates more similar farms
// Easier for the UI to get all the things needed 
// Easier for the users to interact with farms
/** @title BSC Farmer */
contract Farmer is Ownable, IFarmer {
    mapping(address => address) public farms;
    address[] public assets;

    constructor() public {}

    /**
        @dev add farm to farmer
     */
    function addFarm(address asset, address farm) public override onlyOwner {
        require(asset != address(0), "asset is invalid");
        require(farm != address(0), "farm is invalid");

        farms[asset] = farm;
        assets.push(asset);

        emit FarmAdded(msg.sender, farm, asset);
    }

    /**
        @dev join a farm
     */
    function join(address[] calldata _assets, uint256[] calldata values)
        external
        override
    {
        require(
            _assets.length == values.length,
            "assets and values have different length"
        );
        require(_assets.length > 0, "assets is empty");
        require(values.length > 0, "values is empty");

        for (uint8 i = 0; i < _assets.length; i++) {
            Farm(farms[_assets[i]]).join(msg.sender, values[i]);

            emit FarmJoined(msg.sender, _assets[i], values[i]);
        }
    }

    /**
        @dev leave farm
     */
    function leave(address[] calldata _assets, uint256[] calldata values)
        external
        override
    {
        require(
            _assets.length == values.length,
            "assets and values have different length"
        );
        require(_assets.length > 0, "assets is empty");
        require(values.length > 0, "values is empty");

        for (uint8 i = 0; i < _assets.length; i++) {
            Farm(farms[_assets[i]]).leave(msg.sender, values[i]);

            emit FarmLeft(msg.sender, _assets[i], values[i]);
        }
    }

    /**
        @dev get joined amount for farm
    */
    function getJoined(address asset) public view override returns (uint256) {
        return Farm(farms[asset]).totalStakedFor(msg.sender);
    }

    /**
        @dev get current eligible rewards from all farms
     */
    function getCurrentUserRewards(
        address[] calldata _assets,
        uint256[] calldata values
    ) external override returns (address[] memory, uint256[] memory) {
        require(
            _assets.length == values.length,
            "assets and values have different length"
        );
        require(_assets.length > 0, "assets is empty");
        require(values.length > 0, "values is empty");

        address[] memory addresses = new address[](_assets.length);
        uint256[] memory vResult = new uint256[](_assets.length);

        for (uint8 i = 0; i < _assets.length; i++) {
            addresses[i] = _assets[i];
            vResult[i] = Farm(farms[_assets[i]]).leaveQuery(
                msg.sender,
                values[i]
            );
        }
        return (addresses, vResult);
    }

    /**
        @dev get claimed rewards from a specific farm
    */
    function getFarmClaimedRewards(address asset)
        public
        view
        override
        returns (uint256)
    {
        return Farm(farms[asset]).getClaimedRewards(msg.sender);
    }

    /**
        @dev get claimed rewards from all farms added to the farmer
    */
    function getAllFarmsClaimedRewards()
        public
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addresses = new address[](assets.length);
        uint256[] memory values = new uint256[](assets.length);

        for (uint8 i = 0; i < assets.length; i++) {
            addresses[i] = assets[i];
            values[i] = Farm(farms[assets[i]]).getClaimedRewards(msg.sender);
        }

        return (addresses, values);
    }

    /**
        @dev Retrieves all stakes for sender
     */
    function getAllFarmsJoined()
        public
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addresses = new address[](assets.length);
        uint256[] memory vResult = new uint256[](assets.length);

        for (uint8 i = 0; i < assets.length; i++) {
            addresses[i] = assets[i];
            vResult[i] = Farm(farms[assets[i]]).totalStakedFor(msg.sender);
        }

        return (addresses, vResult);
    }

    function totalRewards()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addresses = new address[](assets.length);
        uint256[] memory vResult = new uint256[](assets.length);

        for (uint8 i = 0; i < assets.length; i++) {
            addresses[i] = assets[i];
            vResult[i] = Farm(farms[assets[i]]).totalRewards();
        }

        return (addresses, vResult);
    }
}
