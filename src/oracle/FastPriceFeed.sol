// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "../interfaces/IFastPriceFeed.sol";
import "../interfaces/IVaultPriceFeed.sol";

contract FastPriceFeed is IFastPriceFeed {
    // fit data in a uint256 slot to save gas costs
    struct PriceDataItem {
        uint160 refPrice; // Chainlink price
        uint32 refTime; // last updated at time
        uint32 cumulativeRefDelta; // cumulative Chainlink price delta
        uint32 cumulativeFastDelta; // cumulative fast price delta
    }

    address public fastPriceEvents;
    address public vaultPriceFeed;
    uint256 constant public BITMASK_32 =  ~uint256(0) >> (256 - 32);
    uint256 public constant MAX_REF_PRICE = type(uint160).max;
    uint256 public constant MAX_CUMULATIVE_REF_DELTA = type(uint32).max;
    uint256 public constant MAX_CUMULATIVE_FAST_DELTA = type(uint32).max;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant CUMULATIVE_DELTA_PRECISION = 10 * 1000 * 1000;

    // array of tokens used in setCompactedPrices, saves L1 calldata gas costs
    address[] public tokens;
    // array of tokenPrecisions used in setCompactedPrices, saves L1 calldata gas costs
    // if the token price will be sent with 3 decimals, then tokenPrecision for that token
    // should be 10 ** 3
    uint256[] public tokenPrecisions;


    uint256 public priceDuration;
    uint256 public maxPriceUpdateDelay;
    uint256 public spreadBasisPointsIfInactive;
    uint256 public spreadBasisPointsIfChainError;
    uint256 public minBlockInterval;
    uint256 public maxTimeDeviation;
    
    uint256 public override lastUpdatedAt;
    uint256 public override lastUpdatedBlock;
       
    uint256 public priceDataInterval;
    
    mapping (address => uint256) public prices;

    mapping (address => bool) public isUpdater;

    mapping (address => PriceDataItem) public priceData;
    mapping (address => uint256) public maxCumulativeDeltaDiffs;

    event DisableFastPrice(address signer);
    event EnableFastPrice(address signer);
    event PriceData(address token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event MaxCumulativeDeltaDiffExceeded(address token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);

    modifier onlyUpdater() {
        require(isUpdater[msg.sender], "FastPriceFeed: forbidden");
        _;
    }

    function setPricesWithBits(uint256 _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);
    }

    function _setPricesWithBits(uint256 _priceBits, uint256 _timestamp) private {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 j = 0; j < 8; j++) {
                uint256 index = j;
                if (index >= tokens.length) { return; }
                uint256 startBit = 32 * j;
                uint256 price = (_priceBits >> startBit) & BITMASK_32;

                address token = tokens[j];
                uint256 tokenPrecision = tokenPrecisions[j];
                // uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(tokenPrecision);
                uint256 adjustedPrice = price * PRICE_PRECISION / tokenPrecision;
                _setPrice(token, adjustedPrice, _vaultPriceFeed, _fastPriceEvents);
            }
        }
    }

    function _setLastUpdatedValues(uint256 _timestamp) private returns (bool) {
        if (minBlockInterval > 0) {
            // require(block.number.sub(lastUpdatedBlock) >= minBlockInterval, "FastPriceFeed: minBlockInterval not yet passed");
              require(block.number - lastUpdatedBlock >= minBlockInterval, "FastPriceFeed: minBlockInterval not yet passed");
        }

        uint256 _maxTimeDeviation = maxTimeDeviation;
        require(_timestamp > block.timestamp - _maxTimeDeviation, "FastPriceFeed: _timestamp below allowed range");
        require(_timestamp < block.timestamp + _maxTimeDeviation, "FastPriceFeed: _timestamp exceeds allowed range");

        // do not update prices if _timestamp is before the current lastUpdatedAt value
        if (_timestamp < lastUpdatedAt) {
            return false;
        }

        lastUpdatedAt = _timestamp;
        lastUpdatedBlock = block.number;

        return true;
    }

    function _setPrice(address _token, uint256 _price, address _vaultPriceFeed, address _fastPriceEvents) private {
        // if (_vaultPriceFeed != address(0)) {
        //     uint256 refPrice = IVaultPriceFeed(_vaultPriceFeed).getLatestPrimaryPrice(_token);
        //     uint256 fastPrice = prices[_token];

        //     (uint256 prevRefPrice, uint256 refTime, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);

        //     if (prevRefPrice > 0) {
        //         uint256 refDeltaAmount = refPrice > prevRefPrice ? refPrice.sub(prevRefPrice) : prevRefPrice.sub(refPrice);
        //         uint256 fastDeltaAmount = fastPrice > _price ? fastPrice.sub(_price) : _price.sub(fastPrice);

        //         if (refTime.div(priceDataInterval) != block.timestamp.div(priceDataInterval)) {
        //             cumulativeRefDelta = 0;
        //             cumulativeFastDelta = 0;
        //         }

        //         cumulativeRefDelta = cumulativeRefDelta.add(refDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(prevRefPrice));
        //         cumulativeFastDelta = cumulativeFastDelta.add(fastDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(fastPrice));
        //     }

        //     if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
        //         emit MaxCumulativeDeltaDiffExceeded(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
        //     }

        //     _setPriceData(_token, refPrice, cumulativeRefDelta, cumulativeFastDelta);
        //     emit PriceData(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
        // }

        // prices[_token] = _price;
        // _emitPriceEvent(_fastPriceEvents, _token, _price);
    }
    function _setPriceData(address _token, uint256 _refPrice, uint256 _cumulativeRefDelta, uint256 _cumulativeFastDelta) private {
        require(_refPrice < MAX_REF_PRICE, "FastPriceFeed: invalid refPrice");
        // skip validation of block.timestamp, it should only be out of range after the year 2100
        require(_cumulativeRefDelta < MAX_CUMULATIVE_REF_DELTA, "FastPriceFeed: invalid cumulativeRefDelta");
        require(_cumulativeFastDelta < MAX_CUMULATIVE_FAST_DELTA, "FastPriceFeed: invalid cumulativeFastDelta");

        priceData[_token] = PriceDataItem(
            uint160(_refPrice),
            uint32(block.timestamp),
            uint32(_cumulativeRefDelta),
            uint32(_cumulativeFastDelta)
        );
    }

    function getPriceData(address _token) public view returns (uint256, uint256, uint256, uint256) {
        PriceDataItem memory data = priceData[_token];
        return (uint256(data.refPrice), uint256(data.refTime), uint256(data.cumulativeRefDelta), uint256(data.cumulativeFastDelta));
    }

    function _emitPriceEvent(address _fastPriceEvents, address _token, uint256 _price) private {
        if (_fastPriceEvents == address(0)) {
            return;
        }
        // IFastPriceEvents(_fastPriceEvents).emitPriceEvent(_token, _price);
    }
}