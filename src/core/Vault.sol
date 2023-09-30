// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;
import '../interfaces/IVault.sol';
import "../interfaces/ITinuToken.sol";
import '../interfaces/ICollateralManager.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '../interfaces/IVaultPriceFeed.sol';

// import "hardhat/console.sol";

contract Vault is IVault {

    using SafeMath for uint256;

    event IncreaseCollateral (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 amount,
        uint256 indexed liquidationPrice
    );

    event DecreaseCollateral (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 collateralAmount,
        uint256 indexed liquidationPrice
    );

    event CollateralOwnerTrasnfer (
        address indexed from,
        address indexed to,
        address token,
        uint256 tokenAssets,
        uint256 unitDebt
    );

    event IncreaseDebt (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 amount,
        uint256 indexed liquidationPrice
    );

    event DecreaseDebt (
        address indexed owner,
        uint256 indexed unitDebt,
        address collateralToken,
        uint256 amount,
        uint256 indexed liquidationPrice
    );

    event Approval(
        address indexed owner, 
        address operator,
        bool allow
    );

    event LiquidateCollateral(
        address indexed owner,
        address collateralToken,
        uint256 tokenAssets,
        uint256 unitDebt,
        address feeTo
    );

    address public gov;

    address public tinu;

    address public priceFeed;

    address public treasury;

    uint256 public liquidationTreasuryFee = 990; // 990 = 1.0%

    uint256 public liquidationRatio = 1150; // 1150 = 15.0%
    
    uint256 public minimumCollateral = 100 * 1e18 ; // default 100 UNIT
    
    struct Account {
        uint256 tokenAssets;
        uint256 tinuDebt;
    }

    mapping (address => mapping (address => Account) ) public override vaultOwnerAccount;

    mapping (address => Account) public vaultPoolAccount;

    mapping(address => mapping(address => bool)) public allowances;

    modifier onlyGov {
        require(msg.sender == gov, "Vault: onlyGov");
        _;
    }

    constructor(address _tinu) {
        gov = msg.sender;
        tinu = _tinu;
    }

    function setGov(address _gov) public onlyGov{
        gov = _gov;
    }

    function setPriceFeed(address _priceFeed) public onlyGov {
        priceFeed = _priceFeed;
    }

    function setLiquidationRatio(uint256 _ratio) public onlyGov {
        liquidationRatio = _ratio;
    }
    function setTreasury(address _treasury) public  onlyGov{
        treasury = _treasury;
    }

    function setMinimumCollateral(uint256 _minimumCollateral) public  onlyGov{
        minimumCollateral = _minimumCollateral;
    }

    function setLiquidationTreasuryFee(uint256 _liquidationTreasuryFee) public  onlyGov{
        liquidationTreasuryFee = _liquidationTreasuryFee;
    }

    // the governance controlling this function should have a timelock
    function upgradeVault(address _newVault, address _token, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_newVault, _amount);
    }

    function approve(address _operator, bool _allow) public {
        allowances[msg.sender][_operator] = _allow;
        emit Approval(msg.sender, _operator, _allow);
    }

    function increaseCollateral(
        address _collateralToken, 
        address _receiver
    ) external override returns (bool) {
        uint256 _balance0 = vaultPoolAccount[_collateralToken].tokenAssets;
        uint256 _balance1 = IERC20(_collateralToken).balanceOf(address(this));
        require(_balance1 > 0, "Vault: balance1==0");
        uint256 _balanceDelta = _balance1.sub(_balance0);
        require(_balanceDelta > 0, "Vault: 0");
        vaultOwnerAccount[_receiver][_collateralToken].tokenAssets =  vaultOwnerAccount[_receiver][_collateralToken].tokenAssets.add(_balanceDelta);
        vaultPoolAccount[_collateralToken].tokenAssets =  vaultPoolAccount[_collateralToken].tokenAssets.add(_balanceDelta);
        emit IncreaseCollateral(
            _receiver, 
            vaultOwnerAccount[_receiver][_collateralToken].tinuDebt, 
            _collateralToken, 
            _balanceDelta, 
            _getLiquidationPrice(_receiver, _collateralToken)
        );
        return true;
    }

    function decreaseCollateral(
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount
    ) external override returns (bool){
        _decreaseCollateral(msg.sender, _collateralToken, _receiver, _collateralAmount);
        return true;
    }

    function _decreaseCollateral(
        address _from,
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount
    ) internal returns (bool){
        uint256 _tokenAssets = vaultOwnerAccount[_from][_collateralToken].tokenAssets;
        require(_collateralAmount <= _tokenAssets, "Vault: insufficient collateral balance!");

        vaultOwnerAccount[_from][_collateralToken].tokenAssets =  vaultOwnerAccount[_from][_collateralToken].tokenAssets.sub(_collateralAmount);
        vaultPoolAccount[_collateralToken].tokenAssets =  vaultPoolAccount[_collateralToken].tokenAssets.sub(_collateralAmount);
     
        bool yes = validateLiquidation(_from, _collateralToken, true); 
        require(!yes, "Vault: collateral amount out of range");

        IERC20(_collateralToken).transfer(_receiver, _collateralAmount);
        emit DecreaseCollateral(
            _from, 
            vaultOwnerAccount[_from][_collateralToken].tinuDebt, 
            _collateralToken, 
            _collateralAmount, 
            _getLiquidationPrice(_from, _collateralToken));
        return true;
    }
    
    function decreaseCollateralFrom(
        address _from,
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount
    ) external override returns (bool){
        require(allowances[_from][msg.sender], "Vault: not allow");
        _decreaseCollateral(_from, _collateralToken, _receiver, _collateralAmount);
        return true;
    }

    function _increaseDebt(address _from, address _collateralToken, uint256 _amount, address _receiver) internal returns (bool)  {
        vaultOwnerAccount[_from][_collateralToken].tinuDebt = vaultOwnerAccount[_from][_collateralToken].tinuDebt.add(_amount);
        bool yes = validateLiquidation(_from, _collateralToken, true);
        require(!yes, "Vault: unit debt out of range");

        ITinuToken(tinu).mint(_receiver, _amount);
        emit IncreaseDebt(
            _from, 
            vaultOwnerAccount[_from][_collateralToken].tinuDebt,
            _collateralToken, 
            _amount, 
            _getLiquidationPrice(_from, _collateralToken)
        );
        return true;
    }
    
    function increaseDebt(address _collateralToken, uint256 _amount, address _receiver) external override returns (bool)  {
        _increaseDebt(msg.sender, _collateralToken, _amount, _receiver);
        
        return true;
    }
    function increaseDebtFrom(address _from, address _collateralToken, uint256 _amount, address _receiver) external override returns (bool)  {
        require(allowances[_from][msg.sender], "Vault: not allow");
        _increaseDebt(_from, _collateralToken, _amount, _receiver);

        return true;
    }

    function decreaseDebt(
        address _collateralToken,
        address _receiver
    ) external override returns (bool) {
        uint256 _balance = IERC20(tinu).balanceOf(address(this));
        require(_balance > 0, "balance == 0");
        ITinuToken(tinu).burn(_balance);
        vaultOwnerAccount[_receiver][_collateralToken].tinuDebt = vaultOwnerAccount[_receiver][_collateralToken].tinuDebt.sub(_balance);
        emit DecreaseDebt(
            _receiver, 
            vaultOwnerAccount[_receiver][_collateralToken].tinuDebt,
            _collateralToken, 
            _balance, 
            _getLiquidationPrice(_receiver, _collateralToken)
        );

        return true;
    }

    function liquidation(address _collateralToken, address _account, address _feeTo) external override returns (bool) {
        bool yes = validateLiquidation(_account, _collateralToken, false);
        require(yes, "Vault: no validateLiquidation");
        uint256 _balance = IERC20(tinu).balanceOf(address(this));
        Account storage account = vaultOwnerAccount[_account][_collateralToken];
        require(_balance >= account.tinuDebt, "Vault: insufficient unit token");
        ITinuToken(tinu).burn(account.tinuDebt);

        uint256 _treasuryFee =  account.tokenAssets.mul(1000).sub(account.tokenAssets.mul(liquidationTreasuryFee)).div(1000); // 1%, liquidationTreasuryFee default 990
        uint256 _returnCollateral = account.tokenAssets.sub(_treasuryFee);

        IERC20(_collateralToken).transfer(treasury, _treasuryFee);
        IERC20(_collateralToken).transfer(_feeTo, _returnCollateral);

        emit LiquidateCollateral(_account, _collateralToken, account.tokenAssets, account.tinuDebt, _feeTo);
        account.tinuDebt = 0;
        account.tokenAssets = 0;

        return true;
    }

    function validateLiquidation(address _account, address _collateralToken, bool _checkCollateral ) public view returns(bool){
        Account memory account = vaultOwnerAccount[_account][_collateralToken];
        uint256 _price = getPrice(_collateralToken);
        uint256 _tokenTinuAmount = tokenToTinu(_price, account.tokenAssets);

        if(_checkCollateral && account.tinuDebt > 0) {
            require(_tokenTinuAmount >=  minimumCollateral, "Vault: minimumCollateral");
        }

        if(_tokenTinuAmount.mul(1000) >= account.tinuDebt.mul(liquidationRatio)) { // liquidationRatio = 1150.  115.0  
            return false;
        }
        return true;
    }

    function _getLiquidationPrice(address _account, address _collateralToken ) public view returns(uint256) {
        Account memory account = vaultOwnerAccount[_account][_collateralToken];
        if (account.tokenAssets > 0) {
            uint256 _liquidationPrice = account.tinuDebt.mul(liquidationRatio).div(account.tokenAssets);
            return _liquidationPrice;
        } 
        return 0;
    }

    function tokenToTinu(uint256 _price, uint256 amount) public pure returns(uint256){
        return _price.mul(amount).div(1e18);
    }

    function getPrice(address _token) public override view returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token);
    }
   
    function transferVaultOwner(address _newAccount, address _collateralToken) external override {
        Account storage account = vaultOwnerAccount[msg.sender][_collateralToken];
        Account storage newAccount = vaultOwnerAccount[_newAccount][_collateralToken];
        require(newAccount.tokenAssets == 0, "Vault: newAccount not new");     
        
        newAccount.tokenAssets = newAccount.tokenAssets.add(account.tokenAssets);
        newAccount.tinuDebt = newAccount.tinuDebt.add(account.tinuDebt);

        account.tokenAssets = 0;
        account.tinuDebt = 0;
    
        emit CollateralOwnerTrasnfer(msg.sender, _newAccount, _collateralToken, account.tokenAssets, account.tinuDebt);
    }
}