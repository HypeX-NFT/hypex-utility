// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUtilityMeter721 {
    function makePayment(uint256 tokenId) external payable;

    function requestUseRight(uint256 tokenId) external;

    function approveUseRights(uint256 tokenId) external;

    function useRight(uint256 tokenId) external;
}
