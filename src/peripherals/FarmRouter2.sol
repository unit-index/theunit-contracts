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

    address public VAULT;

    mapping (address => mapping (address=> uint256)) public account;

    struct FlashCallbackData{
        bytes call;
        bytes func;
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

    function depositETH() public payable {
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        address pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, WETH, TINU);
        _deposit(pair, WETH);
    }

    function deposit(address _depositToken, uint256 _amount) public {
        IERC20(_depositToken).transferFrom(msg.sender, address(this), _amount);
        address pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, _depositToken, TINU);
        _deposit(pair, _depositToken);
    }
    /*
        _collateralToken is LP token
        _depositToken is assets
    */
    function _deposit(address _collateralToken, address _depositToken) internal {
        uint256 depositAmounts = IERC20(_depositToken).balanceOf(address(this));
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(UNISWAP_FACTORY, _depositToken, TINU);
        uint needTinuAmounts = UniswapV2Library.quote(depositAmounts, reserveA, reserveB);
        bytes memory _data = abi.encodeWithSignature("addLiquidity(address,address,address,uint256,uint256)", _collateralToken, _depositToken, TINU, depositAmounts, needTinuAmounts);
        IVault(VAULT).flashLoanFrom(msg.sender, _collateralToken, needTinuAmounts, address(this), _data);
       
    }

    function flashLoanCall(address _sender, address _collateralToken, uint256 _amount, bytes calldata _data) external override {
        require(msg.sender == VAULT, "no");
       (bool success, ) = address(this).call(_data);
       if(success) {
            IVault(VAULT).increaseCollateral(_collateralToken, _sender);
       }else{
            revert("FarmRouter2: call error!");
       }
    }

    function addLiquidity(address pair, address tokenA, address tokenB, uint256 amountA, uint256 amountB) public returns(uint) {
        uint256 _amountA = IERC20(tokenA).balanceOf(address(this));
        uint256 _amountB = IERC20(tokenB).balanceOf(address(this));
        require(amountA == _amountA, "FarmRouter2: INSUFFICIENT amountA");
        require(amountB == _amountB, "FarmRouter2: INSUFFICIENT amountB");
        IERC20(tokenA).transfer(pair, _amountA);
        IERC20(tokenB).transfer(pair, _amountB);
        uint liquidity = IUniswapPair(pair).mint(VAULT);
        return liquidity;
    }

    function removeLiquidity(address pair, address _receiver, uint256 _amount, uint256 _debt) public returns(uint, uint){
        uint256 lpBalane = IERC20(pair).balanceOf(address(this));
        require(lpBalane >= _amount, "no");
        IERC20(pair).transfer(pair, _amount);
        (uint amount0, uint amount1) = IUniswapPair(pair).burn(address(this));
        address token0 = IUniswapPair(pair).token0();
        address token1 = IUniswapPair(pair).token1();
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();

        

        /*
        (uint256 tinuAmount, uint256 tokenAmount) =  (amount0, amount1);
        (address tokenA, address tokenB)  = (token0, token1);
        (uint reserveA, uint reserveB) =  ( reserve0,  reserve1);
        if( token0 != TINU) {
            ( tinuAmount,  tokenAmount) =   ( amount1, amount0);
            ( tokenA,  tokenB)          =   ( token1, token0);
            ( reserveA,  reserveB)      =   ( reserve1,  reserve0);
        }
 
        if(tinuAmount > _debt) {
            uint256 delta = tinuAmount - _debt;
            uint256 amountOut = UniswapV2Library.getAmountOut(delta, reserveA, reserveB);
             IERC20(TINU).transfer(pair, delta);
             (uint256 amount0Out, uint256 amount1Out) = token0 == TINU ? (uint256(0), amountOut) : (amountOut, uint256(0));
             IUniswapPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
        }else if(tinuAmount < _debt) {
            uint256 delta = _debt - tinuAmount;
            IERC20(tokenB).transfer(pair, delta);
            uint256 amountIn = UniswapV2Library.getAmountIn(delta, reserveB, reserveA);
            (uint256 amount0Out, uint256 amount1Out) = token0 == TINU ? (amountIn, uint256(0)) : ( uint256(0), amountIn);
             IUniswapPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        uint256 tinuBalance = IERC20(TINU).balanceOf(address(this));
        require(tinuBalance >= _debt, "no");
        IERC20(TINU).transfer(VAULT, _debt);
        IVault(VAULT).decreaseDebt(pair, _receiver);
        uint256 tokenBbalance = IERC20(tokenB).balanceOf(address(this));
        IERC20(TINU).transfer(_receiver, tokenBbalance);
        */
    }

    function getAmountOut(uint256 amount0, uint256 amount1) public view {
        
    }
    // _collateralToken 是LP。
    // amount 要提的LP数量
    // to 是接收地址
    // 计算 有多少资产是不是？ K的平方 / Z = Y
    function withdraw(address _collateralToken, uint256 _amount, address _to) public {
        //  uint256 _collateralAmount = account[msg.sender][_collateralToken];
        //  console.log(_collateralAmount);
        // uint256 lp = IERC20(_collateralToken).balanceOf(address(this));
        //  IERC20(_collateralToken).approve(VAULT, 2**256 - 1);
        (uint256 tokenAssets, uint256 debt) = IVault(VAULT).vaultOwnerAccount(msg.sender, _collateralToken);
        require(_amount <= tokenAssets, "FarmRouter2: amount out of range!");
        // uint256 _debt =  (_amount / tokenAssets) *  debt;
         uint256 _debt = debt;
         bytes memory _data = abi.encodeWithSignature("removeLiquidity(address,address,uint256,uint256)", _collateralToken,msg.sender, _amount, _debt);

        IVault(VAULT).decreaseCollateralFrom(msg.sender, _collateralToken, address(this), _amount, _data);
    }
}