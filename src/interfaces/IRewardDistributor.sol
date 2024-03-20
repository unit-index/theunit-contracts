// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IRewardDistributor {
    function rewardToken() external view returns (address);
    function rewardTokenInfo(address) external view returns (uint256, uint256);
    function pendingRewards(address) external view returns (uint256);
    function distribute() external returns (uint256);
    function setTokensPerInterval(address, uint256) external;
}
