// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUtility {
    function getUtility(address nft) external view returns (address);
}
