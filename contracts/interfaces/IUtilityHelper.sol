// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUtilityHelper {
    enum MembershipType {
        LIFETIME,
        PRIVILEGE_LIFETIME,
        COUNT_BASED,
        TIMELY
    }

    function getType(address nft) external view returns (uint8);
}
