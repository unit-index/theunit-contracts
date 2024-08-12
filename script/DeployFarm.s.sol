// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { BaseScript } from "./Base.s.sol";
import { FarmRouter2 } from "../src/peripherals/FarmRouter2.sol";
import { RewardDistributor } from "../src/staking/RewardDistributor.sol";
import { RewardTracker } from "../src/staking/RewardTracker.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { IVaultPriceFeed } from "../src/interfaces/IVaultPriceFeed.sol";
import { IVault } from "../src/interfaces/IVault.sol";
import { IERC20 } from "../src/test/IERC20.sol";
import { IUniswapV2Factory } from "../src/test/IUniswapV2Factory.sol";

contract DeployFarm is BaseScript {
    function run() public broadcast returns (bool) {

        address UNISWAPFACTORY = 0xD729EEbe443C12417d4c9661556357d3F9Fb4036;
        address UN =  vm.envAddress("BRIDGED_UN");
        address WETH =  vm.envAddress("WETH_ARBITRUM_SEPOLIA");
        address WBTC=  vm.envAddress("WBTC_ARBITRUM_SEPOLIA");


        RewardDistributor rd = new RewardDistributor(UN); //  RewardDistributor  全局只需要一个即可

        RewardTracker ulp = new RewardTracker("UNIT wrap LP WETH/TINU", "ULP");
        UnitPriceFeed priceFeed = new UnitPriceFeed(); //  为ULP创建一个priceFeed
        uint256 price = 1100000 * 1e18;
        priceFeed.setLatestAnswer(int256(price));
        IVaultPriceFeed vaultPriceFeed = IVaultPriceFeed(0xc52A1F4Bb3ee1b92520B1b77f832E680b9858E8f);
        vaultPriceFeed.setTokenConfig(address(ulp), address(priceFeed), 18);
        IVault vault = IVault(0x90ACBC0cBd2c2A2F3b91DAECA104721D6A166361);

        address pair0 = 0x4a93a46c20FB29a71BBfca7a7Eb6224665602570;

        ulp.initialize(pair0, address(rd));

        rd.updateLastDistributionTime(address(ulp));
        rd.setTokensPerInterval(address(ulp), 0.1 ether); // 设置 每秒奖励这么多UN

        IERC20 unToken = IERC20(UN);
        unToken.transfer(address(rd), 2000000 ether);

        FarmRouter2 farm = new FarmRouter2(
            vm.envAddress("DEPLOYER"),
            0x00f254763e5e1711f755933CEB52927374e7712F,
            vm.envAddress("BRIDGED_UN"),
            vm.envAddress("WETH_ARBITRUM_SEPOLIA"),
            0x90ACBC0cBd2c2A2F3b91DAECA104721D6A166361,
            vm.envAddress("UNISWAP_FARM")
        );

        farm.addUlp(pair0, address(ulp));
        ulp.setHandler(address(farm), true);
        
        console2.log("FarmRouter2 deployed at:", address(farm));

        vault.setFreeFlashLoanWhitelist(address(farm), true);

        return true;
    }
}