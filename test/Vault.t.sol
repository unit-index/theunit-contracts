// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Vault } from "../src/core/Vault.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { RouterV1 } from "../src/peripherals/RouterV1.sol";

contract VaultTest is BaseSetup {

    using SafeMath for uint256;

    RouterV1 private router;

    uint256 private collateralAmount = 0.01 * 1e18;
    uint256 private debtAmount = 1000 * 1e18;

    function setUp() public override {
        super.setUp();
        router = new RouterV1(address(vault), address(WETH), address(tinu));
    }

    function test_MintWithoutApproval() external {
        vm.startPrank(user);
        vm.expectRevert("Vault: not allow");
        vault.increaseDebtFrom(user, address(WETH), debtAmount, user);
        vm.stopPrank();
    }

    function test_IncreaseETH() external {
        vm.startPrank(user);
        vm.expectRevert("Router: value cannot be 0");
        router.increaseETH(user);
        vm.deal(user, 10 ether);
        router.increaseETH{value: 1 ether}(user);
        ( uint256 tokenAssets, uint256 tinuDebt ) = vault.vaultOwnerAccount(user, address(WETH));
        ( uint256 poolAssets, ) = vault.vaultPoolAccount(address(WETH));
        assertEq(tokenAssets, 1 ether);
        assertEq(tinuDebt, 0);
        assertEq(poolAssets, 1 ether);
        vm.stopPrank();
    }

    function test_MintWithoutDeposit() external {
        vm.startPrank(user);
        vault.approve(address(router), true);
        vm.expectRevert("Vault: minimumCollateral");
        router.mintUnit(address(WETH), debtAmount, user);
        vm.stopPrank();
    }

    function test_DepositAndMint() external {
        vm.startPrank(user);
        vm.deal(user, 10 ether);
        vault.approve(address(router), true);
        vm.expectRevert("Vault: minimumCollateral");
        router.increaseETHAndMint{value: 0.01 ether}(debtAmount, user);
        vm.expectRevert("Vault: unit debt out of range");
        router.increaseETHAndMint{value: 0.3 ether}(debtAmount, user);
        vm.stopPrank();
    }
}
