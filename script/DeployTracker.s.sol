// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { BaseScript } from "./Base.s.sol";
import { IRewardDistributor } from "../src/interfaces/IRewardDistributor.sol";
import { RewardTracker } from "../src/staking/RewardTracker.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { IVaultPriceFeed } from "../src/interfaces/IVaultPriceFeed.sol";
import { IERC20 } from "../src/test/IERC20.sol";
import { IFarm } from "../src/interfaces/IFarm.sol";

contract DeployTracker is BaseScript {
    function run() public broadcast returns (bool) {

        address UN =  vm.envAddress("BRIDGED_UN");
        address farmAddress = 0xF00eFdd86EF66daAfe900d043EaBcc568D37f952;

        IRewardDistributor rd = IRewardDistributor(0xC758C15c3373680CCfc5808D9F86CEE465c52849);
        RewardTracker ulp = new RewardTracker("UNIT wrap LP WBTC/TINU", "ULP");
        UnitPriceFeed priceFeed = new UnitPriceFeed(); //  为ULP创建一个priceFeed
        uint256 price = 1100000 * 1e18;
        priceFeed.setLatestAnswer(int256(price));
        IVaultPriceFeed vaultPriceFeed = IVaultPriceFeed(0xc52A1F4Bb3ee1b92520B1b77f832E680b9858E8f);
        vaultPriceFeed.setTokenConfig(address(ulp), address(priceFeed), 18);

        address pair0 = 0x795C1c612F3B1507517B5D5ec05c6DA5F7D6dA51;
        ulp.initialize(pair0, address(rd));
        rd.updateLastDistributionTime(address(ulp));
        rd.setTokensPerInterval(address(ulp), 0.03 ether); // 设置 每秒奖励这么多UN

        IERC20 unToken = IERC20(UN);
        unToken.transfer(address(rd), 2000000 ether);

        IFarm farm = IFarm(farmAddress);
        farm.addUlp(pair0, address(ulp));
        ulp.setHandler(farmAddress, true);

        console2.log("RewardTrackerWBTC deployed at:", address(ulp));

        return true;
    }
}