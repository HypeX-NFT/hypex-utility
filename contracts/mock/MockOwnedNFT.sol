// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockOwnedNFT is ERC721("Mock", "MOCK"), Ownable {}
