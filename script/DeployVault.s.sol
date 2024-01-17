// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { Vault } from "../src/core/Vault.sol";
import { console2 } from "forge-std/console2.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { VaultPriceFeed } from "../src/core/VaultPriceFeed.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";

contract DeployVault is BaseScript {

    address private WETH_ARBITRUM_SEPOLIA = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address private UN_ARBITRUM_SEPOLIA = 0x4CEcd017a9bA4dAbDC3d35A042Ea16ace0325115;
    address private WBTC_TEST_ARBITRUM_SEPOLIA = 0xB24D631e7899F6D89eF9C6dEa293A6527e8a3438;
    address private PRICE_FEED_ADMIN = 0xC5feaF9c4bac539c178bef3Aa55d05F4D22F2aBB;

    function run() public broadcast returns (bool) {
        
        TinuToken tinu = new TinuToken();
        VaultPriceFeed vaultPriceFeed = new VaultPriceFeed();
        Vault vault = new Vault(address(tinu));
        vault.setPriceFeed(address(vaultPriceFeed));
        tinu.setMinter(address(vault));


        UnitPriceFeed priceFeed = new UnitPriceFeed();
        console2.log("ETH Price Feed deployed at:", address(priceFeed));
        UnitPriceFeed priceFeedBTC = new UnitPriceFeed();
        console2.log("BTC Price Feed deployed at:", address(priceFeedBTC));
        priceFeed.setAdmin(PRICE_FEED_ADMIN, true);
        priceFeedBTC.setAdmin(PRICE_FEED_ADMIN, true);
        vaultPriceFeed.setTokenConfig(WETH_ARBITRUM_SEPOLIA, address(priceFeed), 18);
        vaultPriceFeed.setTokenConfig(WBTC_TEST_ARBITRUM_SEPOLIA, address(priceFeedBTC), 18);


        vault.setLiquidationRatio(WETH_ARBITRUM_SEPOLIA, 1150);
        vault.setLiquidationRatio(WBTC_TEST_ARBITRUM_SEPOLIA, 1150);


        RouterV1 router = new RouterV1(address(vault), WETH_ARBITRUM_SEPOLIA, address(tinu));
        console2.log("RouterV1 deployed at:", address(router));

        return true;
    }
}