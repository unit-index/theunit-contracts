// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { UN } from "../src/core/UN.sol";

contract MintToken is BaseScript {
    function run(address to, uint256 amount) public broadcast returns (bool) {

        address tokenAddress = _getContractAddress("Token");
        UN un = UN(tokenAddress);
        un.mint(to, amount * 1e18);
        return true;
    }
}