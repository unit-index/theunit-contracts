// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { IVault } from "../src/interfaces/IVault.sol";

contract SetWhitelist is BaseScript {
    function run() public broadcast returns (bool) {
        IVault vault = IVault(0x90ACBC0cBd2c2A2F3b91DAECA104721D6A166361);
        vault.setFreeFlashLoanWhitelist(0xF00eFdd86EF66daAfe900d043EaBcc568D37f952, true);
        return true;
    }
}