// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUtilityMeter1155 {
    function makePayment(uint256 id) external payable;

    function requestUseRight(address owner, uint256 id) external;

    function approveUseRights(uint256 id) external;

    function useRight(address owner, uint256 id) external;
}
