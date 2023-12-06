// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { VaultPriceFeed } from "../src/core/VaultPriceFeed.sol";

contract SetBTCPriceFeed is BaseScript {

    address private WBTC_TEST_ARBITRUM_GOERLI = 0xa8465274Ab3C397453D52b700eddF9543b9347ca;

    function run() public broadcast returns (bool) {
        
        VaultPriceFeed vaultPriceFeed = VaultPriceFeed(0x0854F1fD34D0FC03e0C726C9Dd73c4D386085e6D);
        UnitPriceFeed priceFeedBTC = new UnitPriceFeed();
        console2.log("BTC Price Feed deployed at:", address(priceFeedBTC));
        vaultPriceFeed.setTokenConfig(WBTC_TEST_ARBITRUM_GOERLI, address(priceFeedBTC), 18);

        return true;
    }
}