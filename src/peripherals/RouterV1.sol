// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '../interfaces/IVault.sol';
import "../interfaces/IWETH.sol";
// import "hardhat/console.sol";

contract RouterV1 {
    
    address public VAULT;
    address public WETH;
    address public TINU;

    event IncreaseCollateral (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );

    event DecreaseCollateral (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );

    event MintUnit (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );
    event BurnUnit (
        address indexed receiver,
        address collateralToken,
        uint256 amount
    );
    
    // sepolia WETH 0x632AbC44b7C31B814DA1808325294572C3C1ef2a
    constructor (address _vault, address _weth, address _tinu) {
        VAULT = _vault;
        WETH = _weth;
        TINU = _tinu;
    } 
    
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
 
    function increaseCollateral(address _collateralToken, uint256 _tokenAmount, address _receiver) external returns(bool) {  
        require(IERC20(_collateralToken).balanceOf(msg.sender) >= _tokenAmount, "UintRouter: insufficient tokenAmount");
        IERC20(_collateralToken).transferFrom(msg.sender, VAULT, _tokenAmount);
        IVault(VAULT).increaseCollateral(_collateralToken, _receiver);
        emit IncreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        return true;
    }

    function increaseETH(address _receiver) external payable returns(bool) {  
        require(msg.value > 0, "UintRouter: amount cannot be 0");
        IWETH(WETH).deposit{value: msg.value}();
        IWETH(WETH).transfer(VAULT, msg.value);
        IVault(VAULT).increaseCollateral(WETH, _receiver);
        emit IncreaseCollateral(_receiver, WETH, msg.value);
        return true;
    }

    function decreaseCollateral(address _collateralToken, uint256 _tokenAmount, address _receiver) external returns(bool)  {
        require(_tokenAmount > 0, "UintRouter: amount cannot be 0");
        IVault(VAULT).decreaseCollateralFrom(msg.sender, _collateralToken, _receiver, _tokenAmount);
        emit DecreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        return true;
    }

    function decreaseETH(uint256 _ETHAmount, address _receiver) external returns(bool)  {
        require(_ETHAmount > 0, "UintRouter: amount cannot be 0");
        IVault(VAULT).decreaseCollateralFrom(msg.sender, WETH, address(this), _ETHAmount);
        IWETH(WETH).withdraw(_ETHAmount);
        safeTransferETH(_receiver, _ETHAmount);
        emit DecreaseCollateral(_receiver, WETH, _ETHAmount);
        return true;
    }

    function mintUnit(address _collateralToken, uint256 _UNITAmount, address _receiver) external returns(bool) {
        require(_UNITAmount > 0, "UintRouter: amount cannot be 0");
        IVault(VAULT).increaseDebtFrom(msg.sender, _collateralToken, _UNITAmount, _receiver);
        emit MintUnit(_receiver, _collateralToken, _UNITAmount);
        return true;
    }

    function burnUnit(address _collateralToken, uint256 _UNITAmount, address _receiver)  external returns(bool) {
         require(_UNITAmount > 0, "UintRouter: amount cannot be 0");
        IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
        IVault(VAULT).decreaseDebt( _collateralToken, _receiver);
        emit BurnUnit(_receiver, _collateralToken, _UNITAmount);
        return true;
    }

    function increaseCollateralAndMint(address _collateralToken, uint256 _tokenAmount, uint256 _UNITAmount, address _receiver) public returns(bool) {
        require(_tokenAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(_tokenAmount >0 ) {
            require(IERC20(_collateralToken).balanceOf(msg.sender) >= _tokenAmount, "UintRouter: in");
            IERC20(_collateralToken).transferFrom(msg.sender, VAULT, _tokenAmount);
            IVault(VAULT).increaseCollateral(_collateralToken, _receiver);
            emit IncreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        }
        if(_UNITAmount >0) {
            IVault(VAULT).increaseDebtFrom(msg.sender, _collateralToken, _UNITAmount, _receiver);   
            emit MintUnit(_receiver, _collateralToken, _UNITAmount);
        }
        return true;
    }

    function decreaseCollateralAndBurn(address _collateralToken, uint256 _tokenAmount, uint256 _UNITAmount, address _receiver) public returns(bool) {
        require(_tokenAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");  
        if(_UNITAmount > 0) {
            IVault(VAULT).decreaseCollateralFrom(msg.sender, _collateralToken, _receiver, _tokenAmount);
            IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
            emit DecreaseCollateral(_receiver, _collateralToken, _tokenAmount);
        }

        if(_tokenAmount > 0) {
            IVault(VAULT).decreaseDebt( _collateralToken, _receiver);
            emit BurnUnit(_receiver, _collateralToken, _UNITAmount);
        }
        return true;
    }

    function increaseETHAndMint(uint256 _UNITAmount, address _receiver) public payable returns(bool) {
        require(msg.value > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(msg.value >0 ) {
            IWETH(WETH).deposit{value: msg.value}();
            IWETH(WETH).transfer(VAULT, msg.value);
            IVault(VAULT).increaseCollateral(WETH, _receiver);
            emit IncreaseCollateral(_receiver, WETH, msg.value);
        }
        if(_UNITAmount >0) {
            IVault(VAULT).increaseDebtFrom(msg.sender, WETH, _UNITAmount, _receiver);   
            emit MintUnit(_receiver, WETH, _UNITAmount);
        }
        return true;
    }

    function decreaseETHAndBurn(uint256 _ETHAmount, uint256 _UNITAmount, address _receiver) public payable returns(bool) {   
        require(_ETHAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(_UNITAmount > 0) {
            IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
            IVault(VAULT).decreaseDebt(WETH, _receiver);
            emit BurnUnit(_receiver, WETH, _UNITAmount);
        }
    
        if(_ETHAmount > 0) {
            IVault(VAULT).decreaseCollateralFrom(msg.sender, WETH, address(this), _ETHAmount);
            uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
            require(wethBalance > 0, "UintRouter: WETH not allow 0");
            IWETH(WETH).withdraw(wethBalance);
            safeTransferETH(_receiver, wethBalance);
            emit DecreaseCollateral(_receiver, WETH, wethBalance);
        }
        return true;
    }

    function increaseETHAndBurn(uint256 _UNITAmount, address _receiver) public payable returns(bool) {
        require(msg.value > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");
        if(msg.value >0 ) {
            IWETH(WETH).deposit{value: msg.value}();
            IWETH(WETH).transfer(VAULT, msg.value);
            IVault(VAULT).increaseCollateral(WETH, _receiver);
            emit IncreaseCollateral(_receiver, WETH, msg.value);
        }
        if(_UNITAmount > 0) {
            IERC20(TINU).transferFrom(msg.sender, VAULT, _UNITAmount);
            IVault(VAULT).decreaseDebt(WETH, _receiver);
            emit BurnUnit(_receiver, WETH, _UNITAmount);
        }
        return true;
    }

    function decreaseETHAndMint(uint256 _ETHAmount, uint256 _UNITAmount, address _receiver) public returns(bool) {   
        require(_ETHAmount > 0 || _UNITAmount > 0, "UintRouter: amount cannot be 0");

        if(_ETHAmount > 0) {
            IVault(VAULT).decreaseCollateralFrom(msg.sender, WETH, address(this), _ETHAmount);
            uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
            require(wethBalance > 0, "UintRouter: WETH not allow 0");
            IWETH(WETH).withdraw(wethBalance);
            safeTransferETH(_receiver, wethBalance);
            emit DecreaseCollateral(_receiver, WETH, wethBalance);
        }
        if(_UNITAmount >0) {
            IVault(VAULT).increaseDebtFrom(msg.sender, WETH, _UNITAmount, _receiver);   
            emit MintUnit(_receiver, WETH, _UNITAmount);
        }
        return true;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'UintRouter::safeTransferETH: ETH transfer failed');
    }

    function liquidation(address _collateralToken, address _account, address _feeTo) external returns (bool) {
        (, uint256 _debt) = IVault(VAULT).vaultOwnerAccount(_account, _collateralToken);
        uint256 _balance = IERC20(TINU).balanceOf(msg.sender);
        require(_balance >= _debt, "UintRouter: insufficient TINU token");
        IERC20(TINU).transferFrom(msg.sender, VAULT, _debt);
        IVault(VAULT).liquidation(_collateralToken, _account, _feeTo);
        return true;
    }
}