// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICertificates {
    struct Certificate {
        bytes32 certType;
        bytes32 docHash;
        address issuer;
        uint64 issuedAt;
        uint64 expiresAt;
        bool revoked;
        bytes sig;
    }

    event CertificateLinked(uint256 indexed lotId, bytes32 indexed certKey, bytes32 certType, address issuer);
    event CertificateRevoked(uint256 indexed lotId, bytes32 indexed certKey, string reason);

    function linkByRole(
        uint256 lotId,
        bytes32 certType,
        bytes32 docHash,
        address issuer,
        uint64 issuedAt,
        uint64 expiresAt
    ) external;

    function linkSigned(
        uint256 lotId,
        bytes32 certType,
        bytes32 docHash,
        address issuer,
        uint64 issuedAt,
        uint64 expiresAt,
        bytes calldata sig,
        bytes32 msgHash
    ) external;

    function revoke(uint256 lotId, bytes32 certKey, string calldata reason) external;

    function isValid(bytes32 certKey, uint64 nowTs) external view returns (bool ok, string memory why);

    function getLotCertKeys(uint256 lotId) external view returns (bytes32[] memory);
    function getByKey(bytes32 key) external view returns (Certificate memory);
}
