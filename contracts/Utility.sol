// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Utility {
    address public owner;
    address public nft;
    bool public is721;

    bool public status;
    uint256 public balance;
    uint256 public price;
    uint256 public expireDate;
    address public wallet;

    mapping(uint256 => address) public meterWallets;

    modifier onlyOwner() {
        require(msg.sender == owner, "Utility: the caller is not the owner");
        _;
    }

    constructor(
        address owner_,
        address nft_,
        bool is721_
    ) {
        owner = owner_;
        nft = nft_;
        is721 = is721_;
    }

    function isValid(uint256 tokenId_) public view returns (bool) {
        return meterWallets[tokenId_] == address(0);
    }

    function setStatus(bool status_) external onlyOwner {
        status = status_;
    }

    function setBalance(uint256 balance_) external onlyOwner {
        balance = balance_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setExpireDate(uint256 expireDate_) external onlyOwner {
        require(expireDate_ > block.timestamp, "Utility: expire date should be later than now");
        expireDate = expireDate_;
    }

    function setWallet(address wallet_) external onlyOwner {
        require(wallet_ != address(0), "Utility: zero wallet address");
        wallet = wallet_;
    }

    function begin(uint256 tokenId_, address wallet_) external onlyOwner {
        require(isValid(tokenId_), "Utility: already began");
        meterWallets[tokenId_] = wallet_;
    }

    function end(uint256 tokenId_) external onlyOwner {
        delete meterWallets[tokenId_];
    }

    function makePayment() external {}

    function use() external payable {
        require(msg.value >= price, "Utility: insufficient to use");
        if (msg.value > price) payable(msg.sender).transfer(msg.value - price);
    }
}
