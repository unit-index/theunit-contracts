// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ITreasury {
    function poolAmounts(address) external view returns(uint256);
}
