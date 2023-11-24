// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { Vault } from "../src/core/Vault.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";

contract Deploy is BaseScript {
    function run() public broadcast returns (bool) {

        return true;
    }
}