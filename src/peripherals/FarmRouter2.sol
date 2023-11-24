// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Router01 } from "../test/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../test/IUniswapV2Factory.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IFarm } from "../interfaces/IFarm.sol";
import { IVault } from "../interfaces/IVault.sol";

import '../libraries/UniswapV2Library.sol';

import "forge-std/console.sol"; // test

contract FarmRouter2 is Ownable {
    
    address public TINU;

    address public UN;

    address public uniswapRouter;

    address public UNISWAP_FACTORY;

    address public WETH;

    address public farm;

    address public pair0;
    
    address public pair1;

    address public VAULT;

    constructor(
        address initialOnwer,
        address _tinu, 
        address _un, 
        address _WETH , 
        address _uniswapRouter,
        address _farm,
        address _VAULT,
        address _UNISWAP_FACTORY
    ) Ownable(initialOnwer) {
        TINU = _tinu;
        UN = _un;
        WETH = _WETH;
        uniswapRouter = _uniswapRouter;
        farm = _farm;
        VAULT = _VAULT;
        UNISWAP_FACTORY = _UNISWAP_FACTORY;
    }

    function depositETH() public payable {
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
    }


    function deposit() public payable {

        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(UNISWAP_FACTORY, WETH, TINU);
        console.log(reserveA, reserveB);
        // uint amountBOptimal = UniswapV2Library.quote(wethBalance, reserveA, reserveB);
        // console.log(amountBOptimal);

        // console.log(amountBOptimal);
        // bytes memory _data = abi.encodeWithSignature("addLiquidity(address)", amountA);
        // IVault(VAULT).flashLoan(pair0, amountB, address(this), _data);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        // if (IUniswapV2Factory(UNISWAP_FACTORY).getPair(tokenA, tokenB) == address(0)) {
        //     IUniswapV2Factory(UNISWAP_FACTORY).createPair(tokenA, tokenB);
        // }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(UNISWAP_FACTORY, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

    }

    // function addLiquidity(address user, uint256 wethAmount, uint256 tinuAmount) public {
    //     IUniswapV2Router01(uniswapRouter).addLiquidity(
    //         WETH,
    //         TINU,
    //         wethAmount,
    //         tinuAmount,
    //         0,
    //         0,
    //         VAULT,
    //         block.timestamp+1
    //     );

    //      IVault(VAULT).increaseCollateral(pair0, user);
    // }

    // function withdraw(address _collateralToken, uint256 _amount) public {
        
    // }


}