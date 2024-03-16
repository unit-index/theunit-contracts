
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IFarm {
     function depositETH(uint8 lock) external;
     function deposit(address _depositToken, uint256 _amount, uint8 _lockDay) external;
     function withdraw(address _uLP, uint256 _lockIndex, address _receiver) external; 
}