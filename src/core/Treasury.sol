// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import '../interfaces/ITreasury.sol';

contract Treasury is ITreasury {

    mapping (address => uint256) public override poolAmounts;
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    function setGov(address _gov) public {
        gov = _gov;
    }
    function withdraw(address _token, uint256 _value, address _account) public {
        
    }
}