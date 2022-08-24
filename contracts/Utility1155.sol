// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./BaseUtility.sol";
import "./interfaces/IUtilityHelper.sol";
import "./interfaces/IUtilityMeter1155.sol";
import "./interfaces/IUtilityMembership1155.sol";

contract Utility1155 is BaseUtility, IUtilityMeter1155, IUtilityMembership1155 {
    mapping(address => mapping(uint256 => Meter)) public meters;

    constructor(
        address owner_,
        address nft_,
        IUtilityHelper.MembershipType mType_
    ) {
        owner = owner_;
        nft = nft_;
        mType = mType_;
    }

    function isValidMember(address account, uint256 id) external view returns (bool) {
        return meters[account][id].status;
    }

    function requestMembership(uint256 id) external payable {
        Meter storage meter = meters[msg.sender][id];
        require(
            IERC1155(nft).balanceOf(msg.sender, id) > 0,
            "Utility: caller is not the owner of this nft"
        );
        require(!meter.status, "Utility: membership already approved");
        require(meter.account == address(0), "Utility: pending request already exists");
        require(msg.value >= memberPrice, "Utility: insufficient to request membership");
        if (msg.value > memberPrice) payable(msg.sender).transfer(msg.value - memberPrice);
        meters[msg.sender][id] = Meter(msg.sender, 0, 0, false);
        emit MembershipRequested(id, msg.sender);
    }

    function approveRequest(address account, uint256 id) external onlyOwner {
        Meter storage meter = meters[account][id];
        require(
            meter.account != address(0) && !meter.status,
            "Utility: no pending request for token id"
        );
        meter.lastChecked = block.timestamp;
        meter.status = true;
        emit MembershipApproved(id, meter.account);
    }

    function increaseBalance(uint256 id) external payable {
        require(
            mType == IUtilityHelper.MembershipType.LIFETIME,
            "Utility: not normal lifetime membership"
        );
        Meter storage meter = meters[msg.sender][id];
        require(meter.status, "Utility: not approved for token id");
        meter.balance += msg.value;
    }

    function requestUseRight(address account, uint256 id) external onlyOwner {
        require(
            mType == IUtilityHelper.MembershipType.LIFETIME,
            "Utility: not normal lifetime membership"
        );
        require(meters[account][id].status, "Utility: not approved for token id");
        emit UseRightRequested(id, msg.sender);
    }

    function approveUseRights(uint256 id) external {
        require(
            mType == IUtilityHelper.MembershipType.LIFETIME,
            "Utility: not normal lifetime membership"
        );
        Meter storage meter = meters[msg.sender][id];
        require(meter.status, "Utility: not approved for token id");
        if (meter.balance < rightPrice) {
            meter.status = false;
            return;
        }
        meter.balance -= rightPrice;
        emit UseRightApproved(id, meter.account);
    }

    function check(address account, uint256 id) external {
        Meter storage meter = meters[account][id];
        uint256 debt = ((block.timestamp - meter.lastChecked) / expiration) * rightPrice;
        if (meter.balance < debt) meter.status = false;
        else meter.balance -= debt;
    }

    function useRight(address account, uint256 id) external onlyOwner {
        require(meters[account][id].status, "Utility: not approved for token id");
        // TODO:
    }
}
