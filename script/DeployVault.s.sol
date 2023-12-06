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

    address private WETH_ARBITRUM_GOERLI = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;
    address private UN_ARBITRUM_GOERLI = 0xC97d5D78E72f9e782559274BE158aEb30cab8a8C;
    address private WBTC_TEST_ARBITRUM_GOERLI = 0xa8465274Ab3C397453D52b700eddF9543b9347ca;
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
        vaultPriceFeed.setTokenConfig(WETH_ARBITRUM_GOERLI, address(priceFeed), 18);
        vaultPriceFeed.setTokenConfig(WBTC_TEST_ARBITRUM_GOERLI, address(priceFeedBTC), 18);


        vault.setLiquidationRatio(WETH_ARBITRUM_GOERLI, 1150);
        vault.setLiquidationRatio(WBTC_TEST_ARBITRUM_GOERLI, 1150);


        RouterV1 router = new RouterV1(address(vault), WETH_ARBITRUM_GOERLI, address(tinu));
        console2.log("RouterV1 deployed at:", address(router));

        return true;
    }
}