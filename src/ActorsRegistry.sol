// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * ActorsRegistry — Registro de organizaciones y roles
 * SRP: solo identidad/roles. v5-ready.
 */
contract ActorsRegistry is AccessControl {
    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN");

    // Roles interoperables
    function ROLE_PRODUCER() external pure returns (bytes32) {
        return keccak256("PRODUCER");
    }

    function ROLE_PROCESSOR() external pure returns (bytes32) {
        return keccak256("PROCESSOR");
    }

    function ROLE_TRANSPORTER() external pure returns (bytes32) {
        return keccak256("TRANSPORTER");
    }

    function ROLE_INSPECTOR() external pure returns (bytes32) {
        return keccak256("INSPECTOR");
    }

    function ROLE_RETAILER() external pure returns (bytes32) {
        return keccak256("RETAILER");
    }

    struct Actor {
        string orgName;
        string did;
        string metaURI;
        bool active;
        mapping(bytes32 => bool) hasRole;
    }

    mapping(address => Actor) private actors;

    event ActorAdded(address indexed who, string orgName);
    event ActorUpdated(address indexed who);
    event RoleGrantedExt(address indexed who, bytes32 indexed role);
    event RoleRevokedExt(address indexed who, bytes32 indexed role);
    event ActorActivation(address indexed who, bool active);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRY_ADMIN_ROLE, admin);
    }

    function addActor(address who, string calldata orgName, string calldata did, string calldata metaURI, bool active)
        external
        onlyRole(REGISTRY_ADMIN_ROLE)
    {
        Actor storage a = actors[who];
        a.orgName = orgName;
        a.did = did;
        a.metaURI = metaURI;
        a.active = active;
        emit ActorAdded(who, orgName);
        emit ActorActivation(who, active);
    }

    function updateActor(
        address who,
        string calldata orgName,
        string calldata did,
        string calldata metaURI,
        bool active
    ) external onlyRole(REGISTRY_ADMIN_ROLE) {
        require(bytes(actors[who].orgName).length > 0, "Actors: not found");
        Actor storage a = actors[who];
        a.orgName = orgName;
        a.did = did;
        a.metaURI = metaURI;
        a.active = active;
        emit ActorUpdated(who);
        emit ActorActivation(who, active);
    }

    function grantRoleFor(address who, bytes32 role_) external onlyRole(REGISTRY_ADMIN_ROLE) {
        actors[who].hasRole[role_] = true;
        emit RoleGrantedExt(who, role_);
    }

    function revokeRoleFor(address who, bytes32 role_) external onlyRole(REGISTRY_ADMIN_ROLE) {
        actors[who].hasRole[role_] = false;
        emit RoleRevokedExt(who, role_);
    }

    function hasRole(address who, bytes32 role_) external view returns (bool) {
        return actors[who].hasRole[role_];
    }

    function isActive(address who) external view returns (bool) {
        return actors[who].active;
    }

    function getActor(address who) external view returns (string memory, string memory, string memory, bool) {
        Actor storage a = actors[who];
        return (a.orgName, a.did, a.metaURI, a.active);
    }
}
