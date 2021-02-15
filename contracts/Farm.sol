// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/ILock.sol";
import "./Vault.sol";
import "./ReceiptToken.sol";

//cread based on AMPL Token Geyser
contract Farm is ILock, Ownable {
    using SafeMath for uint256;
    event ReceiptMinted(address indexed user, uint256 amount);
    event ReceiptBurned(address indexed user, uint256 amount);
    event FeeCollected(address indexed feeAddress, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsAdded(uint256 amount, uint256 durationSec, uint256 total);
    event RewardsMovedToClaimable(uint256 amount, uint256 total);

    Vault private _farmingVault;
    Vault private _claimableVault;
    Vault private _frozenVault;

    struct Stake {
        uint256 stakingShares;
        uint256 timestampSec;
    }

    struct UserTotals {
        uint256 stakingShares;
        uint256 stakingShareSeconds;
        uint256 lastAccountingTimestampSec;
    }

    address public farmer;
    address public receiptToken;
    address public feeAddress;

    mapping(address => uint256) userClaimedRewards;

    uint256 public bonusPeriod = 0; //in seconds
    uint256 public initialBonus = 0;
    uint256 public bonusDecimals = 3; // to have values like 678 out of 1000 which is 67.8%

    uint256 public totalFrozenShares = 0;
    uint256 public totalUsersShares = 0;

    uint256 private _totalUsersSharesSeconds = 0;
    uint256 private _lastAccountingTimestampSec = now;
    uint256 private _maxUnlocks = 0;
    uint256 private _initialSharesPerToken = 0;

    mapping(address => UserTotals) private _userTotals;
    mapping(address => Stake[]) private _userStakes;

    struct UnlockSchedule {
        uint256 initialLockedShares;
        uint256 unlockedShares;
        uint256 lastUnlockTimestampSec;
        uint256 endAtSec;
        uint256 durationSec;
    }

    UnlockSchedule[] public unlockSchedules;

    /**
     * @param stakingToken staking asset.
     * @param distributionToken reward token.
     * @param maxUnlocks Max number of unlock stages, to guard against hitting gas limit.
     * @param initialBonus_ Starting time bonus
     *                    e.g. 25% means user gets 25% of max distribution tokens.
     * @param bonusPeriod_ Length of time for bonus to increase linearly to max.
     * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
     * @param bonusDecimals_ bonus decimals
     */
    constructor(
        IERC20 stakingToken,
        IERC20 distributionToken,
        uint256 maxUnlocks,
        uint256 initialBonus_,
        uint256 bonusPeriod_,
        uint256 initialSharesPerToken,
        uint256 bonusDecimals_,
        address _farmer,
        address receiptTokenAddres,
        address _feeAddress
    ) public {
        // The start bonus must be some fraction of the max. (i.e. <= 100%)
        require(
            initialBonus_ <= 10**bonusDecimals_,
            "TokenGeyser: start bonus too high"
        );
        // If no period is desired, instead set initialBonus = 100%
        // and bonusPeriod to a small value like 1sec.
        require(bonusPeriod_ != 0, "TokenGeyser: bonus period is zero");
        require(
            initialSharesPerToken > 0,
            "TokenGeyser: initialSharesPerToken is zero"
        );

        require(bonusDecimals_ > 0, "TokenGeyser: bonusDecimals_ is zero");

        _farmingVault = new Vault(stakingToken);
        _claimableVault = new Vault(distributionToken);
        _frozenVault = new Vault(distributionToken);

        farmer = _farmer;
        initialBonus = initialBonus_;
        bonusDecimals = bonusDecimals_;
        bonusPeriod = bonusPeriod_;
        _maxUnlocks = maxUnlocks;
        _initialSharesPerToken = initialSharesPerToken;
        receiptToken = receiptTokenAddres;
        feeAddress = _feeAddress;
    }

    /**
     * @dev Transfers amount of deposit tokens from the user.
     * @param amount Number of deposit tokens to stake.
     */
    function join(address user, uint256 amount) external override {
        require(
            farmer == msg.sender,
            "This method can be called by the farmer only"
        );
        _join(user, user, amount);
    }

    /**
     * @dev Transfers amount of deposit tokens from the caller on behalf of user.
     * @param user User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     */
    function joinFor(
        address sender,
        address user,
        uint256 amount
    ) external override onlyOwner {
        require(
            farmer == msg.sender,
            "This method can be called by the farmer only"
        );
        _join(sender, user, amount);
    }

    /**
     * @dev Private implementation of staking methods.
     * @param staker User address who deposits tokens to stake.
     * @param beneficiary User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     */
    function _join(
        address staker,
        address beneficiary,
        uint256 amount
    ) private {
        require(amount > 0, "TokenGeyser: stake amount is zero");
        require(
            beneficiary != address(0),
            "TokenGeyser: beneficiary is zero address"
        );
        require(
            totalUsersShares == 0 || totalStaked() > 0,
            "TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do"
        );

        uint256 mintedStakingShares =
            (totalUsersShares > 0)
                ? totalUsersShares.mul(amount).div(totalStaked())
                : amount.mul(_initialSharesPerToken);

        require(
            mintedStakingShares > 0,
            "TokenGeyser: Stake amount is too small"
        );

        updateAccounting(beneficiary);

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];
        totals.stakingShares = totals.stakingShares.add(mintedStakingShares);
        totals.lastAccountingTimestampSec = now;

        Stake memory newStake = Stake(mintedStakingShares, now);
        _userStakes[beneficiary].push(newStake);

        // 2. Global Accounting
        totalUsersShares = totalUsersShares.add(mintedStakingShares);
        // Already set in updateAccounting()
        // _lastAccountingTimestampSec = now;

        // interactions
        require(
            _farmingVault.token().transferFrom(
                staker,
                address(_farmingVault),
                amount
            ),
            "TokenGeyser: transfer into staking pool failed"
        );

        //receiptToken
        ReceiptToken(receiptToken).mint(staker, amount);

        emit ReceiptMinted(staker, amount);
        emit Joined(beneficiary, amount, totalStakedFor(beneficiary));
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    /**
     * @return Total earnings for a user
     */
    function getClaimedRewards(address user) public view returns (uint256) {
        return userClaimedRewards[user];
    }

    /**
     * @dev Rescue rewards
     */
    function rescueRewards(address user) external onlyOwner {
        require(totalUnlocked() > 0, "TokenGeyser: reward vault is empty");
        require(
            _claimableVault.transfer(user, _claimableVault.balance()),
            "TokenGeyser: transfer failed"
        );
    }

    /**
     * @return The token users deposit as stake.
     */
    function getStakingToken() public view returns (IERC20) {
        return _farmingVault.token();
    }

    /**
     * @return The token users receive as they unstake.
     */
    function getDistributionToken() public view returns (IERC20) {
        assert(_claimableVault.token() == _frozenVault.token());
        return _claimableVault.token();
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     */
    function leave(address staker, uint256 amount) external override {
        require(
            farmer == msg.sender,
            "This method can be called by the geyser manager only"
        );
        _leave(staker, amount);
    }

    /**
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens that would be rewarded.
     */
    function leaveQuery(address staker, uint256 amount)
        public
        returns (uint256)
    {
        require(
            farmer == msg.sender,
            "This method can be called by the geyser manager only"
        );
        return _leave(staker, amount);
    }

    function calculateFee(uint256 amount) private pure returns (uint256) {
        return (amount * 500) / 10000;
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens rewarded.
     */

    function _leave(address user, uint256 amount) private returns (uint256) {
        updateAccounting(user);

        uint256 stakingSharesToBurn =
            totalUsersShares.mul(amount).div(totalStaked());

        require(
            stakingSharesToBurn > 0,
            "TokenGeyser: Unable to unstake amount this small"
        );

        // 1. User Accounting
        UserTotals storage totals = _userTotals[user];
        Stake[] storage accountStakes = _userStakes[user];

        // Redeem from most recent stake and go backwards in time.
        uint256 stakingShareSecondsToBurn = 0;
        uint256 sharesLeftToBurn = stakingSharesToBurn;
        uint256 rewardAmount = 0;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = accountStakes[accountStakes.length - 1];
            uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
            uint256 newStakingShareSecondsToBurn = 0;

            if (lastStake.stakingShares <= sharesLeftToBurn) {
                newStakingShareSecondsToBurn = lastStake.stakingShares.mul(
                    stakeTimeSec
                );
                rewardAmount = computeNewReward(
                    rewardAmount,
                    newStakingShareSecondsToBurn,
                    stakeTimeSec
                );

                stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
                    newStakingShareSecondsToBurn
                );
                sharesLeftToBurn = sharesLeftToBurn.sub(
                    lastStake.stakingShares
                );
                accountStakes.pop();
            } else {
                newStakingShareSecondsToBurn = sharesLeftToBurn.mul(
                    stakeTimeSec
                );
                rewardAmount = computeNewReward(
                    rewardAmount,
                    newStakingShareSecondsToBurn,
                    stakeTimeSec
                );
                stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
                    newStakingShareSecondsToBurn
                );
                lastStake.stakingShares = lastStake.stakingShares.sub(
                    sharesLeftToBurn
                );
                sharesLeftToBurn = 0;
            }
        }
        totals.stakingShareSeconds = totals.stakingShareSeconds.sub(
            stakingShareSecondsToBurn
        );
        totals.stakingShares = totals.stakingShares.sub(stakingSharesToBurn);
        // Already set in updateAccounting
        // totals.lastAccountingTimestampSec = now;

        // 2. Global Accounting
        _totalUsersSharesSeconds = _totalUsersSharesSeconds.sub(
            stakingShareSecondsToBurn
        );
        totalUsersShares = totalUsersShares.sub(stakingSharesToBurn);
        // Already set in updateAccountingF
        // _lastAccountingTimestampSec = now;

        // interactions
        require(
            _farmingVault.transfer(user, amount),
            "TokenGeyser: transfer out of staking pool failed"
        );

        //in case rescueRewards was called, there are no rewards to be transfered
        if (totalUnlocked() >= rewardAmount) {
            uint256 feeAmount = calculateFee(rewardAmount);
            uint256 finalRewardAmount = rewardAmount - feeAmount;
            require(
                _claimableVault.transfer(user, finalRewardAmount),
                "TokenGeyser: transfer out of unlocked pool failed"
            );
            require(
                _claimableVault.transfer(feeAddress, feeAmount),
                "TokenGeyser: transfer fee out of unlocked pool failed"
            );
            emit FeeCollected(feeAddress, feeAmount);
            emit RewardsClaimed(user, finalRewardAmount);

            userClaimedRewards[user] += finalRewardAmount;
        }
        uint256 receiptBalance = ReceiptToken(receiptToken).balanceOf(user);
        require(
            receiptBalance >= amount,
            "TokenGeyser: You have less receipt tokens than it is required"
        );
        ReceiptToken(receiptToken).burn(user, amount);

        emit ReceiptBurned(user, amount);
        emit Left(user, amount, totalStakedFor(user));

        require(
            totalUsersShares == 0 || totalStaked() > 0,
            "TokenGeyser: Error unstaking. Staking shares exist, but no staking tokens do"
        );

        return rewardAmount;
    }

    /**
     * @dev Applies an additional time-bonus to a distribution amount. This is necessary to
     *      encourage long-term deposits instead of constant unstake/restakes.
     *      The bonus-multiplier is the result of a linear function that starts at initialBonus and
     *      ends at 100% over bonusPeriod, then stays at 100% thereafter.
     * @param currentRewardTokens The current number of distribution tokens already alotted for this
     *                            unstake op. Any bonuses are already applied.
     * @param stakingShareSeconds The stakingShare-seconds that are being burned for new
     *                            distribution tokens.
     * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate
     *                     the time-bonus.
     * @return Updated amount of distribution tokens to award, with any bonus included on the
     *         newly added tokens.
     */
    function computeNewReward(
        uint256 currentRewardTokens,
        uint256 stakingShareSeconds,
        uint256 stakeTimeSec
    ) private view returns (uint256) {
        uint256 newRewardTokens =
            totalUnlocked().mul(stakingShareSeconds).div(
                _totalUsersSharesSeconds
            );

        if (stakeTimeSec >= bonusPeriod) {
            return currentRewardTokens.add(newRewardTokens);
        }

        uint256 oneHundredPct = 10**bonusDecimals;
        uint256 bonusedReward =
            initialBonus
                .add(
                oneHundredPct.sub(initialBonus).mul(stakeTimeSec).div(
                    bonusPeriod
                )
            )
                .mul(newRewardTokens)
                .div(oneHundredPct);

        return currentRewardTokens.add(bonusedReward);
    }

    /**
     * @param addr The user to look up staking information for.
     * @return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address addr)
        public
        view
        override
        returns (uint256)
    {
        return
            totalUsersShares > 0
                ? totalStaked().mul(_userTotals[addr].stakingShares).div(
                    totalUsersShares
                )
                : 0;
    }

    /**
     * @return The total number of deposit tokens staked globally, by all users.
     */
    function totalStaked() public view override returns (uint256) {
        return _farmingVault.balance();
    }

    /**
     * @dev Note that this application has a staking token as well as a distribution token, which
     * may be different. This function is required by EIP-900.
     * @return The deposit token used for staking.
     */
    function token() external view override returns (address) {
        return address(getStakingToken());
    }

    /**
     * @dev A globally callable function to update the accounting state of the system.
     *      Global state and state for the caller are updated.
     * @return [0] balance of the locked pool
     * @return [1] balance of the unlocked pool
     * @return [2] caller's staking share seconds
     * @return [3] global staking share seconds
     * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
     * @return [5] block timestamp
     */
    function updateAccounting(address user)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        _unlockTokens();

        // Global accounting
        uint256 newStakingShareSeconds =
            now.sub(_lastAccountingTimestampSec).mul(totalUsersShares);
        _totalUsersSharesSeconds = _totalUsersSharesSeconds.add(
            newStakingShareSeconds
        );
        _lastAccountingTimestampSec = now;

        // User Accounting
        UserTotals storage totals = _userTotals[user];
        uint256 newUserStakingShareSeconds =
            now.sub(totals.lastAccountingTimestampSec).mul(
                totals.stakingShares
            );
        totals.stakingShareSeconds = totals.stakingShareSeconds.add(
            newUserStakingShareSeconds
        );
        totals.lastAccountingTimestampSec = now;

        uint256 totalUserRewards =
            (_totalUsersSharesSeconds > 0)
                ? totalUnlocked().mul(totals.stakingShareSeconds).div(
                    _totalUsersSharesSeconds
                )
                : 0;

        return (
            totalLocked(),
            totalUnlocked(),
            totals.stakingShareSeconds,
            _totalUsersSharesSeconds,
            totalUserRewards,
            now
        );
    }

    /**
     * @return Total number of locked distribution tokens.
     */
    function totalLocked() public view returns (uint256) {
        return _frozenVault.balance();
    }

    /**
     * @return Total number of unlocked distribution tokens.
     */
    function totalUnlocked() public view returns (uint256) {
        return _claimableVault.balance();
    }

    /**
     * @return Number of unlock schedules.
     */
    function unlockScheduleCount() public view returns (uint256) {
        return unlockSchedules.length;
    }

    /**
     * @dev This funcion allows the contract owner to add more locked distribution tokens, along
     *      with the associated "unlock schedule". These locked tokens immediately begin unlocking
     *      linearly over the duraction of durationSec timeframe.
     * @param amount Number of distribution tokens to lock. These are transferred from the caller.
     * @param durationSec Length of time to linear unlock the tokens.
     */
    function lockTokens(uint256 amount, uint256 durationSec)
        external
        onlyOwner
    {
        require(
            unlockSchedules.length < _maxUnlocks,
            "TokenGeyser: reached maximum unlock schedules"
        );

        // Update lockedTokens amount before using it in computations after.
        updateAccounting(msg.sender);

        uint256 lockedTokens = totalLocked();
        uint256 mintedLockedShares =
            (lockedTokens > 0)
                ? totalFrozenShares.mul(amount).div(lockedTokens)
                : amount.mul(_initialSharesPerToken);

        UnlockSchedule memory schedule;
        schedule.initialLockedShares = mintedLockedShares;
        schedule.lastUnlockTimestampSec = now;
        schedule.endAtSec = now.add(durationSec);
        schedule.durationSec = durationSec;
        unlockSchedules.push(schedule);

        totalFrozenShares = totalFrozenShares.add(mintedLockedShares);

        require(
            _frozenVault.token().transferFrom(
                msg.sender,
                address(_frozenVault),
                amount
            ),
            "TokenGeyser: transfer into locked pool failed"
        );
        emit RewardsAdded(amount, durationSec, totalLocked());
    }

    /**
     * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the
     *      previously defined unlock schedules. Publicly callable.
     * @return Number of newly unlocked distribution tokens.
     */
    function unlockTokens() public onlyOwner returns (uint256) {
        _unlockTokens();
    }

    function _unlockTokens() private returns (uint256) {
        uint256 unlockedTokens = 0;
        uint256 lockedTokens = totalLocked();

        if (totalFrozenShares == 0) {
            unlockedTokens = lockedTokens;
        } else {
            uint256 unlockedShares = 0;
            for (uint256 s = 0; s < unlockSchedules.length; s++) {
                unlockedShares = unlockedShares.add(unlockScheduleShares(s));
            }
            unlockedTokens = unlockedShares.mul(lockedTokens).div(
                totalFrozenShares
            );
            totalFrozenShares = totalFrozenShares.sub(unlockedShares);
        }

        if (unlockedTokens > 0) {
            require(
                _frozenVault.transfer(address(_claimableVault), unlockedTokens),
                "TokenGeyser: transfer out of locked pool failed"
            );
            emit RewardsMovedToClaimable(unlockedTokens, totalLocked());
        }

        return unlockedTokens;
    }

    /**
     * @dev Returns the number of unlockable shares from a given schedule. The returned value
     *      depends on the time since the last unlock. This function updates schedule accounting,
     *      but does not actually transfer any tokens.
     * @param s Index of the unlock schedule.
     * @return The number of unlocked shares.
     */
    function unlockScheduleShares(uint256 s) private returns (uint256) {
        UnlockSchedule storage schedule = unlockSchedules[s];

        if (schedule.unlockedShares >= schedule.initialLockedShares) {
            return 0;
        }

        uint256 sharesToUnlock = 0;
        // Special case to handle any leftover dust from integer division
        if (now >= schedule.endAtSec) {
            sharesToUnlock = (
                schedule.initialLockedShares.sub(schedule.unlockedShares)
            );
            schedule.lastUnlockTimestampSec = schedule.endAtSec;
        } else {
            sharesToUnlock = now
                .sub(schedule.lastUnlockTimestampSec)
                .mul(schedule.initialLockedShares)
                .div(schedule.durationSec);
            schedule.lastUnlockTimestampSec = now;
        }

        schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);
        return sharesToUnlock;
    }

    /**
     * @dev Lets the owner rescue funds air-dropped to the staking pool.
     * @param otherToken Address of the token to be rescued.
     * @param to Address to which the rescued funds are to be sent.
     * @param amount Amount of tokens to be rescued.
     * @return Transfer success.
     */
    function rescueFundsFromStakingPool(
        address otherToken,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        return _farmingVault.rescueOthers(otherToken, to, amount);
    }

    function totalRewards() external view returns (uint256) {
        uint256 lockedPoolBalance = _frozenVault.balance();
        uint256 unlockedPoolBalance = _claimableVault.balance();
        return lockedPoolBalance + unlockedPoolBalance;
    }
}
