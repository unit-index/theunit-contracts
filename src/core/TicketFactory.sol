// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { TicketUN } from "../core/TicketUN.sol";
import { ITicketFactory } from "../interfaces/ITicketFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ITicketToken } from "../interfaces/ITicketToken.sol";

contract TicketFactory is ITicketFactory {
    event TicketCreated(
        address indexed ticket,
        uint256 unLockTime
    );

    address public un;

    constructor(address _un) {
        un = _un;
    }

    mapping (address => uint256) public override tickets;
    mapping (uint256 => address) public override ticketAddresses;

    function createTicket(uint256 _unLockTime) public override {
        require(ticketAddresses[_unLockTime] == address(0), "TokenFactory: Already exists unlcok time!");
        address _ticket =  address(new TicketUN("Ticket UN", "tUN",_unLockTime));
        tickets[_ticket] = _unLockTime;
        ticketAddresses[_unLockTime] = _ticket;
        emit TicketCreated(_ticket, _unLockTime);
    }

    function unlock(address _ticket, uint256 _amount, address _to) public override {
        require( tickets[_ticket] > 0 && tickets[_ticket] < block.timestamp, "TokenFactory: cannot claim yet");
        IERC20(_ticket).transferFrom(msg.sender, address(this), _amount);
        uint256 balance = IERC20(_ticket).balanceOf(address(this));
        ITicketToken(_ticket).burn(balance);
        IERC20(un).transfer(_to, balance);
    }

    // Only farm contract, and multisig wallet have the permission
    function lock(address _ticket, address _to, uint256 _amount) public override {
        require(tickets[_ticket] > 0, "TokenFactory: Invalid token");
        require(_amount > 0, "TokenFactory: Invalid amount 0");
        uint256 unBalance0 = IERC20(un).balanceOf(address(this));
        IERC20(un).transferFrom(msg.sender, address(this), _amount);
        uint256 unBalance1 = IERC20(un).balanceOf(address(this));
        require(unBalance1 - unBalance0 == _amount, "TokenFactory: Invalid amount");
        ITicketToken(_ticket).mint(_to, _amount);
    }
}