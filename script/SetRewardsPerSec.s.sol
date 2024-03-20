// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { IRewardDistributor } from "../src/interfaces/IRewardDistributor.sol";

contract SetRewardsPerSec is BaseScript {
    function run() public broadcast returns (bool) {
        IRewardDistributor rd = IRewardDistributor(0xC758C15c3373680CCfc5808D9F86CEE465c52849);
        rd.setTokensPerInterval(0x1dA0dcF724B4e44A3718f66702F3137Aec51aDe8, 100000000000000000);
        return true;
    }
}