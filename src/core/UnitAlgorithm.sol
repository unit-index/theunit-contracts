// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import { console2 } from "forge-std/console2.sol";

interface IMedian{
     function read() external view returns (uint256);
}
contract UnitAlgorithm {

    address public median;

    mapping (address => bool) public orcl;

    uint256 public lastMonthUnitPrice;

    struct MarketInfo{
        uint256 lastMonthClosePrice;
        uint256 lastMonthMarketCap;
        uint256 updateTime;
    }

    mapping (uint256 => address[]) public tokensPerMonth;

    mapping (uint256 => mapping ( address => MarketInfo)) public tokenPerMonthMarketInfo;

    constructor(address _median){
        median = _median;
    }

    function setOrcl(address _account, bool _a) public {
        orcl[_account] = _a;
    }

    function updateTokens(uint256 _month, address[] calldata _token) public {  // only gov
        tokensPerMonth[_month] = _token;
    }

    function recover(uint256 _lastMCP, uint256 _lastMMC, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_lastMCP, _lastMMC)))),
            v, r, s
        );
    }
    /*
        Pre-writing can be done unlimited times, but only the last pre-writing is valid.
        For example, pre-writing can be done before the last day of the month at 23:59:59.
        On the first day of the next month at 00:00:00, the pre-writing can take effect.
    */
    function updateMarketInfo(uint256 _month, address _token, uint256[] calldata _lastMCP, uint256[] calldata _lastMMC, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) public {
        MarketInfo storage marketInfo =  tokenPerMonthMarketInfo[_month][_token];

        require(_lastMCP.length == _lastMMC.length, "length not eq!");
        require(_month >= block.timestamp, "time out!");
        for(uint i = 0; i < _lastMCP.length; i++ ) {
            address signer = recover(_lastMCP[i], _lastMMC[i], v[i], r[i],s[i]);
            require(orcl[signer], "account not control");
            marketInfo.lastMonthClosePrice = _lastMCP[i];
            marketInfo.lastMonthMarketCap = _lastMMC[i];
            marketInfo.updateTime = block.timestamp;
        }

        lastMonthUnitPrice = IMedian(median).read();
    }

    function totalMarketCap(uint256 _month) public view returns(uint256) {
        address[] memory _tokens = tokensPerMonth[_month];
        uint256 _totalMarketCap = 0;
        for(uint i = 0 ; i < _tokens.length; i++) {
            MarketInfo memory marketInfo = tokenPerMonthMarketInfo[_month][_tokens[i]];
            _totalMarketCap += marketInfo.lastMonthMarketCap;
        }
        return _totalMarketCap;
    }
    // test
    function calculate(uint256 _month, uint256[] calldata _price) public view  returns(uint256) {
        uint256 _count = 0;
        address[] memory _tokens = tokensPerMonth[_month];

        for(uint i = 0; i< _tokens.length; i++) {
            MarketInfo memory  marketInfo = tokenPerMonthMarketInfo[_month][_tokens[i]];
            uint256 marketRate = marketInfo.lastMonthMarketCap / totalMarketCap(_month);
            _count += _price[i] / marketInfo.lastMonthClosePrice  * marketRate;
        }

        return _count * lastMonthUnitPrice;
    }
}