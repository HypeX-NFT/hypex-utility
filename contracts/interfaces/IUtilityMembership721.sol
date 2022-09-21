// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUtilityMembership721 {
    function isValidMember(uint256 tokenId) external view returns (bool);

    function requestMembership(uint256 tokenId) external payable;

    function approveRequest(uint256 tokenId) external;
}
