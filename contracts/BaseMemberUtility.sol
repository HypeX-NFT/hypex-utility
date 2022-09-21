// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract BaseMemberUtility {
    address public owner;
    address public nft;
    uint256 public expiration;

    struct Meter {
        address account;
        uint256 right;
        uint256 lastUpdated;
        bool isValid;
        uint8 useStatus;
    }

    uint256 public memberPrice;
    uint256 public rightPrice;

    event MembershipRequested(uint256 id, address account);
    event MembershipApproved(uint256 id, address account);
    event MembershipForfeitted(uint256 id, address account);
    event MembershipRequestDiscarded(uint256 id, address account);
    event MembershipAssignedTo(uint256 id, address to);
    event UseRightRequested(uint256 id, address account);
    event UseRightApproved(uint256 id, address account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Utility: the caller is not the owner");
        _;
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

    function setExpiration(uint256 duartion) external onlyOwner {
        expiration = duartion;
    }
}
