// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { BaseScript } from "./Base.s.sol";
import { FarmRouter2 } from "../src/peripherals/FarmRouter2.sol";

contract DeployFarm is BaseScript {
    function run() public broadcast returns (bool) {
        FarmRouter2 farm = new FarmRouter2(
            vm.envAddress("DEPLOYER"),
            0x00f254763e5e1711f755933CEB52927374e7712F,
            vm.envAddress("BRIDGED_UN"),
            vm.envAddress("WETH_ARBITRUM_SEPOLIA"),
            0x90ACBC0cBd2c2A2F3b91DAECA104721D6A166361,
            vm.envAddress("UNISWAP_FARM")
        );
        console2.log("FarmRouter2 deployed at:", address(farm));
        return true;
    }
}