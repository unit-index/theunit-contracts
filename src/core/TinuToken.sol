// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ITinuToken } from "../interfaces/ITinuToken.sol";
import { ICollateralManager } from "../interfaces/ICollateralManager.sol";

contract TinuToken is ERC20, ITinuToken {

    event Mint (
        address indexed to,
        uint256 value
    );
    event Burn (
        address indexed from,
        uint256 value
    );

    address public gov;

    address public minter;
    
    modifier onlyGov{
        require(msg.sender == gov, "only gov!");
        _;
    }
    constructor() ERC20("TINU", "TINU") {
        gov = msg.sender;
    }

    function setGov(address _gov) public onlyGov{
          gov = _gov;
    }

    function setMinter(address _newMinter) public onlyGov {
        minter = _newMinter;
    }

    function mint(address _to, uint256 _value) external override returns(bool) {
        require(msg.sender == minter, "only minter!");
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
