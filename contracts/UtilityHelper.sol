// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract UtilityHelper {
    using Address for address;

    function getType(address nft) external view returns (uint8) {
        if (!nft.isContract()) return 0;

        try IERC165(nft).supportsInterface(type(IERC721).interfaceId) returns (bool is721) {
            if (is721) return 1;
            try IERC165(nft).supportsInterface(type(IERC1155).interfaceId) returns (bool is1155) {
                return is1155 ? 2 : 0;
            } catch {
                return 0;
            }
        } catch {
            return 0;
        }
    }
}
