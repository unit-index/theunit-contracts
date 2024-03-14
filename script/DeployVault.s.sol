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
import { DutchAuction } from "../src/core/DutchAuction.sol";

contract DeployVault is BaseScript {

    function run() public broadcast returns (bool) {
        
        TinuToken tinu = new TinuToken();
        VaultPriceFeed vaultPriceFeed = new VaultPriceFeed();


        DutchAuction dutchAuction = new DutchAuction(1,1,1);
        Vault vault = new Vault(address(tinu), address(dutchAuction));

        vault.setPriceFeed(address(vaultPriceFeed));
        tinu.setMinter(address(vault));


        UnitPriceFeed priceFeed = new UnitPriceFeed();
        console2.log("ETH Price Feed deployed at:", address(priceFeed));
        UnitPriceFeed priceFeedBTC = new UnitPriceFeed();
        console2.log("BTC Price Feed deployed at:", address(priceFeedBTC));
        priceFeed.setAdmin(vm.envAddress("DEPLOYER"), true);
        priceFeedBTC.setAdmin(vm.envAddress("DEPLOYER"), true);
        vaultPriceFeed.setTokenConfig(vm.envAddress("WETH_ARBITRUM_SEPOLIA"), address(priceFeed), 18);
        vaultPriceFeed.setTokenConfig(vm.envAddress("WBTC_ARBITRUM_SEPOLIA"), address(priceFeedBTC), 18);


        vault.setLiquidationRatio(vm.envAddress("WETH_ARBITRUM_SEPOLIA"), 1150);
        vault.setLiquidationRatio(vm.envAddress("WBTC_ARBITRUM_SEPOLIA"), 1150);


        RouterV1 router = new RouterV1(address(vault), vm.envAddress("WETH_ARBITRUM_SEPOLIA"), address(tinu));
        console2.log("RouterV1 deployed at:", address(router));

        return true;
    }
}