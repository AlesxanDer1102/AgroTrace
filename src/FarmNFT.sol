// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * FarmNFT — Identidad de fincas (ERC-721)
 * v5-ready. No hooks especiales; solo override de supportsInterface.
 */
contract FarmNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant FARM_ADMIN_ROLE = keccak256("FARM_ADMIN");
    bytes32 public constant FARM_MINTER_ROLE = keccak256("FARM_MINTER");

    struct FarmData {
        string name; // Nombre de la finca
        string region; // Región/Departamento
        string countryISO; // "PE","CO","MX", etc.
        bytes12 geohash; // ubicación aproximada
        string cropFocus; // palta/café/arándano/uva/cacao...
        string photoURI; // imagen destacada (IPFS/URL)
        string metaURI; // JSON con más detalles
    }

    mapping(uint256 => FarmData) public farm; // tokenId -> datos

    event FarmRegistered(uint256 indexed farmNftId, address owner);
    event FarmUpdated(uint256 indexed farmNftId);

    constructor(address admin) ERC721("FarmNFT", "FARM") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FARM_ADMIN_ROLE, admin);
        _grantRole(FARM_MINTER_ROLE, admin);
    }

    function registerFarm(uint256 tokenId, address owner, FarmData calldata data, string calldata tokenURI_)
        external
        onlyRole(FARM_MINTER_ROLE)
    {
        require(!exists(tokenId), "Farm: exists");
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        farm[tokenId] = data;
        emit FarmRegistered(tokenId, owner);
    }

    function updateFarm(uint256 tokenId, FarmData calldata data, string calldata newTokenURI) external {
        require(exists(tokenId), "Farm: unknown");
        require(hasRole(FARM_ADMIN_ROLE, msg.sender) || ownerOf(tokenId) == msg.sender, "Farm: not authorized");
        farm[tokenId] = data;
        if (bytes(newTokenURI).length > 0) {
            _setTokenURI(tokenId, newTokenURI);
        }
        emit FarmUpdated(tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        // ERC721 v5 mantiene _ownerOf como interno
        return _ownerOf(tokenId) != address(0);
    }

    function supportsInterface(bytes4 iid) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(iid);
    }
}
