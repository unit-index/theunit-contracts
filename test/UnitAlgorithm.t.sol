// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { console2 } from "forge-std/console2.sol";
import { BaseSetup } from "./BaseSetup.t.sol";
import { TinuToken } from "../src/core/TinuToken.sol";
import { UnitAlgorithm } from "../src/core/UnitAlgorithm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol"; // test

contract UnitAlgorithmTest is BaseSetup {

    UnitAlgorithm public unitAlgorithm;

    // TinuToken token1 = new TinuToken();
    // TinuToken token2 = new TinuToken();
    // TinuToken token3 = new TinuToken();
    /*
    [
        'avalanche-2',   'binancecoin',
        'bitcoin',       'bitcoin-cash',
        'cardano',       'chainlink',
        'dogecoin',      'ethereum',
        'fetch-ai',      'internet-computer',
        'leo-token',     'litecoin',
        'matic-network', 'near',
        'pepe',          'polkadot',
        'ripple',        'shiba-inu',
        'solana',        'the-open-network',
        'tron',          'uniswap'
        ]
    */
    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
    
        unitAlgorithm = new UnitAlgorithm(address(0), owner);

        string[] memory tokens = new string[](22);
        tokens[0] = "avalanche-2";
        tokens[1] = "bitcoin";
        tokens[2] = "cardano";
        tokens[3] = "dogecoin";
        tokens[4] = "fetch-ai";
        tokens[5] = "leo-token";
        tokens[6] = "matic-network";
        tokens[7] = "pepe";
        tokens[8] = "ripple";
        tokens[9] = "solana";
        tokens[10] = "tron";
        tokens[11] = "binancecoin";
        tokens[12] = "bitcoin-cash";
        tokens[13] = "chainlink";
        tokens[14] = "ethereum";
        tokens[15] = "internet-compute";
        tokens[16] = "litecoin";
        tokens[17] = "near";
        tokens[18] = "polkadot";
        tokens[19] = "shiba-inu";
        tokens[20] = "the-open-network";
        tokens[21] = "uniswap";

        unitAlgorithm.updateTokens(block.timestamp, tokens);

        console2.log("aaaaa:", unitAlgorithm.tokensPerMonth(block.timestamp, 2));

        vm.stopPrank();
    }

    function test_feedInfo() external {

        vm.startPrank(owner);

        uint256 _month = block.timestamp;

        uint256 _lastMCP = 6110437611602430;
        uint256 _lastMMC = 1205378364698;

        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        unitAlgorithm.setOrcl(alice, true);
        (uint8 v, bytes32 r, bytes32 s)  = vm.sign(alicePk,keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_lastMCP, _lastMMC)))));

        uint256[] memory _lastMCPs = new uint256[](1);
        _lastMCPs[0] = _lastMCP;
        uint256[] memory _lastMMCs = new uint256[](1);
        _lastMMCs[0] = _lastMMC;

        uint8[] memory vs = new uint8[](1);
        vs[0] = v;
        bytes32[] memory rs = new bytes32[](1);
        rs[0] = r;
        bytes32[] memory ss = new bytes32[](1);
        ss[0] = s;

        string memory token = "bitcoin";
      
        unitAlgorithm.updateMarketInfo(_month, token, _lastMCPs, _lastMMCs, vs, rs, ss);

        (uint256 lastMonthClosePrice, uint256 lastMonthMarketCap, uint256 updateTime) = unitAlgorithm.tokenPerMonthMarketInfo(_month, token);

        assertEq(lastMonthClosePrice, _lastMCP);
        assertEq(lastMonthMarketCap, _lastMMC);
        
        uint256 cap = unitAlgorithm.totalMarketCap(_month);
        console2.log(cap);

        vm.stopPrank();
    }
}