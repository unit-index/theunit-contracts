// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { Unit } from "../src/core/Unit.sol";
import { TicketFactory } from "../src/core/TicketFactory.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployToken is BaseScript {
    function run() public broadcast returns (bool) {

        Unit unitToken = new Unit(broadcaster, 2 ** 33 * 1e18);
        console2.log("Unit deployed at: ", address(unitToken));

        return true;
    }
}