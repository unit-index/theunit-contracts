// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { UN } from "../src/core/UN.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployToken is BaseScript {
    function run(address intialOwner) public broadcast returns (bool) {

        UN unitDAO = new UN(intialOwner);
        console2.log("UN deployed at: ", address(unitDAO));
        console2.log("UN max supply: ", unitDAO.getMaxSupply());

        return true;
    }
}