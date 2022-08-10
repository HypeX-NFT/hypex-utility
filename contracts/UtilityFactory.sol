// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Utility.sol";

interface INFT {
    function owner() external view returns (address);
}

contract UtilityFactory is UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => address) public utilities;

    event UtilityCreated(address indexed nft, address indexed utility, bool indexed is721);

    modifier onlyNFTIssuer(address nft) {
        (bool success, bytes memory data) = nft.call(abi.encodeWithSignature("owner()"));
        if (success) {
            address addr = abi.decode(data, (address));
            require(addr == msg.sender, "Factory: not nft issuer");
        }
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function bind(address nft, bool is721) external onlyNFTIssuer(nft) returns (address) {
        require(utilities[nft] == address(0), "Factory: utilitiy already exists");
        Utility utility = new Utility(msg.sender, nft, is721);
        utilities[nft] = address(utility);
        emit UtilityCreated(nft, address(utility), is721);
        return address(utility);
    }

    function getUtility(address nft) external view returns (address) {
        return utilities[nft];
    }
}
