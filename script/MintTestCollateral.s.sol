// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { WrappedBTC } from "../src/test/TestCollateral.sol";

contract MintTestCollateral is BaseScript {
    function run(address to, uint256 amount) public broadcast returns (bool) {
        address tokenAddress = _getContractAddress("MintTestCollateral");
        WrappedBTC WBTC = WrappedBTC(tokenAddress);
        WBTC.mint(to, amount * 1e18);
        return true;
    }
}