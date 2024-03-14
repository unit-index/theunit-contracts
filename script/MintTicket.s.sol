// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { ITicketFactory } from "../src/interfaces/ITicketFactory.sol";
import { UN } from "../src/core/UN.sol";

contract MintTicket is BaseScript {
    function run(address ticket, address to, uint256 amount) public broadcast returns (bool) {

        address ticketFactoryAddress = _getContractAddress("Ticket");
        ITicketFactory ticketFactory = ITicketFactory(ticketFactoryAddress);

        UN un = UN(vm.envAddress("BRIDGED_UN"));
        un.approve(ticketFactoryAddress, amount * 1e18);
        ticketFactory.lock(ticket, to, amount * 1e18);
        return true;
    }
}