// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IFlashLoan {
     function flashLoanCall(address sender, address _collateralToken, uint256 amount, bytes calldata data) external;
}