// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { TicketUN } from "../core/TicketUN.sol";
import { ITicketFactory } from "../interfaces/ITicketFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ITicketToken } from "../interfaces/ITicketToken.sol";

contract TicketFactory is ITicketFactory {

    // Event to log the creation of a new ticket.
    event TicketCreated(
        address indexed ticket,
        uint256 unLockTime
    );

    // Address of UN token
    address public un;

    constructor(address _un) {
        un = _un;
    }

    // Mapping to keep track of tickets and their unlock times.
    mapping (address => uint256) public override tickets;
    // Mapping to store addresses of tickets based on unlock times.
    mapping (uint256 => address) public override ticketAddresses;

    // Function to create a new ticket contract with unlockTime.
    function createTicket(uint256 _unLockTime) public override returns(address) {
        require(ticketAddresses[_unLockTime] == address(0), "TokenFactory: unlock time exists");
        address _ticket = address(new TicketUN("Ticket UN", "tUN", _unLockTime));
        tickets[_ticket] = _unLockTime;
        ticketAddresses[_unLockTime] = _ticket;
        emit TicketCreated(_ticket, _unLockTime);
        return _ticket;
    }

    // Function to unlock tickets, burn _amount tickets and transfer same amount UN to _to.
    function unlock(address _ticket, uint256 _amount, address _to) public override {
        require(tickets[_ticket] > 0 && tickets[_ticket] < block.timestamp, "TokenFactory: cannot claim yet");
        IERC20(_ticket).transferFrom(msg.sender, address(this), _amount);
        uint256 balance = IERC20(_ticket).balanceOf(address(this));
        ITicketToken(_ticket).burn(balance);
        IERC20(un).transfer(_to, balance);
    }

    // Function to lock tickets. msg.sender must have a amount of UN greater or equal to _amount
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
