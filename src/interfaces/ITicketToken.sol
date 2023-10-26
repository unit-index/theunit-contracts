
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ITicketToken{
    function mint(address _to, uint256 _value) external returns(bool);
    function burn(uint256 _value) external returns(bool);
}