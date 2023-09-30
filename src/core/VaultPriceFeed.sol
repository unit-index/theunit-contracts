// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '../interfaces/IPriceFeed.sol';
import '../interfaces/IVaultPriceFeed.sol';

contract VaultPriceFeed is IVaultPriceFeed {
    using SafeMath for uint256;

    address public gov;

    mapping (address => address) public priceFeeds;

    mapping (address => uint256) public priceDecimals;

    uint256 public constant PRICE_PRECISION = 10 ** 30;

    modifier onlyGov() {
        require(msg.sender == gov, "VaultPriceFeed: forbidden");
        _;
    }

    constructor() {
        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals
    ) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
    }

    // 把价格统一转成了30位
    function getPrice(address _token) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        int256 price = priceFeed.latestAnswer();
        // uint256 _priceDecimals = priceDecimals[_token];
        return uint256(price);
    }

    function tokenToUnit(address _token, uint256 _price, uint256 amount) public view returns(uint256){
        uint256 _priceDecimals = priceDecimals[_token];
        return amount  * 1**_priceDecimals / _price;
    }
}