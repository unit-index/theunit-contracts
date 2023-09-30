// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface ITinuToken {
    function mint(address _to, uint256 value) external returns(bool);
    function burn(uint256 value) external returns(bool);
    // function unitDebt(address _account, address _collateralToken) external view returns( uint256);
}