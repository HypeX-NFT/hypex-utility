// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IUtilityHelper.sol";

abstract contract BaseUtility {
    address public owner;
    address public nft;
    IUtilityHelper.MembershipType mType;
    uint256 public expiration;

    struct Meter {
        address account;
        uint256 balance;
        uint256 lastChecked;
        bool status;
    }

    uint256 public memberPrice;
    uint256 public rightPrice;

    event MembershipRequested(uint256 id, address account);
    event MembershipApproved(uint256 id, address account);
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

    function assignTo(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Utility: new owner address is 0x0");
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
}
