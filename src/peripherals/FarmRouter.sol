// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IFarm.sol";

import "hardhat/console.sol";

contract FarmRouter is Ownable {
    using SafeMath for uint256;

    address public TINU;

    address public UN;

    address public uniswapRouter;

    address public WETH;

    address public farm;

    address public pair0;
    
    address public pair1;

    constructor(
        address _tinu, 
        address _un, 
        address _WETH , 
        address _uniswapRouter,
        address _farm,
        address _pair0,
        address _pair1
    ) {
        TINU = _tinu;
        UN = _un;
        WETH = _WETH;
        uniswapRouter = _uniswapRouter;
        farm = _farm;
        pair0 = _pair0;
        pair1 = _pair1;

        IWETH(WETH).approve(address(this), type(uint256).max );
        IERC20(TINU).approve(address(this),type(uint256).max );
        IERC20(UN).approve(address(this), type(uint256).max );
    }

    function depositETHAndAddLiquidity(
        uint256 tinuAmountOut, 
        uint256 ethAmountInMax, 
        uint256[] calldata amountA,
        uint256 unAmountOut,
        uint256 tinuAmountInMax, 
        uint256[] calldata amountB,
        uint256 _multiplierIndex
     ) public  payable{
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();

        address[] memory path0 =   new address[](2);
        path0[0] = WETH;
        path0[1] = TINU;
        IUniswapV2Router01(uniswapRouter).swapTokensForExactTokens(
            uint(tinuAmountOut),
            uint(ethAmountInMax),
            path0,
            address(this),
            block.number+1
        );

        IUniswapV2Router01(uniswapRouter).addLiquidity(
            WETH,
            TINU,
            amountA[0],
            amountA[1],
            0,
            0,
            address(this),
            block.number+1
        );

        address[] memory path1 = new address[](2);
        path1[0] = TINU;
        path1[1] = UN;
        IUniswapV2Router01(uniswapRouter).swapTokensForExactTokens(
            uint(unAmountOut),
            uint(tinuAmountInMax),
            path1,
            address(this),
            block.number+1
        );

        IUniswapV2Router01(uniswapRouter).addLiquidity(
            UN,
            TINU,
            amountB[0],
            amountB[1],
            0,
            0,
            address(this),
            block.number+1
        );

        uint256 lp0Amount = IERC20(pair0).balanceOf(address(this));
        uint256 lp1Amount = IERC20(pair1).balanceOf(address(this));

        IFarm(farm).depositAndLock(0, _multiplierIndex, lp0Amount, msg.sender);
        IFarm(farm).depositAndLock(1, _multiplierIndex, lp1Amount, msg.sender);
    }
}
