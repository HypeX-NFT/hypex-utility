// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IUtilityHelper.sol";
import "./Utility721.sol";
import "./Utility1155.sol";

contract UtilityFactory is UUPSUpgradeable, OwnableUpgradeable {
    address public helper;
    mapping(address => address) public utilities;

    event UtilityCreated(
        address indexed nft,
        address indexed utility,
        IUtilityHelper.MembershipType indexed mType,
        bool is721
    );

    modifier onlyNFTIssuer(address nft) {
        (bool success, bytes memory data) = nft.call(abi.encodeWithSignature("owner()"));
        if (success) {
            address addr = abi.decode(data, (address));
            require(addr == msg.sender, "Factory: not nft issuer");
        }
        _;
    }

    function initialize(address helper_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(helper_ != address(0), "Factory: helper address is 0x0");
        helper = helper_;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function bind(address nft, IUtilityHelper.MembershipType mType)
        external
        onlyNFTIssuer(nft)
        returns (address)
    {
        require(utilities[nft] == address(0), "Factory: utilitiy already exists");
        uint8 nType = IUtilityHelper(helper).getType(nft);
        require(nType > 0, "Factory: given address is not erc721 or erc1155 standard");
        address utility;
        if (nType == 1) utility = address(new Utility721(msg.sender, nft, mType));
        else utility = address(new Utility1155(msg.sender, nft, mType));
        utilities[nft] = utility;
        emit UtilityCreated(nft, utility, mType, nType == 1);
        return utility;
    }

    function getUtility(address nft) external view returns (address) {
        return utilities[nft];
    }
}
