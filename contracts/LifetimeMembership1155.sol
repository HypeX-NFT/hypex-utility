// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./BaseMemberUtility.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter1155.sol";
import "./interfaces/IUtilityMembership1155.sol";

contract LifetimeMembership1155 is BaseMemberUtility, IUtilityMeter1155, IUtilityMembership1155 {
    mapping(address => mapping(uint256 => Meter)) public meters;

    constructor(address owner_, address nft_) {
        owner = owner_;
        nft = nft_;
    }

    function isValidMember(address account, uint256 id) external view returns (bool) {
        return meters[account][id].isValid;
    }

    function requestMembership(uint256 id) external payable {
        Meter memory meter = meters[msg.sender][id];
        require(
            IERC1155(nft).balanceOf(msg.sender, id) > 0,
            "Utility: caller is not the owner of this nft"
        );
        require(!meter.isValid, "Utility: already valid membership");
        require(meter.account == address(0), "Utility: already requested membership");
        require(msg.value >= memberPrice, "Utility: insufficient to request membership");
        if (msg.value > memberPrice) payable(msg.sender).transfer(msg.value - memberPrice);
        meters[msg.sender][id] = Meter(msg.sender, 0, 0, false, 0);
        emit MembershipRequested(id, msg.sender);
    }

    function discardRequest(uint256 id) external {
        require(
            meters[msg.sender][id].account == msg.sender && !meters[msg.sender][id].isValid,
            "Utility: no request exists for token id"
        );
        delete meters[msg.sender][id];
        emit MembershipRequestDiscarded(id, msg.sender);
    }

    function approveRequest(address account, uint256 id) external onlyOwner {
        Meter storage meter = meters[account][id];
        require(
            meter.account != address(0) && !meter.isValid,
            "Utility: no request exists for token id"
        );
        meter.lastUpdated = block.timestamp;
        meter.isValid = true;
        emit MembershipApproved(id, meter.account);
    }

    function forfeitMembership(address account, uint256 id) external onlyOwner {
        Meter storage meter = meters[account][id];
        require(meter.isValid, "Utility: no valid membership for token id");
        meter.isValid = false;
        meter.account = address(0);
        if (meter.right > 0) payable(meter.account).transfer(meter.right * rightPrice);
        emit MembershipForfeitted(id, meter.account);
    }

    function assignTo(uint256 id, address to) external {
        Meter storage meter = meters[msg.sender][id];
        require(
            meter.account == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        meter.account = to;
        meters[to][id] = meter;
        delete meters[msg.sender][id];
        emit MembershipAssignedTo(id, to);
    }

    function makePayment(uint256 id) external payable {
        Meter storage meter = meters[msg.sender][id];
        require(rightPrice > 0, "Utility: right price not set yet");
        require(
            meter.account == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        if (msg.value < rightPrice) {
            payable(msg.sender).transfer(msg.value);
            return;
        }
        if (meter.right > 0) return;
        meter.right++;
        if (msg.value > rightPrice) payable(msg.sender).transfer(msg.value - rightPrice);
    }

    function requestUseRight(address account, uint256 id) external onlyOwner {
        revert("not supported in this type of membership");
    }

    function approveUseRights(uint256 id) external {
        revert("not supported in this type of membership");
    }

    function useRight(address account, uint256 id) external onlyOwner {
        Meter storage meter = meters[msg.sender][id];
        require(meter.isValid, "Utility: invalid membership");
        require(meter.right > 0, "Utility: no right to use");
        meter.right--;
    }
}
