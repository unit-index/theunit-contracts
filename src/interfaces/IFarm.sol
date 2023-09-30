
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IFarm {
     function depositAndLock(uint256 _pid, uint256 _multiplierIndex, uint256 _amount, address _to) external;
}