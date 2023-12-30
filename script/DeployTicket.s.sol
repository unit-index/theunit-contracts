// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { TicketFactory } from "../src/core/TicketFactory.sol";

contract DeployTicket is BaseScript {
    function run() public broadcast returns (bool) {

        TicketFactory factory = new TicketFactory(address(bridgedUN));
        console2.log("Unit Ticket Factory deployed at: ", address(factory));

        return true;
    }
}