// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./BaseMemberUtility.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter1155.sol";
import "./interfaces/IUtilityMembership1155.sol";

contract CountMembership1155 is BaseMemberUtility, IUtilityMeter1155, IUtilityMembership1155 {
    mapping(address => mapping(uint256 => Meter)) public meters;

    constructor(address admin_, address nft_) {
        admin = admin_;
        nft = nft_;
    }

    function isValidMember(address owner, uint256 id) external view returns (bool) {
        return meters[owner][id].isValid;
    }

    /**
     * @notice request memberhsip for {id}
     * @dev only nft owner can call this function
     * @param id nft token id
     * emits {MembershipRequested} event
     */
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

    /**
     * @notice discard memberhsip request for {id}
     * @dev only membership owner can call this function
     * @param id nft token id
     * emits {MembershipRequestDiscarded} event
     */
    function discardRequest(uint256 id) external {
        require(
            meters[msg.sender][id].owner == msg.sender && !meters[msg.sender][id].isValid,
            "Utility: no request exists for token id"
        );
        delete meters[msg.sender][id];
        emit MembershipRequestDiscarded(id, msg.sender);
    }

    /**
     * @notice approve memberhsip request from owner of {id}
     * @dev only utility admin can call this function
     * @param owner address of membership owner
     * @param id nft token id
     * emits {MembershipRequestApproved} event
     */
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

    /**
     * @notice forfeit active memberhsip from owner of {id}
     * @dev only utility admin can call this function
     * @param owner address of membership owner
     * @param id nft token id
     * emits {MembershipForfeitted} event
     */
    function forfeitMembership(address owner, uint256 id) external onlyAdmin {
        Meter storage meter = meters[owner][id];
        require(meter.isValid, "Utility: no valid membership for token id");
        meter.isValid = false;
        meter.owner = address(0);
        if (meter.right > 0) payable(meter.owner).transfer(meter.right * rightPrice);
        emit MembershipForfeitted(id, meter.owner);
    }

    /**
     * @notice hand over memberhsip to other user for {id}
     * @dev only membership owner can call this function
     * @param id nft token id
     * @param to target user to hand over membership
     * emits {MembershipAssignedTo} event
     */
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

    /**
     * @notice charge payment for the rights of {id}
     * @dev only membership owner can call this function
     * @param id nft token id
     */
    function makePayment(uint256 id) external payable {
        Meter storage meter = meters[msg.sender][id];
        require(rightPrice > 0, "Utility: right price not set yet");
        require(
            meter.owner == msg.sender && meter.isValid,
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

    /**
     * @notice request use right to membership owner of {id}
     * @dev only utility admin can call this function
     * @param owner address of membership owner
     * @param id nft token id
     * emits {UseRightRequested} event
     */
    function requestUseRight(address owner, uint256 id) external onlyAdmin {
        Meter storage meter = meters[owner][id];
        require(meter.useStatus == 0, "Utility: already requested use");
        require(meter.isValid, "Utility: invalid membership");
        meter.useStatus = 1;
        emit UseRightRequested(id, msg.sender);
    }

    /**
     * @notice approve use right from owner for {id}
     * @dev only membership owner can call this function
     * @param id nft token id
     * emits {UseRightApproved} event
     */
    function approveUseRights(uint256 id) external {
        Meter storage meter = meters[msg.sender][id];
        require(meter.useStatus == 1, "Utility: use not requested");
        require(
            meter.owner == msg.sender && meter.isValid,
            "Utility: not owner or invalid membership"
        );
        require(meter.right > 0, "Utility: no right to approve");
        meter.right--;
        meter.useStatus = 2;
        emit UseRightApproved(id, meter.owner);
    }

    /**
     * @notice use right of {id}
     * @dev only utility admin can call this function
     * @param owner address of membership owner
     * @param id nft token id
     */
    function useRight(address owner, uint256 id) external onlyAdmin {
        Meter storage meter = meters[owner][id];
        require(meter.useStatus == 2, "Utility: use request not approved for token id");
        require(meter.isValid, "Utility: invalid membership");
        meter.useStatus = 0;
    }
}
