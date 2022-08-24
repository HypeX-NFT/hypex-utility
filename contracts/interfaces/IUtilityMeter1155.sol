// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUtilityMeter1155 {
    function increaseBalance(uint256 id) external payable;

    function requestUseRight(address account, uint256 id) external;

    function approveUseRights(uint256 id) external;

    function useRight(address account, uint256 id) external;
}
