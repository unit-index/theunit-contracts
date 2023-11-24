// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { Unit } from "../src/core/Unit.sol";

contract MintToken is BaseScript {
    function run(address to, uint256 amount) public broadcast returns (bool) {

        address tokenAddress = _getContractAddress("Token");
        Unit un = Unit(tokenAddress);
        un.mint(to, amount * 1e18);
        return true;
    }
}