// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IUtilityHelper.sol";
import "./CountMembership721.sol";
import "./CountMembership1155.sol";
import "./LifetimeMembership721.sol";
import "./LifetimeMembership1155.sol";
import "./TimelyMembership721.sol";
import "./TimelyMembership1155.sol";

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

    /**
     * @notice bind {nft} contract with {mType} memberhsip type
     * @dev only {nft} contract owner can call this function
     * @param nft address of nft collection
     * @param mType membership type
     * - LIFE_TIME (with PRIVILEGE)
     * - COUNT_BASED
     * - TIMELY (Montly/Yearly)
     * @return address of generated utility contract
     */
    function bindMember(address nft, IUtilityHelper.MembershipType mType)
        external
        onlyNFTIssuer(nft)
        returns (address)
    {
        require(utilities[nft] == address(0), "Factory: utilitiy already exists");
        uint8 nType = IUtilityHelper(helper).getType(nft);
        require(nType > 0, "Factory: given address is not erc721 or erc1155 standard");
        address utility;
        if (nType == 1) {
            if (mType == IUtilityHelper.MembershipType.COUNT_BASED)
                utility = address(new CountMembership721(msg.sender, nft));
            else if (mType == IUtilityHelper.MembershipType.TIMELY)
                utility = address(new TimelyMembership721(msg.sender, nft));
            else utility = address(new LifetimeMembership721(msg.sender, nft));
        } else {
            if (mType == IUtilityHelper.MembershipType.COUNT_BASED)
                utility = address(new CountMembership1155(msg.sender, nft));
            else if (mType == IUtilityHelper.MembershipType.TIMELY)
                utility = address(new TimelyMembership1155(msg.sender, nft));
            else utility = address(new LifetimeMembership1155(msg.sender, nft));
        }
        utilities[nft] = utility;
        emit UtilityCreated(nft, utility, mType, nType == 1);
        return utility;
    }

    function getUtility(address nft) external view returns (address) {
        return utilities[nft];
    }
}
