// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUtilityMembership1155 {
    function isValidMember(address account, uint256 tokenId) external view returns (bool);

    function requestMembership(uint256 tokenId) external payable;

    function approveRequest(address account, uint256 tokenId) external;
}
