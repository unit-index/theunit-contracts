// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { Farm } from "../src/staking/Farm.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { FarmRouter } from "../src/peripherals/FarmRouter.sol";
import { IUniswapV2Factory } from "../src/test/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "../src/test/IUniswapV2Router01.sol";
// import { IERC20 } from "../src/test/IERC20.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol"; // test

contract FarmTest is BaseSetup {

    // These are addresses of Arbitrum Goerli
    IUniswapV2Router01 private constant UNISWAP_ROUTER = 
        IUniswapV2Router01(0x45cCf01182Fb4f95d6C4F64d70105B2BA0DAC3Bf);
    IUniswapV2Factory private constant UNISWAP_FACTORY = 
        IUniswapV2Factory(0xD729EEbe443C12417d4c9661556357d3F9Fb4036);
    // IERC20 private constant UN = IERC20(0x101627e8e52f627951BBdEC88418B131eE890cbE);

    RouterV1 private vaultRouter;

    Farm public farm;
    FarmRouter public router;
    uint256 public amount = 1000000 * 1e18;

    uint256 private collateralAmount = 0.01 * 1e18;
    uint256 private debtAmount = 1000 * 1e18;

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
            owner,
            172800, 
            cakesPerPeriod, 
            block.number,
            address(un)
        );

        address pair0 = UNISWAP_FACTORY.createPair(address(WETH), address(tinu));
        address pair1 = UNISWAP_FACTORY.createPair(address(un), address(tinu));
      
        farm.add(0, IERC20(pair0));
        farm.add(1, IERC20(pair1));

        router = new FarmRouter(
            owner,
            address(tinu),
            address(un),
            address(WETH),
            address(UNISWAP_ROUTER),
            address(farm),
            address(pair0),
            address(pair1),
            address(vault)
        );
        // (address _vault, address _weth, address _tinu)
        vaultRouter = new RouterV1(address(vault), address(WETH), address(tinu));
        // test_DepositAndMint();
        depositAndMint();

        tinu.approve(address(UNISWAP_ROUTER), type(uint256).max);
        WETH.approve(address(UNISWAP_ROUTER), type(uint256).max);
        WETH.deposit{value: 1 ether}();
        UNISWAP_ROUTER.addLiquidity(address(tinu), address(WETH), 10000000000000000, 100000000000, 0, 0, owner, 99999999999999999);

        un.mint(owner, 100 ether);
        un.approve(address(UNISWAP_ROUTER), type(uint256).max);
        (uint a, uint b, uint lp) = UNISWAP_ROUTER.addLiquidity(address(tinu), address(un), 30 ether, 3 ether, 0, 0, owner, 99999999999999999);
        console2.log("lp:",a, b, lp);
        vm.stopPrank();
    }

    function depositAndMint() public {
        // vm.startPrank(user);
        vm.deal(owner, 10 ether);
        vault.approve(address(vaultRouter), true);
        vm.expectRevert("Vault: minimumTINU");
        vaultRouter.increaseETHAndMint{value: 0.01 ether}(debtAmount, owner);
        vm.expectRevert("Vault: unit debt out of range");
        vaultRouter.increaseETHAndMint{value: 0.3 ether}(debtAmount, owner);
        vaultRouter.increaseETHAndMint{value: 1.5 ether}(debtAmount, owner);
        ( uint256 tokenAssets, uint256 tinuDebt ) = vault.vaultOwnerAccount(owner, address(WETH));
        ( uint256 poolAssets, ) = vault.vaultPoolAccount(address(WETH));
        assertEq(tokenAssets, 1.5 ether);
        assertEq(tinuDebt, debtAmount);
        assertEq(poolAssets, 1.5 ether);
        // vm.stopPrank();
    }

    function test_DepositETH() external {
        vm.startPrank(user);

        uint256 ethPrice = vaultPriceFeed.getPrice(address(WETH));
        assertEq(ethPrice, price);
        uint256 ethAmount = 0.1 * 1e18;
        // uint256 tinuVaultAmount = (ethAmount * 4 * price).div(liquidationRatio + recommendRatio).mul(100);
        // uint256 tinuPoolAmount = tinuVaultAmount.mul(3).div(4);

        uint256[] memory amountA = new uint256[](2);
        amountA[0] = 1e18;
        amountA[1] = 1e18;
        vm.deal(user, 100 ether);

        router.depositETHAndAddLiquidity{value: 100 ether}(
            200 * 1e18, 
            10 * 1e18, 
            amountA,
            1 * 1e17,
            3 * 1e18, 
            amountA,
            1
        );

        vm.roll(10000);

        ( uint256 a, uint256 b, uint256 c, uint256 d ) = farm.pendingRewards(0, address(user));
        
        console.log( a,b,c,d);

        vm.stopPrank();
    }
}
