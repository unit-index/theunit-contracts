// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";

contract Deploy is BaseScript {
    function run() public broadcast returns (bool) {
        return true;
    }
}