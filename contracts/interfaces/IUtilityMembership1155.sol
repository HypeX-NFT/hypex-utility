// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUtilityMembership1155 {
    function isValidMember(address owner, uint256 id) external view returns (bool);

    function requestMembership(uint256 id) external payable;

    function approveRequest(address owner, uint256 id) external;
}
