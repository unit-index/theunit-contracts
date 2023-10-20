// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { TicketToken } from "../core/TicketToken.sol";
import { TokenFactory } from "../interfaces/ITokenFactory.sol";

contract TokenFactory is ITokenFactory {

    address public un;

    mapping (address => bool) public minter;

    constructor(address _un) {
        un = _un;
    }

    function setMinter(address addr, bool canMint) public onlyOwner {
        minter[addr] = canMint;
    }

    mapping (address => uint256) public tickets;

    function createTicket(uint256 _unLockTime) public override {
        require(tickets[_ticket] == 0, "");
        address _ticket =  address(new TicketToken("Ticket UN", "tUN",_unLockTime));
        tickets[_ticket] = _unLockTime;
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
        require(minter[msg.sender], "TokenFactory: no minter!");
        ITicketToken(_ticket).mint(_to, _amount);
    } 
}