// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EnglishAuction {
    string public item;
    address payable public immutable seller;
    uint256 public endsAt;
    bool public started;
    bool public ended;
    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public bids;

    event Start(string _item, uint256 currentPrice);
    event Bid(address _bidder, uint256 _bid);
    event End(address _highestBidder, uint256 _highestBid);
    event Withdraw(address _sender, uint256 _refundAmount);

    constructor(string memory _item, uint256 _startingBid) {
        item = _item;
        highestBid = _startingBid;
        seller = payable(msg.sender);
    }

    modifier onlySeller() {
        require(seller == msg.sender, "not a seller");
        _;
    }

    modifier hasStarted() {
        require(started, "has not started yet");
        _;
    }

    modifier notEnded() {
        require(block.timestamp < endsAt, "has ended");
        _;
    }

    function start() external onlySeller {
        require(!started, "has already started");
        started = true;
        endsAt = block.timestamp + 30;
        emit Start(item, highestBid);
    }

    function bid() external payable hasStarted notEnded {
        require(msg.value > highestBid, "bid is lower than current");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function end() external hasStarted {
        require(!ended, "has been already ended");
        require(block.timestamp >= endsAt, "can't stop auction yet");
        ended = true;

        if (highestBidder != address(0)) {
            seller.transfer(highestBid);
        }

        emit End(highestBidder, highestBid);
    }

    function withdraw() external {
        uint256 refundAmount = bids[msg.sender];
        require(refundAmount > 0, "incorrect refund amount");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);

        emit Withdraw(msg.sender, refundAmount);
    }
}
