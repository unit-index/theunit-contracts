// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IRewardTracker.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol"; // test

contract RewardDistributor is IRewardDistributor {

    address public override rewardToken;
    // uint256 public override tokensPerInterval;
    // uint256 public lastDistributionTime;
    // address public rewardTracker;

    address public admin;
    address public gov;


    struct Reward {
        uint256 tokensPerInterval;
        uint256 lastDistributionTime;
    }

    mapping (address => Reward ) public override rewardTokenInfo;

    event Distribute(address rewardTracker, uint256 amount);
    event TokensPerIntervalChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "RewardDistributor: forbidden");
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = _rewardToken;
        admin = msg.sender;
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    // function setRewardTracker(address _rewardTracker, bool isOk) external onlyGov  {
    //     rewardTracker[_rewardTracker] = isOk;
    // }
    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function updateLastDistributionTime(address _rewardTracker) external onlyAdmin {
        rewardTokenInfo[_rewardTracker].lastDistributionTime =  block.timestamp;
    }

    function setTokensPerInterval(address _rewardTracker,uint256 _amount) external onlyAdmin {
        require(rewardTokenInfo[_rewardTracker].lastDistributionTime != 0, "RewardDistributor: invalid lastDistributionTime");
        IRewardTracker(_rewardTracker).updateRewards();
        rewardTokenInfo[_rewardTracker].tokensPerInterval = _amount;
        emit TokensPerIntervalChange(_amount);
    }

    function pendingRewards(address _rewardTracker) public view override returns (uint256) {
        if (block.timestamp == rewardTokenInfo[_rewardTracker].lastDistributionTime) {
            return 0;
        }

        uint256 timeDiff = block.timestamp - rewardTokenInfo[_rewardTracker].lastDistributionTime;
        return rewardTokenInfo[_rewardTracker].tokensPerInterval * timeDiff;
    }


    function distribute() external override returns (uint256) {
        require(rewardTokenInfo[msg.sender].lastDistributionTime > 0, "RewardDistributor: invalid msg.sender");
        uint256 amount = pendingRewards(msg.sender);
        if (amount == 0) { return 0; }

        rewardTokenInfo[msg.sender].lastDistributionTime = block.timestamp;

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (amount > balance) { amount = balance; }

        safeTransfer(rewardToken, msg.sender, amount);

        emit Distribute(msg.sender, amount);

        return amount;
    }

    function safeTransfer(address _token, address _to, uint256 _amount) internal {
         IERC20(_token).transfer(_to, _amount);
    }
}
