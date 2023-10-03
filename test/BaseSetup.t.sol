// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Vault } from "../src/core/Vault.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { UnitPriceFeed } from "../src/oracle/UnitPriceFeed.sol";
import { VaultPriceFeed } from "../src/core/VaultPriceFeed.sol";

contract BaseSetup is PRBTest, StdCheats {

    address internal owner;
    address internal user;
    address internal WETH = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;
    uint256 internal recommendRatio = 200;
    uint256 internal price = 1100;
    uint256 internal liquidationRatio;

    TinuToken public tinu;
    Vault public vault;
    UnitPriceFeed public priceFeed;
    VaultPriceFeed public vaultPriceFeed;

    function setUp() public virtual {
        owner = payable(address(uint160(uint256(keccak256(abi.encodePacked("owner"))))));
        user = payable(address(uint160(uint256(keccak256(abi.encodePacked("user"))))));
        vm.startPrank(owner);
        tinu = new TinuToken();
        priceFeed = new UnitPriceFeed();
        priceFeed.setLatestAnswer(int256(price));
        vaultPriceFeed = new VaultPriceFeed();
        vault = new Vault(address(tinu));
        vault.setPriceFeed(address(vaultPriceFeed));
        tinu.setMinter(address(vault));
        vaultPriceFeed.setTokenConfig(WETH, address(priceFeed), 18);
        liquidationRatio = vault.liquidationRatio();
        vm.stopPrank();
    }
}