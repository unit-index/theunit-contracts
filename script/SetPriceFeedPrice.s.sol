// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { IPriceFeed } from "../src/interfaces/IPriceFeed.sol";

contract SetPriceFeedAnswer is BaseScript {

    function run() public broadcast returns (bool) {
        
        IPriceFeed priceFeedBTC = IPriceFeed(0x2f1d4AE6a0bb0e864cD81A646921DFB479aF5936);
        priceFeedBTC.setLatestAnswer(18373442 * 10**15);
        IPriceFeed priceFeedETH = IPriceFeed(0x2F6200e0d027c886F15e4FC79A8D8085c277925E);
        priceFeedETH.setLatestAnswer(1052953 * 10**15);

        return true;
    }
}