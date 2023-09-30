// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IVaultPriceFeed {

    function getPrice(address _token) external view returns (uint256);
 
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals
    ) external;

    function tokenToUnit(address _token, uint256 _price, uint256 amount) external view returns(uint256);
}
