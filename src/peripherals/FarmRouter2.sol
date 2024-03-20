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

    address public UNISWAP_FACTORY;

    address public WETH;

    address public VAULT;

    // address public uLP;
    mapping (address => address) public uLps; // pair => ulp
    mapping (address => address) public pairs; //ulp => pair

    // mapping (address => type2) name;

    struct AddLP{
        address pair; 
        address tokenA; 
        address tokenB; 
        uint256 amountA;
        uint256 amountB;
        uint8 lockDay;
        address account;
    }

    struct RemoveLP{
        address pair;
        address receiver;
        uint256 lockIndex;
        uint256 amount;
    }

    struct FlashCallbackData{
        uint8 callType;
        bytes callData; 
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

    function compound(address _ulp, address _unUlp, address _account, uint8 _lockDay) public {
        require( IRewardTracker(_ulp).claimable(_account) > 0, "FarmRouter: claimable cannot be 0");
        IRewardTracker(_ulp).claimForAccount(_account, address(this));
        address _unTinuPair = UniswapV2Library.pairFor(UNISWAP_FACTORY, UN, TINU);
        _deposit(_unUlp, UN, _unTinuPair, _lockDay, msg.sender);
    }

    function depositETH(uint8 lock) public payable {
        require(msg.value > 0, "FarmRouter: value cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        address _pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, WETH, TINU);
        address _uLP = uLps[_pair];
        _deposit(_uLP, WETH, _pair, lock,  msg.sender);
    }

    function deposit(address _depositToken, uint256 _amount, uint8 _lockDay) public {
        IERC20(_depositToken).transferFrom(msg.sender, address(this), _amount);
        address _pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, _depositToken, TINU);
        address _uLP = uLps[_pair];
        require(_uLP != address(0), "FarmRouter: can not pair!");
        _deposit(_uLP, _depositToken, _pair, _lockDay, msg.sender);
    }

    // amount: ulp amount
    function withdraw(address _uLP, uint256 _lockIndex, address _receiver) public {
        address _pair = pairs[_uLP];
        require(_pair != address(0), "FarmRouter2: collateralToken error!");
        (uint256 _amount, , ) = IRewardTracker(_uLP).locked(msg.sender, _lockIndex);
        RemoveLP memory _data = RemoveLP(_pair, _receiver, _lockIndex, _amount);
        FlashCallbackData memory fcData = FlashCallbackData(1, abi.encode(_data));
        IVault(VAULT).decreaseCollateralFrom(msg.sender, _uLP, address(this), _amount, abi.encode(fcData));
    }

    /*
        _collateralToken is ULP token
        _depositToken is assets
    */
    function _deposit(address _collateralToken, address _depositToken, address _pair, uint8 _lockDay, address _account) internal {
        uint256 depositAmounts = IERC20(_depositToken).balanceOf(address(this));
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(UNISWAP_FACTORY, _depositToken, TINU);
        uint needTinuAmounts = UniswapV2Library.quote(depositAmounts, reserveA, reserveB);

        AddLP memory _data = AddLP(_pair, _depositToken, TINU, depositAmounts, needTinuAmounts, _lockDay, _account );
        FlashCallbackData memory fcData = FlashCallbackData(0, abi.encode(_data));
        IVault(VAULT).flashLoanFrom(msg.sender, _collateralToken, needTinuAmounts, address(this), abi.encode(fcData));
    }

    function flashLoanCall(address _sender, address _collateralToken, uint256 _amount, bytes calldata _data) external override {
        require(msg.sender == VAULT, "FarmRouter2: no");
        FlashCallbackData memory fcData = abi.decode(_data, (FlashCallbackData));
        if(fcData.callType == 0) { 
            AddLP memory addLP = abi.decode(fcData.callData, (AddLP));
            uint256 liquidity = addLiquidity(addLP.pair, addLP.tokenA, addLP.tokenB, addLP.amountA, addLP.amountB);
            address _uLP = uLps[addLP.pair];
            IRewardTracker(_uLP).stakeForAccount(address(this), addLP.account, addLP.pair, liquidity, addLP.lockDay);

            uint256 balance0 =  IERC20(_uLP).balanceOf(VAULT);
            IERC20(_uLP).transferFrom(addLP.account, VAULT, liquidity);
            uint256 balance1 =  IERC20(_uLP).balanceOf(VAULT);
            IVault(VAULT).increaseCollateral(_collateralToken, addLP.account);  

        } else if(fcData.callType == 1) {
            // address _pair = pairs[_collateralToken];
            RemoveLP memory removeLP = abi.decode(fcData.callData, (RemoveLP));
    
            IERC20(_collateralToken).transfer(_sender, removeLP.amount);
            IRewardTracker(_collateralToken).unstakeForAccount(_sender, removeLP.pair, removeLP.lockIndex , address(this)); // 从
 
            uint256 lpBalane = IERC20(removeLP.pair).balanceOf(address(this));
            require(lpBalane >= _amount,"FarmRouter2: unstake error");

            (uint amount0, uint amount1) = removeLiquidity(removeLP.pair, removeLP.amount);
            uint256 tinuBalance = IERC20(TINU).balanceOf(address(this));
            IERC20(TINU).transfer(VAULT, tinuBalance);
            IVault(VAULT).decreaseDebt(_collateralToken, _sender);
            address token0 = IUniswapPair(removeLP.pair).token0();
            address token1 = IUniswapPair(removeLP.pair).token1();

            // TODO: deposit把欠多少TINU存下来，然后在每次 remove 的时候 按照这个还就行了。
            // uint256 outAmount = getAmountOut(_collateralToken, _sender, removeLP.amount);
            if(token0 == TINU) {
                  IERC20(token1).transfer(_sender, amount1);
            }else {
                  IERC20(token0).transfer(_sender, amount0);
            }

            // uint256 tinuBalance2 = IERC20(TINU).balanceOf(address(this));
            // (uint256 tokenAssets, uint256 debt) = IVault(VAULT).vaultOwnerAccount(msg.sender, _collateralToken);
        }
    }
    // 获取多少头寸
    function getAmountOut(address _collateralToken, address _account, uint256 _amount ) public view returns(uint256) {
         (uint256 tokenAssets, uint256 debt) = IVault(VAULT).vaultOwnerAccount(_account, _collateralToken);
        return  _amount * 1e18 / tokenAssets * debt / 1e18;
    }

    function addLiquidity(address pair, address tokenA, address tokenB, uint256 amountA, uint256 amountB) private returns(uint) {
        uint256 _amountA = IERC20(tokenA).balanceOf(address(this));
        uint256 _amountB = IERC20(tokenB).balanceOf(address(this));
        require(amountA == _amountA, "FarmRouter2: INSUFFICIENT amountA");
        require(amountB == _amountB, "FarmRouter2: INSUFFICIENT amountB");
        IERC20(tokenA).transfer(pair, _amountA);
        IERC20(tokenB).transfer(pair, _amountB);
        uint liquidity = IUniswapPair(pair).mint(address(this));
        return liquidity;
    }
    
    function removeLiquidity(address _pair, uint256 _amount) private returns(uint, uint){
        uint256 lpBalane = IERC20(_pair).balanceOf(address(this));
        require(lpBalane >= _amount, "FarmRouter2: INSUFFICIENT amount");
        IERC20(_pair).transfer(_pair, _amount);
        (uint amount0, uint amount1) = IUniswapPair(_pair).burn(address(this));
        return (amount0, amount1);
    }

    function sellToTinu(address pair, uint256 _delta, uint256 _reserveA, uint256 _reserveB) internal {
        uint256 amountOut = UniswapV2Library.getAmountOut(_delta, _reserveA, _reserveB);
        IERC20(TINU).transfer(pair, _delta);
        (uint256 amount0Out, uint256 amount1Out) = (uint256(0), amountOut);
        IUniswapPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
    }
}
