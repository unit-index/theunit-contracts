// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Farm } from "../src/core/Farm.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { FarmRouter } from "../src/peripherals/FarmRouter.sol";
import { IUniswapV2Factory } from "../src/test/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "../src/test/IUniswapV2Router01.sol";
import { IERC20 } from "../src/test/IERC20.sol";

contract FarmTest is BaseSetup {

    using SafeMath for uint256;

    // These are addresses of Arbitrum Goerli
    IUniswapV2Router01 private constant UNISWAP_ROUTER = 
        IUniswapV2Router01(0x45cCf01182Fb4f95d6C4F64d70105B2BA0DAC3Bf);
    IUniswapV2Factory private constant UNISWAP_FACTORY = 
        IUniswapV2Factory(0xD729EEbe443C12417d4c9661556357d3F9Fb4036);
    IERC20 private constant UN = IERC20(0x101627e8e52f627951BBdEC88418B131eE890cbE);

    Farm public farm;
    FarmRouter public router;
    uint256 public amount = 1000000 * 1e18;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        uint8 periodCount = 12;
        uint256[] memory cakesPerPeriod = new uint256[](periodCount);
        cakesPerPeriod[0] = amount;
        for (uint8 i=1; i<periodCount; i++) {
            cakesPerPeriod[i] = amount / (i * 2);
        }

        farm = new Farm(
            172800, 
            cakesPerPeriod, 
            block.number,
            address(UN)
        );

        address pair0 = UNISWAP_FACTORY.createPair(WETH, address(tinu));
        address pair1 = UNISWAP_FACTORY.createPair(address(UN), address(tinu));

        router = new FarmRouter(
            address(tinu),
            address(UN),
            WETH,
            address(UNISWAP_ROUTER),
            address(farm),
            address(pair0),
            address(pair1)
        );

        vm.stopPrank();
    }

    // function test_DepositETH() external {
    //     vm.startPrank(user);

        // uint256 ethPrice = vaultPriceFeed.getPrice(WETH);
        // assertEq(ethPrice, price);
        // uint256 ethAmount = 0.1 * 1e18;
        // uint256 tinuVaultAmount = (ethAmount * 4 * price).div(liquidationRatio + recommendRatio).mul(100);
        // uint256 tinuPoolAmount = tinuVaultAmount.mul(3).div(4);

        // router.depositETHAndAddLiquidity(
        //     240 * 1e18, 
        //     0.3 * 1e18, 
        //     [], 
        //     unAmountOut, 
        //     tinuAmountInMax, 
        //     amountB, 
        //     _multiplierIndex
        // );
    // }
}
