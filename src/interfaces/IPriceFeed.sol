// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IPriceFeed {
    function description() external view returns (string memory);
    function setAdmin(address _account, bool _isAdmin) external;
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function setLatestAnswer(int256 _answer) external;
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}
