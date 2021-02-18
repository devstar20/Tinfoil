// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// used in Farm
interface ILock {
    event Joined(address indexed user, uint256 amount, uint256 total);
    event Left(address indexed user, uint256 amount, uint256 total);

    /**
     * @dev Used to join a farm
     * @param user Address of the user who joins the farm
     * @param amount The amount that user joins with
     */
    function join(address user, uint256 amount) external;

    /**
     * @dev Join a farm in the name of another user
     * @param sender Adress which is calling the contract
     * @param user Address of the user who joins the farm
     * @param amount The amount that user joins with
     */
    function joinFor(
        address sender,
        address user,
        uint256 amount
    ) external;

    /**
     * @dev Leave a farm
     * @param staker Address of the user who joins the farm
     * @param amount The amount that user leaves with
     */
    function leave(address staker, uint256 amount) external;

    /**
     * @dev Retrieves the total amount a user added in the farm
     * @param addr Address of the user who joins the farm
     */
    function totalStakedFor(address addr) external view returns (uint256);

    /**
     * @dev Retrieves the total amount snder added in the farm
     */
    function totalStaked() external view returns (uint256);

    /**
     * @dev Retrieves the farming token's address
     */
    function token() external view returns (address);
}
