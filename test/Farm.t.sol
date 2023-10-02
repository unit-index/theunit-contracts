// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import {Farm} from "../src/core/Farm.sol";
import {TinuToken} from "../src/core/TinuToken.sol";
import {FarmRouter} from "../src/peripherals/FarmRouter.sol";
import {IUniswapV2Factory} from "../src/test/IUniswapV2Factory.sol";
import {IUniswapV2Router01} from "../src/test/IUniswapV2Router01.sol";
import {IERC20} from "../src/test/IERC20.sol";
import {IWETH} from "../src/test/IWETH.sol";

contract FarmTest is BaseSetup {

    // These are addresses of Arbitrum Goerli
    IUniswapV2Router01 private constant UNISWAP_ROUTER = 
        IUniswapV2Router01(0x45cCf01182Fb4f95d6C4F64d70105B2BA0DAC3Bf);
    IUniswapV2Factory private constant UNISWAP_FACTORY = 
        IUniswapV2Factory(0xD729EEbe443C12417d4c9661556357d3F9Fb4036);
    IERC20 private constant UN = IERC20(0x101627e8e52f627951BBdEC88418B131eE890cbE);
    IWETH private constant WETH = IWETH(0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3);

    Farm public farm;
    FarmRouter public router;
    TinuToken public TINU;
    uint256 public amount = 1000000e18;

    function setUp() public override {
        super.setUp();
        TINU = new TinuToken();

        uint256[] memory cakesPerPeriod;
        cakesPerPeriod[0] = amount;
        for (uint i=1; i<12; i++) {
            cakesPerPeriod[i] = amount / (i * 2);
        }

        farm = new Farm(
            172800, 
            cakesPerPeriod, 
            block.number,
            UN
        );

        address pair0 = UNISWAP_FACTORY.createPair(WETH.address, TINU.address);
        address pair1 = UNISWAP_FACTORY.createPair(UN.address, TINU.address);

        router = new FarmRouter(
            TINU,
            UN,
            WETH,
            UNISWAP_ROUTER,
            farm,
            pair0,
            pair1
        );

        assertEq(router.UN, 0x101627e8e52f627951BBdEC88418B131eE890cbE);
    }
}
