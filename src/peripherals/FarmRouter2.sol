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
import { IRewardTracker } from "../interfaces/IRewardTracker.sol";
import '../libraries/UniswapV2Library.sol';

// import "forge-std/console.sol"; // test

contract FarmRouter2 is Ownable, IFlashLoan {
    
    address public TINU;

    address public UN;

    address public uniswapRouter;

    address public UNISWAP_FACTORY;

    address public WETH;

    address public farm;

    address public VAULT;

    // address public uLP;
    mapping (address => address) public uLps; // pair => ulp
    mapping (address => address) public pairs; //ulp => pair

    struct FlashCallbackData{
        bytes callData; // calldata
        uint func; // addLiquidity 0 removeLiquidity 1
    }

    constructor(
        address initialOnwer,
        address _tinu, 
        address _un, 
        address _WETH,
        address _VAULT,
        address _UNISWAP_FACTORY
    ) Ownable(initialOnwer) {
        TINU = _tinu;
        UN = _un;
        WETH = _WETH;
        VAULT = _VAULT;
        UNISWAP_FACTORY = _UNISWAP_FACTORY;
    }

    function addUlp(address _pair, address _ulp) public onlyOwner {
        uLps[_pair] = _ulp;
        pairs[_ulp] = _pair;
        IERC20(_pair).approve(_ulp, 2**256-1);
    }

    function depositETH() public payable {
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        address _pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, WETH, TINU);
        address _uLP = uLps[_pair];
        _deposit(_uLP, WETH);
    }

    function deposit(address _depositToken, uint256 _amount) public {
        IERC20(_depositToken).transferFrom(msg.sender, address(this), _amount);
        address _pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, WETH, TINU);
        address _uLP = uLps[_pair];
        _deposit(_uLP, _depositToken);
    }
    /*
        _collateralToken is LP token
        _depositToken is assets
    */
    function _deposit(address _collateralToken, address _depositToken) internal {
        uint256 depositAmounts = IERC20(_depositToken).balanceOf(address(this));
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(UNISWAP_FACTORY, _depositToken, TINU);
        uint needTinuAmounts = UniswapV2Library.quote(depositAmounts, reserveA, reserveB);
        address _pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, _depositToken, TINU);
        // console.log("_collateralToken:", _collateralToken);
        bytes memory _data = abi.encodeWithSignature(
            "addLiquidity(address,address,address,uint256,uint256)",
            _pair,
            _depositToken,
            TINU,
            depositAmounts, 
            needTinuAmounts
        );

        FlashCallbackData memory fcData = FlashCallbackData(_data, 0);
        IVault(VAULT).flashLoanFrom(msg.sender, _collateralToken, needTinuAmounts, address(this), abi.encode(fcData));
    }

    function flashLoanCall(address _sender, address _collateralToken, uint256 _amount, bytes calldata _data) external override {
        require(msg.sender == VAULT, "FarmRouter2: no");
        FlashCallbackData memory fcData = abi.decode(_data, (FlashCallbackData));
        if(fcData.func == 0) { 
            (bool success, ) = address(this).call(fcData.callData); // add
            require(success, "FarmRouter2: addLiquidity error!");
            IVault(VAULT).increaseCollateral(_collateralToken, _sender);  
        }else if(fcData.func == 1) {
            address _pair = pairs[_collateralToken];
            IRewardTracker(_collateralToken).unstake(_pair, _amount);
            uint256 lpBalane = IERC20(_pair).balanceOf(address(this));
            // console.log("unstank", lpBalane);
            require(lpBalane >= _amount,"FarmRouter2: unstake error");
            (bool success, ) = address(this).call(fcData.callData); // rm
            require(success, "FarmRouter2: remove Liquidity error!");
            uint256 tinuBalance = IERC20(TINU).balanceOf(address(this));
            IERC20(TINU).transfer(VAULT, tinuBalance);
            IVault(VAULT).decreaseDebt(_collateralToken, _sender);
            uint256 tinuBalance2 = IERC20(TINU).balanceOf(address(this));
            // console.log("tinuBalance:",tinuBalance2);
            (uint256 tokenAssets, uint256 debt) = IVault(VAULT).vaultOwnerAccount(msg.sender, _collateralToken);
            // console.log("tinuBalance:",tokenAssets, debt);
        }
    }

    function addLiquidity(address pair, address tokenA, address tokenB, uint256 amountA, uint256 amountB) public returns(uint) {
        uint256 _amountA = IERC20(tokenA).balanceOf(address(this));
        uint256 _amountB = IERC20(tokenB).balanceOf(address(this));
        require(amountA == _amountA, "FarmRouter2: INSUFFICIENT amountA");
        require(amountB == _amountB, "FarmRouter2: INSUFFICIENT amountB");
        IERC20(tokenA).transfer(pair, _amountA);
        IERC20(tokenB).transfer(pair, _amountB);
        uint liquidity = IUniswapPair(pair).mint(address(this));
        address _uLP = uLps[pair];
        IRewardTracker(_uLP).stake(pair, liquidity);
        IERC20(_uLP).transfer(VAULT, liquidity);
        return liquidity;
    }
    
    function removeLiquidity(address _pair, address _receiver, uint256 _amount) public returns(uint, uint){
        uint256 lpBalane = IERC20(_pair).balanceOf(address(this));
        require(lpBalane >= _amount, "FarmRouter2: INSUFFICIENT amount");
        IERC20(_pair).transfer(_pair, _amount);
        (uint amount0, uint amount1) = IUniswapPair(_pair).burn(address(this));
        return (amount0, amount1);
        // address token0 = IUniswapPair(_pair).token0();
        // address token1 = IUniswapPair(_pair).token1();
        // (uint reserve0, uint reserve1,) = IUniswapV2Pair(_pair).getReserves();
        // console.log("removeLiquidity getReserves:", reserve0, reserve1);
        // if(amount0 > _debt) {
        //     sellToTinu(_pair, amount0 - _debt, reserve0, reserve1);
        // }

        // (uint256 tinuAmount, uint256 tokenAmount) =  (amount0, amount1);
        // (address tokenA, address tokenB)  = (token0, token1);
        // (uint reserveA, uint reserveB) =  ( reserve0,  reserve1);
        // if( token0 != TINU) {
        //     ( tinuAmount,  tokenAmount) =   ( amount1, amount0);
        //     ( tokenA,  tokenB)          =   ( token1, token0);
        //     ( reserveA,  reserveB)      =   ( reserve1,  reserve0);
        // }
 
        // if(tinuAmount > _debt) {
        //     uint256 delta = tinuAmount - _debt;
        //     uint256 amountOut = UniswapV2Library.getAmountOut(delta, reserveA, reserveB);
        //      IERC20(TINU).transfer(pair, delta);
        //      (uint256 amount0Out, uint256 amount1Out) = token0 == TINU ? (uint256(0), amountOut) : (amountOut, uint256(0));
        //      IUniswapPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
        // }else if(tinuAmount < _debt) {
        //     uint256 delta = _debt - tinuAmount;
        //     IERC20(tokenB).transfer(pair, delta);
        //     uint256 amountIn = UniswapV2Library.getAmountIn(delta, reserveB, reserveA);
        //     (uint256 amount0Out, uint256 amount1Out) = token0 == TINU ? (amountIn, uint256(0)) : ( uint256(0), amountIn);
        //      IUniswapPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
        // }

        // uint256 tinuBalance = IERC20(TINU).balanceOf(address(this));
        // require(tinuBalance >= _debt, "no");

        // IERC20(TINU).transfer(VAULT, _debt);
        // IVault(VAULT).decreaseDebt(pair, _receiver);

        // uint256 tokenBbalance = IERC20(token1).balanceOf(address(this));
        // IERC20(TINU).transfer(_receiver, tokenBbalance);
    }

    function sellToTinu(address pair, uint256 _delta, uint256 _reserveA, uint256 _reserveB) internal {
        uint256 amountOut = UniswapV2Library.getAmountOut(_delta, _reserveA, _reserveB);
        IERC20(TINU).transfer(pair, _delta);
        // (uint256 amount0Out, uint256 amount1Out) = token0 == TINU ? (uint256(0), amountOut) : (amountOut, uint256(0));
         (uint256 amount0Out, uint256 amount1Out) = (uint256(0), amountOut);
        IUniswapPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    // function sellTinu(address pair,  uint256 _delta, uint256 _reserveA, uint256 _reserveB) internal {
    //      IERC20(tokenB).transfer(pair, _delta);
    //      uint256 amountIn = UniswapV2Library.getAmountIn(_delta, _reserveB, _reserveA);
    //       (uint256 amount0Out, uint256 amount1Out) = (_amountOut, uint256(0));
    // }

    // _collateralToken: ulp address 
    // amount: ulp amount
    function withdraw(address _collateralToken, uint256 _amount, address _to) public {
        address _pair = pairs[_collateralToken];
        require(_pair != address(0), "FarmRouter2: collateralToken error!");
         bytes memory _data = abi.encodeWithSignature("removeLiquidity(address,address,uint256)", _pair, msg.sender, _amount);
        FlashCallbackData memory fcData = FlashCallbackData(_data, 1);
        // console.log(msg.sender, _collateralToken, address(this), _amount);
        IVault(VAULT).decreaseCollateralFrom(msg.sender, _collateralToken, address(this), _amount, abi.encode(fcData));
    }
}
