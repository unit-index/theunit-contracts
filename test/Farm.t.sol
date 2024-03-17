// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { Farm } from "../src/staking/Farm.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { FarmRouter2 } from "../src/peripherals/FarmRouter2.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { WrappedBTC } from "../src/test/TestCollateral.sol";
import { IVault } from "../src/interfaces/IVault.sol";
import { IFarm } from "../src/interfaces/IFarm.sol";
import { IUniswapV2Factory } from "../src/test/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "../src/test/IUniswapV2Router01.sol";
// import { IERC20 } from "../src/test/IERC20.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";
import { IERC20 } from "../src/test/IERC20.sol";
import { RewardTracker } from "../src/staking/RewardTracker.sol";
import { RewardDistributor } from "../src/staking/RewardDistributor.sol";

contract FarmTest2 is BaseSetup {
    
    IUniswapV2Factory private constant UNISWAP_FACTORY = 
        IUniswapV2Factory(0xD729EEbe443C12417d4c9661556357d3F9Fb4036);

    RouterV1 private vaultRouter;
    // Farm public farm;
    FarmRouter2 public farmRouter2 ;

    RewardTracker public ulp;

    function setUp() public override {
        super.setUp();
    }

    // function test_depositWBTC() public {
    //     vm.startPrank(0xC4cD7F3F5B282d40840E1C451EC93FFAE61514f9);
    //     IERC20 collateral = IERC20(0xBB6E93D6E98a8d119Ca7279CB826300b7EB11845);
    //     collateral.approve(0xcac9bd169eEA4334326439963975C8323DFe8894, 10 ether);
    //     IFarm farm = IFarm(0xcac9bd169eEA4334326439963975C8323DFe8894);
    //     farm.deposit(0xBB6E93D6E98a8d119Ca7279CB826300b7EB11845, 1 ether, 30);
    //     vm.stopPrank();
    // }

    function test_depositETH() public {
        vm.startPrank(0xC4cD7F3F5B282d40840E1C451EC93FFAE61514f9);
        IVault vault = IVault(0x90ACBC0cBd2c2A2F3b91DAECA104721D6A166361);
        vault.approve(0xcac9bd169eEA4334326439963975C8323DFe8894, true);
        IFarm farm = IFarm(0xcac9bd169eEA4334326439963975C8323DFe8894);
        farm.depositETH{value: 0.02 ether}(30);
        vm.stopPrank();
    }
}
