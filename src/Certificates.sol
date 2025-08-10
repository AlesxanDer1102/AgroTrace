// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ICertificates.sol";
import "./IActorsRegistry.sol";

/**
 * Certificates — Vincula certificados a lotes (separado de trazabilidad).
 * Principio de Responsabilidad Única: solo gestiona certificados/verificación.
 */
contract Certificates is ICertificates {
    IActorsRegistry public immutable registry;
    bytes32 private constant ROLE_INSPECTOR = keccak256("INSPECTOR");
    bytes4  private constant EIP1271_MAGICVALUE = 0x1626ba7e;

    mapping(uint256 => bytes32[]) private _lotCertKeys; // lotId -> keys
    mapping(bytes32  => Certificate) private _certByKey; // key = keccak256(lotId, docHash)

    constructor(address actorsRegistry) {
        registry = IActorsRegistry(actorsRegistry);
    }

    function linkByRole(
        uint256 lotId,
        bytes32 certType,
        bytes32 docHash,
        address issuer,
        uint64 issuedAt,
        uint64 expiresAt
    ) external {
        require(registry.hasRole(msg.sender, ROLE_INSPECTOR), "Certs: not inspector");
        _link(lotId, certType, docHash, issuer, issuedAt, expiresAt, "");
    }

    function linkSigned(
        uint256 lotId,
        bytes32 certType,
        bytes32 docHash,
        address issuer,
        uint64 issuedAt,
        uint64 expiresAt,
        bytes calldata sig,
        bytes32 msgHash
    ) external {
        require(_isValidIssuerSig(issuer, msgHash, sig), "Certs: bad issuer sig");
        _link(lotId, certType, docHash, issuer, issuedAt, expiresAt, sig);
    }

    function revoke(uint256 lotId, bytes32 certKey, string calldata reason) external {
        require(registry.hasRole(msg.sender, ROLE_INSPECTOR), "Certs: not inspector");
        Certificate storage c = _certByKey[certKey];
        require(c.docHash != bytes32(0), "Certs: unknown");
        c.revoked = true;
        emit CertificateRevoked(lotId, certKey, reason);
    }

    function isValid(bytes32 key, uint64 nowTs) external view returns (bool ok, string memory why) {
        Certificate memory c = _certByKey[key];
        if (c.docHash == bytes32(0)) return (false, "not found");
        if (c.revoked)               return (false, "revoked");
        if (c.expiresAt != 0 && nowTs > c.expiresAt) return (false, "expired");
        return (true, "");
    }

    function getLotCertKeys(uint256 lotId) external view returns (bytes32[] memory) {
        return _lotCertKeys[lotId];
    }

    function getByKey(bytes32 key) external view returns (Certificate memory) {
        return _certByKey[key];
    }

    // ----- internos -----
    function _link(
        uint256 lotId,
        bytes32 certType,
        bytes32 docHash,
        address issuer,
        uint64 issuedAt,
        uint64 expiresAt,
        bytes memory sig
    ) internal {
        bytes32 key = keccak256(abi.encode(lotId, docHash));
        require(_certByKey[key].docHash == bytes32(0), "Certs: already linked");
        _certByKey[key] = Certificate(certType, docHash, issuer, issuedAt, expiresAt, false, sig);
        _lotCertKeys[lotId].push(key);
        emit CertificateLinked(lotId, key, certType, issuer);
    }

    function _isValidIssuerSig(address issuer, bytes32 msgHash, bytes memory sig) internal view returns (bool) {
        if (sig.length == 0) return false;
        if (issuer.code.length == 0) {
            (bytes32 r, bytes32 s, uint8 v) = _split(sig);
            address rec = ecrecover(msgHash, v, r, s);
            return rec == issuer;
        } else {
            (bool ok, bytes memory ret) =
                issuer.staticcall(abi.encodeWithSignature("isValidSignature(bytes32,bytes)", msgHash, sig));
            return ok && ret.length == 4 && bytes4(ret) == EIP1271_MAGICVALUE;
        }
    }

    function _split(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Certs: bad sig len");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
