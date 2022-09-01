// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BaseMemberUtility.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter721.sol";
import "./interfaces/IUtilityMembership721.sol";

contract MemberUtility721 is BaseMemberUtility, IUtilityMeter721, IUtilityMembership721 {
    mapping(uint256 => Meter) public meters;

    constructor(
        address owner_,
        address nft_,
        IUtilityHelper.MembershipType mType_
    ) {
        owner = owner_;
        nft = nft_;
        mType = mType_;
    }

    function isValidMember(uint256 tokenId) external view returns (bool) {
        return meters[tokenId].status;
    }

    function requestMembership(uint256 tokenId) external payable {
        Meter storage meter = meters[tokenId];
        require(
            IERC721(nft).ownerOf(tokenId) == msg.sender,
            "Utility: caller is not the owner of this nft"
        );
        require(!meter.status, "Utility: membership already approved");
        require(meter.account == address(0), "Utility: pending request already exists");
        require(msg.value >= memberPrice, "Utility: insufficient to request membership");
        if (msg.value > memberPrice) payable(msg.sender).transfer(msg.value - memberPrice);
        meters[tokenId] = Meter(msg.sender, 0, 0, false);
        emit MembershipRequested(tokenId, msg.sender);
    }

    function approveRequest(uint256 tokenId) external onlyOwner {
        Meter storage meter = meters[tokenId];
        require(
            meter.account != address(0) && !meter.status,
            "Utility: no pending request for token id"
        );
        meter.lastChecked = block.timestamp;
        meter.status = true;
        emit MembershipApproved(tokenId, meter.account);
    }

    function increaseBalance(uint256 tokenId) external payable {
        require(
            mType == IUtilityHelper.MembershipType.LIFETIME,
            "Utility: not normal lifetime membership"
        );
        Meter storage meter = meters[tokenId];
        require(meter.status, "Utility: not approved for token id");
        meter.balance += msg.value;
    }

    function requestUseRight(uint256 tokenId) external onlyOwner {
        require(
            mType == IUtilityHelper.MembershipType.LIFETIME,
            "Utility: not normal lifetime membership"
        );
        require(meters[tokenId].status, "Utility: not approved for token id");
        emit UseRightRequested(tokenId, msg.sender);
    }

    function approveUseRights(uint256 tokenId) external {
        require(
            mType == IUtilityHelper.MembershipType.LIFETIME,
            "Utility: not normal lifetime membership"
        );
        Meter storage meter = meters[tokenId];
        require(meter.status, "Utility: not approved for token id");
        if (meter.balance < rightPrice) {
            meter.status = false;
            return;
        }
        meter.balance -= rightPrice;
        emit UseRightApproved(tokenId, meter.account);
    }

    function check(uint256 tokenId) external {
        require(mType == IUtilityHelper.MembershipType.TIMELY, "Utility: not timely membership");
        Meter storage meter = meters[tokenId];
        uint256 debt = ((block.timestamp - meter.lastChecked) / expiration) * rightPrice;
        if (meter.balance < debt) meter.status = false;
        else meter.balance -= debt;
    }

    function useRight(uint256 tokenId) external onlyOwner {
        require(meters[tokenId].status, "Utility: not approved for token id");
        // TODO:
    }
}
