// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IActorsRegistry {
    function hasRole(address who, bytes32 role) external view returns (bool);
    function isActive(address who) external view returns (bool);

    function ROLE_PRODUCER() external pure returns (bytes32);
    function ROLE_PROCESSOR() external pure returns (bytes32);
    function ROLE_TRANSPORTER() external pure returns (bytes32);
    function ROLE_INSPECTOR() external pure returns (bytes32);
    function ROLE_RETAILER() external pure returns (bytes32);
}
