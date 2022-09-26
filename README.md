# Introduction

NFT has been well recognized as digital ownership technology. On top of the ownership representation, people are exploring various utilities around NFTs, such as using NFT as event tickets, building membership by NFT ownerships, among many others. There are different ways to implement a utility of NFTs, but so far most of the implementations are proprietary with little support for expansion. Many of them are implemented through customized ERC-721 or ERC-1155 smart contracts so that standard NFTs based on those standards will not be able to leverage.

This repo helps you to present a generic mechanism to implement NFT utilities through a standard UtilityMeter interface and a NFT Utility Gateway smart contract. It is backward compatible with ERC-721 and ERC-1155 standards so that every existing NFTs will also be augmented with utilities through this mechanism. The standard UtilityMeter interface are open to developers so that anyone can develop their own utility mechanism and provide to others

## _This codebase supports 4 different kinds of membership types_

- Lifetime
- Lifetime with Privilege
- Count-based
- Monthly/Annually

```
interface UtilityFactory {
    function bindNFTUtility(address nft, IUtilityHelper.MembershipType mType) external returns (address);
    function getUtility(address nft) external view returns (address);
```

```
interface BaseMemberUtility {
    function withdraw() external;
    function setMembershipPrice(uint256 price) external;
    function setRightPrice(uint256 price) external;
    function setExpiration(uint256 duration) external;
}
```

```
interface MembershipUtility {
    function isValidMember(uint256 tokenId) external view returns (bool);
    function requestMembership(uint256 tokenId) external payable;
    function discardRequest(uint256 tokenId) external;
    function approveRequest(uint256 tokenId) external;
    function forfeitMembership(uint256 tokenId) external;
    function assignTo(uint256 tokenId, address to) external;
    function makePayment(uint256 tokenId) external payable;
    function requestUseRight(uint256 tokenId) external;
    function approveUseRights(uint256 tokenId) external;
    function useRight(uint256 tokenId) external;
}
```
