// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter.sol";
import "./interfaces/IUtilityMembership.sol";

contract Utility is IUtilityMeter, IUtilityMembership {
    address public owner;
    address public nft;
    bool public is721;
    IUtilityHelper.MembershipType mType;

    struct Meter {
        address account;
        uint256 balance;
        uint256 startAt;
        bool status;
    }

    uint256 public memberPrice;
    uint256 public rightPrice;
    mapping(uint256 => Meter) public meters;

    event MembershipRequested(uint256 id, address account);
    event MembershipApproved(uint256 id, address account);
    event UseRightRequested(uint256 id, address account);
    event UseRightApproved(uint256 id, address account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Utility: the caller is not the owner");
        _;
    }

    constructor(
        address owner_,
        address nft_,
        bool is721_,
        IUtilityHelper.MembershipType mType_
    ) {
        owner = owner_;
        nft = nft_;
        is721 = is721_;
        mType = mType_;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function setMembershipPrice(uint256 price) external onlyOwner {
        memberPrice = price;
    }

    function setRightPrice(uint256 price) external onlyOwner {
        rightPrice = price;
    }

    function isValidMember(uint256 tokenId) public view returns (bool) {
        return meters[tokenId].status;
    }

    function requestMembership(uint256 tokenId) external payable {
        require(
            is721
                ? (IERC721(nft).ownerOf(tokenId) == msg.sender)
                : (IERC1155(nft).balanceOf(msg.sender, tokenId) > 0),
            "Utility: caller is not the owner of this nft"
        );
        require(!meters[tokenId].status, "Utility: membership already approved");
        require(meters[tokenId].account == address(0), "Utility: pending request already exists");
        require(msg.value >= memberPrice, "Utility: insufficient to request membership");
        meters[tokenId] = Meter(msg.sender, 0, block.timestamp, true);
        if (msg.value > memberPrice) payable(msg.sender).transfer(msg.value - memberPrice);
        emit MembershipRequested(tokenId, msg.sender);
    }

    function approveRequest(uint256 tokenId) external onlyOwner {
        require(
            meters[tokenId].account != address(0) && !meters[tokenId].status,
            "Utility: no pending request for token id"
        );
        meters[tokenId].status = true;
        emit MembershipApproved(tokenId, meters[tokenId].account);
    }

    function increaseBalance(uint256 tokenId) external payable {
        require(meters[tokenId].status, "Utility: not approved for token id");
        require(
            meters[tokenId].account == msg.sender,
            "Utility: caller is not the owner of this nft"
        );
        meters[tokenId].balance += msg.value;
    }

    function requestUseRight(uint256 tokenId) external onlyOwner {
        require(meters[tokenId].status, "Utility: not approved for token id");
        emit UseRightRequested(tokenId, msg.sender);
    }

    function approveUseRights(uint256 tokenId) external {
        require(meters[tokenId].status, "Utility: not approved for token id");
        require(
            meters[tokenId].account == msg.sender,
            "Utility: caller is not the owner of this nft"
        );
        emit UseRightApproved(tokenId, meters[tokenId].account);
    }

    function useRight(uint256 tokenId) external onlyOwner {
        require(meters[tokenId].status, "Utility: not approved for token id");
        meters[tokenId].balance -= rightPrice;
    }

    function assignTo(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Utility: new owner address is 0x0");
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
}
