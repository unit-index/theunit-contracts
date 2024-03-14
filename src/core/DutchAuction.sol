pragma solidity ^0.8.21;
import { IVault } from "../interfaces/IVault.sol";

contract DutchAuction {
    
    address public seller;
    uint256 public startingPrice;
    uint256 public reservePrice;
    uint256 public duration;
    uint256 public startTime;
    bool public auctionEnded;
    address public highestBidder;
    uint256 public highestBid;

    // struct Auction{
    // }

    event AuctionEnded(address winner, uint256 winningBid);

    constructor(uint256 _startingPrice, uint256 _reservePrice, uint256 _duration) {
        seller = msg.sender;
        startingPrice = _startingPrice;
        reservePrice = _reservePrice;
        duration = _duration;
        startTime = block.timestamp;
        auctionEnded = false;
        highestBidder = address(0);
        highestBid = 0;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can perform this action");
        _;
    }

    modifier onlyBeforeEnd() {
        require(!auctionEnded, "Auction has already ended");
        require(block.timestamp < startTime + duration, "Auction has ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(auctionEnded || block.timestamp >= startTime + duration, "Auction has not ended yet");
        _;
    }

    function createOrder(address _collateralToken, address _account) external {
        //  bool yes = IVault(vault).toAuction(_collateralToken, _account);
    }

    function placeBid() external payable onlyBeforeEnd {
        require(msg.value > highestBid, "Bid must be higher than current highest bid");
        // highestBidder.transfer(highestBid);
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function endAuction() external onlySeller onlyAfterEnd {
        require(!auctionEnded, "Auction has already ended");
        auctionEnded = true;
        if (highestBid >= reservePrice) {
            // seller.transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            emit AuctionEnded(address(0), 0);
        }
    }

    function withdraw() external onlyAfterEnd {
        require(msg.sender != highestBidder, "You are the highest bidder");
        require(msg.sender != seller, "You are the seller");
        require(auctionEnded, "Auction has not ended yet");
        payable(msg.sender).transfer(highestBid);
    }
}