// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract UtilityMembership is Ownable {
    uint256 public price;
    mapping(address => uint256[]) public memberships;
    mapping(address => bool) public pending;

    event MembershipRequested(address user);
    event MembershipAssigned(address user, uint256[] attributeIndexes);
    event MembershipRevoked(address user);
    event MembershipApproved(address user);

    constructor(uint256 price_) {
        price = price_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function requestMembership(uint256[] calldata attributeIndexes_) external payable {
        require(!pending[msg.sender], "Membership: pending request exists");
        require(memberships[msg.sender].length == 0, "Membership: already approved");
        require(attributeIndexes_.length > 0, "Membership: invalid arguments");
        require(msg.value >= price, "Membership: insufficient to request");
        memberships[msg.sender] = attributeIndexes_;
        pending[msg.sender] = true;
        if (msg.value > price) payable(msg.sender).transfer(msg.value - price);
        emit MembershipRequested(msg.sender);
    }

    function approveRequest(address user_) external onlyOwner {
        delete pending[user_];
        emit MembershipApproved(user_);
    }

    function forfeitMembership() external payable {
        require(
            !pending[msg.sender] && memberships[msg.sender].length > 0,
            "Membership: nothing to forfeit"
        );
        delete memberships[msg.sender];
        delete pending[msg.sender];
        require(msg.value >= price, "Membership: insufficient to request");
        if (msg.value > price) payable(msg.sender).transfer(msg.value - price);
    }

    function discardRequest(address user_) external onlyOwner {
        delete pending[user_];
        delete memberships[user_];
    }

    function assignTo(address to_, uint256[] calldata attributeIndexes_) external {
        emit MembershipAssigned(to_, attributeIndexes_);
    }

    function revokeFrom(address from_) external onlyOwner {
        delete memberships[from_];
        emit MembershipRevoked(from_);
    }

    function isCurrentMember(address to_) external view returns (bool) {
        return memberships[to_].length > 0 && !pending[to_];
    }
}
