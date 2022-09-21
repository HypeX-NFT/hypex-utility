// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./BaseMemberUtility.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter1155.sol";
import "./interfaces/IUtilityMembership1155.sol";

contract TimelyMembership1155 is BaseMemberUtility, IUtilityMeter1155, IUtilityMembership1155 {
    mapping(address => mapping(uint256 => Meter)) public meters;

    constructor(address admin_, address nft_) {
        admin = admin_;
        nft = nft_;
    }

    function isValidMember(address owner, uint256 id) external view returns (bool) {
        return
            meters[owner][id].isValid &&
            meters[owner][id].lastUpdated + meters[owner][id].right * expiration <= block.timestamp;
    }

    function requestMembership(uint256 id) external payable {
        Meter memory meter = meters[msg.sender][id];
        require(
            IERC1155(nft).balanceOf(msg.sender, id) > 0,
            "Utility: caller is not the owner of this nft"
        );
        require(!meter.isValid, "Utility: already valid membership");
        require(meter.owner == address(0), "Utility: already requested membership");
        require(msg.value >= memberPrice, "Utility: insufficient to request membership");
        if (msg.value > memberPrice) payable(msg.sender).transfer(msg.value - memberPrice);
        meters[msg.sender][id] = Meter(msg.sender, 0, 0, false, 0);
        emit MembershipRequested(id, msg.sender);
    }

    function discardRequest(uint256 id) external {
        require(
            meters[msg.sender][id].owner == msg.sender && !meters[msg.sender][id].isValid,
            "Utility: no request exists for token id"
        );
        delete meters[msg.sender][id];
        emit MembershipRequestDiscarded(id, msg.sender);
    }

    function approveRequest(address owner, uint256 id) external onlyAdmin {
        Meter storage meter = meters[owner][id];
        require(
            meter.owner != address(0) && !meter.isValid,
            "Utility: no request exists for token id"
        );
        meter.lastUpdated = block.timestamp;
        meter.isValid = true;
        emit MembershipRequestApproved(id, meter.owner);
    }

    function forfeitMembership(address owner, uint256 id) external onlyAdmin {
        Meter storage meter = meters[owner][id];
        require(meter.isValid, "Utility: no valid membership for token id");
        meter.isValid = false;
        meter.owner = address(0);
        if (meter.right > 0) payable(meter.owner).transfer(meter.right);
        emit MembershipForfeitted(id, meter.owner);
    }

    function assignTo(uint256 id, address to) external {
        Meter storage meter = meters[msg.sender][id];
        require(
            meter.owner == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        meter.owner = to;
        meters[to][id] = meter;
        delete meters[msg.sender][id];
        emit MembershipAssignedTo(id, to);
    }

    function makePayment(uint256 id) external payable {
        Meter storage meter = meters[msg.sender][id];
        require(rightPrice > 0, "Utility: right price not set yet");
        require(expiration > 0, "Utility: membership duration not set yet");
        require(
            meter.owner == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        uint256 right = msg.value / rightPrice;
        if (right == 0) {
            payable(msg.sender).transfer(msg.value);
            return;
        }
        if (meter.lastUpdated + meter.right * expiration <= block.timestamp) {
            meter.lastUpdated = block.timestamp;
            meter.right = right;
        } else {
            meter.right += right;
        }
        if (msg.value > rightPrice * right)
            payable(msg.sender).transfer(msg.value - rightPrice * right);
    }

    function requestUseRight(address, uint256) external {
        revert("not supported in this type of membership");
    }

    function approveUseRights(uint256) external {
        revert("not supported in this type of membership");
    }

    function useRight(address, uint256) external {
        revert("not supported in this type of membership");
    }
}
