// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IVault {

    // The number of all tokens in the pool
    // function poolAmounts(address _token) external view returns (uint256);
   
    function increaseCollateral(address _collateralToken, address _receiver) external returns (bool);
    
    function decreaseCollateral(
        address _collateralToken,
        address _receiver, 
        uint256 _collateralAmount
    ) external returns(bool);
    
    function decreaseCollateralFrom(
        address _from,
        address _collateralToken,
        address _receiver,
        uint256 _collateralAmount
    ) external returns (bool);

    function liquidation(address _token, address _account, address _feeTo
    ) external returns (bool);

    

    // function vaultOwnerAccount(address _receiver, address _collateralToken) external view returns (uint256);

    function increaseDebt(address _collateralToken, uint256 _amount, address _receiver) external returns (bool);
    function increaseDebtFrom(address from,address _collateralToken, uint256 _amount, address _receiver) external returns (bool);

    function decreaseDebt(
        address _collateralToken,
        address _receiver
    ) external returns (bool);

     function getPrice(address _token) external view returns (uint256);

    function transferVaultOwner(address _newAccount, address _collateralToken) external;
    // function transferFromVaultOwner(address _from ,address _newAccount, address _collateralToken, uint256 _tokenAssets, uint256 _unitDebt) external;

    function vaultOwnerAccount(address _account, address _collateralToken) external view returns (uint256, uint256);

}