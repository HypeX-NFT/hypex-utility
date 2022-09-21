// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract BaseMemberUtility {
    address public admin;
    address public nft;
    uint256 public expiration;

    struct Meter {
        // owner of the meter
        address owner;
        // right amount of the meter, number of rights or number of duration
        uint256 right;
        // last updated time of membership
        // in case right is valuable, based last charge time.
        uint256 lastUpdated;
        // status of membership approval
        bool isValid;
        // use status from the admin
        // 0 - not requested / used, 1 - requested by admin, 2 - approved by  owner
        uint8 useStatus;
    }

    /// @notice price to request membership
    uint256 public memberPrice;
    /// @notice price to make payment for right
    uint256 public rightPrice;

    event MembershipRequested(uint256 id, address owner);
    event MembershipRequestDiscarded(uint256 id, address owner);
    event MembershipRequestApproved(uint256 id, address owner);
    event MembershipForfeitted(uint256 id, address owner);
    event MembershipAssignedTo(uint256 id, address to);
    event UseRightRequested(uint256 id, address owner);
    event UseRightApproved(uint256 id, address owner);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Utility: the caller is not the admin");
        _;
    }

    /// @notice withdraw deposited funds to admin's wallet
    function withdraw() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    /// @notice set price to request membership
    function setMembershipPrice(uint256 price) external onlyAdmin {
        memberPrice = price;
    }

    /// @notice set price to make payment for right
    function setRightPrice(uint256 price) external onlyAdmin {
        rightPrice = price;
    }

    /// @notice set expiration duration
    /// @dev only valuable for timely membership
    function setExpiration(uint256 duartion) external onlyAdmin {
        expiration = duartion;
    }
}
