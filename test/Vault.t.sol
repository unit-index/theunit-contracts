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

    uint256 private collateralAmount = 0.01 * 1e18; // 1000 collateral tokens
    uint256 private debtAmount = 1000 * 1e18; // 1000 tinu tokens

    function setUp() public override {
        super.setUp();
        router = new RouterV1(address(vault), WETH, address(tinu));
    }

    function test_MintWithoutApproval() external {
        vm.expectRevert("Vault: not allow");
        vault.increaseDebtFrom(user, WETH, debtAmount, user);
    }

    function test_IncreaseETH() external {
        vm.startPrank(user);
        vm.expectRevert("Router: value cannot be 0");
        router.increaseETH(user);
        vm.deal(user, 10 ether);
        console2.log(user.balance);
        router.increaseETH{value: 1 ether}(user);
        ( uint256 tokenAssets, uint256 tinuDebt ) = vault.vaultOwnerAccount(user, WETH);
        ( uint256 poolAssets, ) = vault.vaultPoolAccount(WETH);
        assertEq(tokenAssets, 1 ether);
        assertEq(tinuDebt, 0);
        assertEq(poolAssets, 1 ether);
        vm.stopPrank();
    }
}
