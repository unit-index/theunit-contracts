// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { TicketFactory } from "../src/core/TicketFactory.sol";
import { IUniswapV2Factory } from "../src/test/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "../src/test/IUniswapV2Router01.sol";
// import { IERC20 } from "../src/test/IERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol"; // test

contract UNTokenTest is BaseSetup {

    TicketFactory public ticketFactory;

    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
    
        un.mint(owner, 100 ether);

        ticketFactory = new TicketFactory(address(un));

        vm.stopPrank();
    }

    function test_createTicket() external {
        vm.startPrank(owner);
        uint256 time = block.timestamp + 1;

        ticketFactory.createTicket(time);

        address ticket = ticketFactory.ticketAddresses( time);

        // uint256 unLockTime = ticketFactory.tickets(ticket);
        // console.log(ticket, unLockTime);
        un.approve(address(ticketFactory), 10 ether);
        ticketFactory.lock(ticket, owner, 10 ether);

        uint256 tfBalance = un.balanceOf(address(ticketFactory));
        uint256 ticketBalance = IERC20(ticket).balanceOf(address(owner));
    
        assertEq(tfBalance, ticketBalance);

        vm.warp(time -1);

        IERC20(ticket).approve(address(ticketFactory), 10 ether);
        ticketFactory.unlock(ticket, 10 ether, owner);

        vm.stopPrank();
    }
}