// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITicketToken } from "../interfaces/ITicketToken.sol";

contract TicketUN is ERC20, ITicketToken {

    event Mint (
        address indexed to,
        uint256 value
    );
    
    event Burn (
        address indexed from,
        uint256 value
    );

    address public minter;

    uint256 public unLockTime;
    
    constructor(string memory _name, string memory _symbol, uint256 _unLockTime) ERC20(_name, _symbol) {
        minter = msg.sender;
        unLockTime = _unLockTime;
    }

    function mint(address _to, uint256 _value) external override returns(bool) {
        require(msg.sender == minter, "No rights!");
        _mint(_to, _value);
        emit Mint(_to, _value);
        return true;
    }

    function burn(uint256 _value) external override returns(bool) {
        _burn(msg.sender, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
}
