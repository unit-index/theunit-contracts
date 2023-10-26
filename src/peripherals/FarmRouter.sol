// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Router01 } from "../test/IUniswapV2Router01.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IFarm } from "../interfaces/IFarm.sol";
import { IVault } from "../interfaces/IVault.sol";

import "forge-std/console.sol"; // test

contract FarmRouter is Ownable {
    using SafeMath for uint256;

    address public TINU;

    address public UN;

    address public uniswapRouter;

    address public WETH;

    address public farm;

    address public pair0;
    
    address public pair1;

    address public VAULT;

    constructor(
        address _tinu, 
        address _un, 
        address _WETH , 
        address _uniswapRouter,
        address _farm,
        address _pair0,
        address _pair1,
        address _VAULT
    ) {
        TINU = _tinu;
        UN = _un;
        WETH = _WETH;
        uniswapRouter = _uniswapRouter;
        farm = _farm;
        pair0 = _pair0;
        pair1 = _pair1;

        VAULT = _VAULT;

        setApprove();
    }

    function setApprove() public {
        IWETH(WETH).approve(uniswapRouter, type(uint256).max );
        IERC20(TINU).approve(uniswapRouter,type(uint256).max );
        IERC20(UN).approve(uniswapRouter
        , type(uint256).max );
    }

    function depositETHAndAddLiquidity(
        uint256 tinuAmountOut,  // mint多少tinu
        uint256 ethAmountInMax, // 用多少eth 质押
        uint256[] calldata amountA, // add ETH/TINU 的数量
        uint256 unAmountOut,        // 买多少UN
        uint256 tinuAmountInMax,    // 最多输入多说TINU
        uint256[] calldata amountB, // add TINU/UN  的数量
        uint256 _multiplierIndex    // 倍数, 
     ) public  payable{
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        // uint256 ethBalance = IWETH(WETH).balanceOf(address(this));

        IWETH(WETH).transfer(VAULT, ethAmountInMax);
        IVault(VAULT).increaseCollateral(WETH, address(this));
        IVault(VAULT).increaseDebt(WETH, tinuAmountOut , address(this));
       
       ( uint256 tokenAssets, uint256 tinuDebt ) = IVault(VAULT).vaultOwnerAccount(address(this), address(WETH));
        console.log("depositETHAndAddLiquidity", tokenAssets, tinuDebt);

        // uint256 ethBalance = IWETH(WETH).balanceOf(address(this));
        // uint256 tinuBalance =  IWETH(TINU).balanceOf(address(this));
        // console.log("balance:", ethBalance, tinuBalance);
        // add ETH/TINU
        IUniswapV2Router01(uniswapRouter).addLiquidity(
            WETH,
            TINU,
            amountA[0],
            amountA[1],
            0,
            0,
            address(this),
            block.timestamp+1
        );
        
        // add TINU/UN
        address[] memory path1 = new address[](2);
        path1[0] = TINU;
        path1[1] = UN;

        IUniswapV2Router01(uniswapRouter).swapTokensForExactTokens(
            uint(unAmountOut),
            uint(tinuAmountInMax),
            path1,
            address(this),
            block.timestamp+1
        );

        // IUniswapV2Router01(uniswapRouter).addLiquidity(
        //     UN,
        //     TINU,
        //     amountB[0],
        //     amountB[1],
        //     0,
        //     0,
        //     address(this),
        //     block.timestamp+1
        // );

        // uint256 lp0Amount = IERC20(pair0).balanceOf(address(this));
        // uint256 lp1Amount = IERC20(pair1).balanceOf(address(this));

        // IERC20(pair0).approve(address(this), type(uint256).max );
        // IERC20(pair1).approve(address(this), type(uint256).max );

        // IFarm(farm).depositAndLock(0, _multiplierIndex, lp0Amount, address(this));

        // IFarm(farm).depositAndLock(1, _multiplierIndex, lp1Amount, msg.sender);
    }

    // function swapAndAddLiquidity() internal {
        
    // }
}
