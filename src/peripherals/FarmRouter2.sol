// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Router01 } from "../test/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "../test/IUniswapV2Factory.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IFarm } from "../interfaces/IFarm.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IFlashLoan } from "../interfaces/IFlashLoan.sol";
import { IUniswapPair } from "../interfaces/IUniswapPair.sol";

import '../libraries/UniswapV2Library.sol';

// import "forge-std/console.sol"; // test

contract FarmRouter2 is Ownable, IFlashLoan {
    
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
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        uint256 wethBalance = IWETH(WETH).balanceOf(address(this));
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(UNISWAP_FACTORY, WETH, TINU);
        uint amountBOptimal = UniswapV2Library.quote(wethBalance, reserveA, reserveB);
        address pair =  UniswapV2Library.pairFor(UNISWAP_FACTORY, WETH, TINU);
        bytes memory _data = abi.encodeWithSignature("addLiquidity(address,address,address,uint256,uint256)", pair, WETH, TINU, wethBalance, amountBOptimal);
        IVault(VAULT).flashLoan(pair, amountBOptimal, address(this), _data);
    }

    function flashLoanCall(address _sender, address _collateralToken, uint256 _amount, bytes calldata _data) external override {
        require(msg.sender == VAULT, "");
        address(this).call(_data);
        IVault(VAULT).increaseCollateral(_collateralToken, _sender);
    }

    function addLiquidity(address pair, address tokenA, address tokenB, uint256 amountA, uint256 amountB) public {
        uint256 _amountA = IERC20(tokenA).balanceOf(address(this));
        uint256 _amountB = IERC20(tokenB).balanceOf(address(this));
        require(amountA == _amountA, "FarmRouter2: INSUFFICIENT amountA");
        require(amountB == _amountB, "FarmRouter2: INSUFFICIENT amountB");
        IERC20(tokenA).transfer(pair, _amountA);
        IERC20(tokenB).transfer(pair, _amountB);
        IUniswapPair(pair).mint(VAULT);
    }

    function withdraw(address _collateralToken, uint256 _amount) public {
          
    }
}