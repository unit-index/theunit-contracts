// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { WrappedBTC } from "../src/test/TestCollateral.sol";
import { TicketFactory } from "../src/core/TicketFactory.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployMintTestCollateral is BaseScript {
    function run(address to, uint256 amount) public broadcast returns (bool) {

        WrappedBTC collateral = new WrappedBTC(broadcaster);
        console2.log("Test Collateral deployed at: ", address(collateral));
        collateral.mint(to, amount * 1e18);

        return true;
    }
}