// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BaseMemberUtility.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter721.sol";
import "./interfaces/IUtilityMembership721.sol";

contract CountMembership721 is BaseMemberUtility, IUtilityMeter721, IUtilityMembership721 {
    mapping(uint256 => Meter) public meters;

    constructor(address owner_, address nft_) {
        owner = owner_;
        nft = nft_;
    }

    function isValidMember(uint256 tokenId) external view returns (bool) {
        return meters[tokenId].isValid;
    }

    function requestMembership(uint256 tokenId) external payable {
        Meter memory meter = meters[tokenId];
        require(
            IERC721(nft).ownerOf(tokenId) == msg.sender,
            "Utility: caller is not the owner of this nft"
        );
        require(!meter.isValid, "Utility: already valid membership");
        require(meter.account == address(0), "Utility: already requested membership");
        require(msg.value >= memberPrice, "Utility: insufficient to request membership");
        if (msg.value > memberPrice) payable(msg.sender).transfer(msg.value - memberPrice);
        meters[tokenId] = Meter(msg.sender, 0, 0, false, 0);
        emit MembershipRequested(tokenId, msg.sender);
    }

    function discardRequest(uint256 tokenId) external {
        require(
            meters[tokenId].account == msg.sender && !meters[tokenId].isValid,
            "Utility: no request exists for token id"
        );
        delete meters[tokenId];
        emit MembershipRequestDiscarded(tokenId, msg.sender);
    }

    function approveRequest(uint256 tokenId) external onlyOwner {
        Meter storage meter = meters[tokenId];
        require(
            meter.account != address(0) && !meter.isValid,
            "Utility: no request exists for token id"
        );
        meter.lastUpdated = block.timestamp;
        meter.isValid = true;
        emit MembershipApproved(tokenId, meter.account);
    }

    function forfeitMembership(uint256 tokenId) external onlyOwner {
        Meter storage meter = meters[tokenId];
        require(meter.isValid, "Utility: no valid membership for token id");
        meter.isValid = false;
        meter.account = address(0);
        if (meter.right > 0) payable(meter.account).transfer(meter.right * rightPrice);
        emit MembershipForfeitted(tokenId, meter.account);
    }

    function assignTo(uint256 tokenId, address to) external {
        Meter storage meter = meters[tokenId];
        require(
            meter.account == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        meter.account = to;
        emit MembershipAssignedTo(tokenId, to);
    }

    function makePayment(uint256 tokenId) external payable {
        Meter storage meter = meters[tokenId];
        require(rightPrice > 0, "Utility: right price not set yet");
        require(
            meter.account == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        uint256 right = msg.value / rightPrice;
        if (right == 0) {
            payable(msg.sender).transfer(msg.value);
            return;
        }
        meter.right += right;
        if (msg.value > rightPrice * right)
            payable(msg.sender).transfer(msg.value - rightPrice * right);
    }

    function requestUseRight(uint256 tokenId) external onlyOwner {
        Meter storage meter = meters[tokenId];
        require(meter.useStatus == 0, "Utility: already requested use");
        require(meter.isValid, "Utility: invalid membership");
        meter.useStatus = 1;
        emit UseRightRequested(tokenId, msg.sender);
    }

    function approveUseRights(uint256 tokenId) external {
        Meter storage meter = meters[tokenId];
        require(meter.useStatus == 1, "Utility: use not requested");
        require(
            meter.account == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        require(meter.right > 0, "Utility: no right to approve");
        meter.right--;
        meter.useStatus = 2;
        emit UseRightApproved(tokenId, meter.account);
    }

    function useRight(uint256 tokenId) external onlyOwner {
        Meter storage meter = meters[tokenId];
        require(meter.useStatus == 2, "Utility: use request not approved for token id");
        require(meter.isValid, "Utility: invalid membership");
        meter.useStatus = 0;
    }
}
