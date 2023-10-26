// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface ITicketFactory {
    function createTicket(uint256 _unLockTime) external;
    function unlock(address _ticket, uint256 _amount, address _to) external; 
    function lock(address _ticket, address _to, uint256 _amount) external;
    function tickets(address _ticket) external view;
    function ticketAddresses(uint256 _unlockTime) external view;
}
