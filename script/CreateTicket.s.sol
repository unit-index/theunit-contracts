// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { ITicketFactory } from "../src/interfaces/ITicketFactory.sol";

contract CreateTicket is BaseScript {
    function run(uint256 unlockTime) public broadcast returns (address) {

        address ticketFactoryAddress = _getContractAddress("Ticket");
        ITicketFactory ticketFactory = ITicketFactory(ticketFactoryAddress);
        address ticket = ticketFactory.createTicket(unlockTime);
        console2.log("Ticket with unlock time: %d is deployed at %s", unlockTime, ticket);

        return ticket;
    }
}