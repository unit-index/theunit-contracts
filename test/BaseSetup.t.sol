// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Vault } from "../src/core/Vault.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { Utils } from "./Utils.t.sol";

contract BaseSetup is PRBTest, StdCheats {

    Utils internal utils;

    address internal owner;
    address internal user;
    address payable[] internal users;

    TinuToken public tinu;
    Vault public vault;

    function setUp() public virtual {
        tinu = new TinuToken();
        vault = new Vault(tinu);
        users = utils.createUsers(2);
        owner = users[0];
        user = users[1];
    }
}