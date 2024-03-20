// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { IRewardDistributor } from "../src/interfaces/IRewardDistributor.sol";

contract SetRewardsPerSec is BaseScript {
    function run() public broadcast returns (bool) {
        IRewardDistributor rd = IRewardDistributor(0x83E392F54b0C170F96142bFD422Fc86b786f5A06);
        rd.setTokensPerInterval(0xACe60BbE9c5a2aa53842384072aeA433D251d69E, 100000000000000000);
        return true;
    }
}