// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUtilityFactory {
    function getUtility(address nft) external view returns (address);
}
