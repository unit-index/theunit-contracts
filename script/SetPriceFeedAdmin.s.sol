// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/console2.sol";
import { IPriceFeed } from "../src/interfaces/IPriceFeed.sol";

contract SetPriceFeedAdmin is BaseScript {

    address private PRICE_FEED_ADMIN = 0xC5feaF9c4bac539c178bef3Aa55d05F4D22F2aBB;

    function run() public broadcast returns (bool) {
        
        IPriceFeed priceFeedBTC = IPriceFeed(0x5148FA700a8dCe5777e475f239E285a1b3dfC3ec);
        priceFeedBTC.setAdmin(PRICE_FEED_ADMIN, true);
        IPriceFeed priceFeedETH = IPriceFeed(0x481aE08bE993e853E163D9c39a9a5e86760aD281);
        priceFeedETH.setAdmin(PRICE_FEED_ADMIN, true);

        return true;
    }
}