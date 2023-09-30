
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface ICollateralManager {
    function liquidationFee(address) external view returns(uint256);
    function maxDecreaseCollateralAmount(address _collateralToken, address _account,  uint256 _totalCollateralAmount) external view returns(uint256);
    function maxMintUnitValue(address _collateralToken, address _account) external view returns(uint256);
}