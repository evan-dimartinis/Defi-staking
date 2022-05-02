// stake: Lock tokens into our smart contract
// withdraw: unlock tokens and pull out of the contract
// claimReward: users get their reward tokens
// What is a good reward mechanism/reward math?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC20.sol";
import "../Security/ReentrancyGuard.sol";

error Staking__TransferFailed();
error Staking__Zero();

contract Staking is ReentrancyGuard {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;
    // address => amount they staked
    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_rewards;
    mapping(address => uint256) public s_userRewardPerTokenPaid;
    uint256 private s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;
    uint256 public constant REWARD_RATE = 100;

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);

    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((s_balances[account] *
                (rewardPerToken() - s_userRewardPerTokenPaid[account])) /
                1e18) + s_rewards[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return
            s_rewardPerTokenStored +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
                s_totalSupply);
    }

    // What kind of tokens are we going to allow?
    // just allowing erc20 tokens
    // if we were allowing different tokens we would have to do chainlink stuff to convert prices between tokens
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        nonReentrant
        moreThanZero(amount)
    {
        // keep track of how much this user has staked
        // keep track of how much token we have total
        // transfer tokens from account
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;
        emit Staked(msg.sender, amount);
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount)
        external
        updateReward(msg.sender)
        nonReentrant
        moreThanZero(amount)
    {
        s_balances[msg.sender] -= amount;
        s_totalSupply -= amount;
        emit WithdrewStake(msg.sender, amount);
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        // How much reward should they get?

        // Contract will emit X tokens/second
        // Disperse them to all token stakers

        // 100 tokens/second
        // 100 tokens dispersed proportionally

        uint256 reward = s_rewards[msg.sender];

        s_rewards[msg.sender] = 0;

        emit RewardsClaimed(msg.sender, reward);

        bool success = s_rewardToken.transfer(msg.sender, reward);

        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__Zero();
        }
        _;
    }
}
