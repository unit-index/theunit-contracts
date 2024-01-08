// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { Farm } from "../src/core/Farm.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { FarmRouter2 } from "../src/peripherals/FarmRouter2.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { IVault } from "../src/interfaces/IVault.sol";
import { IUniswapV2Factory } from "../src/test/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "../src/test/IUniswapV2Router01.sol";
// import { IERC20 } from "../src/test/IERC20.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ULP } from "../src/staking/ULP.sol";

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

    FarmRouter2 public router;

    uint256 public amount = 1000000 * 1e18;
    uint256 private collateralAmount = 0.01 * 1e18;
    uint256 private debtAmount = 1000 * 1e18;

    address private pairETHTINU;

    ULP public ulp;

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

        pairETHTINU = pair0;
        farm.add(0, IERC20(pair0));
        farm.add(1, IERC20(pair1));
        
        // console.log(pair0);
        priceFeed = new UnitPriceFeed();
        uint256 price = 1100000 * 1e18;
        priceFeed.setLatestAnswer(int256(price));
        vaultPriceFeed.setTokenConfig(pair0, address(priceFeed), 18);

        ulp = new ULP(pair0);

        router = new FarmRouter2(
            owner,
            address(tinu),
            address(un),
            address(WETH),
            address(vault),
            address(UNISWAP_FACTORY),
            address(ulp)
        );
        
        IVault(vault).setFreeFlashLoanWhitelist(address(router), true);

        vaultRouter = new RouterV1(address(vault), address(WETH), address(tinu));
        
        depositAndMint();

        tinu.approve(address(UNISWAP_ROUTER), type(uint256).max);
        WETH.approve(address(UNISWAP_ROUTER), type(uint256).max);
        
        vm.deal(owner, 10 ether);
        WETH.deposit{value: 1 ether}(); 

        UNISWAP_ROUTER.addLiquidity(address(tinu), address(WETH), 10000000000000000, 100000000000, 0, 0, owner, 99999999999999999);

        vm.stopPrank();
    }

    function depositAndMint() public {
        // vm.startPrank(user);
        vm.deal(owner, 10 ether);
        vault.approve(address(vaultRouter), true);
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
        vm.deal(user, 100 ether);

        vault.approve(address(router), true);
        router.depositETH{value: 10 ether}();

        // (uint256 asset, uint256 debt) = vault.vaultOwnerAccount(user, address(pairETHTINU));
        // console.log(asset, debt);
        router.withdraw(address(pairETHTINU), 10 ether, user);
        vm.stopPrank();
    }

    function test_DepositETHAndSwap() external {
        vm.startPrank(user);
        vm.deal(user, 100 ether);
        vault.approve(address(router), true);
        router.depositETH{value: 10 ether}();

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(tinu);
        WETH.deposit{value: 10 ether}();
        WETH.approve(address(UNISWAP_ROUTER), 10 ether);
        UNISWAP_ROUTER.swapExactTokensForTokens(10000000, 0, path, address(this), block.timestamp+1);

        router.withdraw(address(pairETHTINU), 10 ether, user);

        vm.stopPrank();
    }
}
