// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Certificates.sol";

contract DeployCertificatesScript is Script {
    Certificates public certificates;
    address public actorsRegistry;

    function setUp() public {
        actorsRegistry = vm.envAddress("ACTORS_REGISTRY_ADDRESS");
    }

    function run() public {
        vm.startBroadcast();

        console.log("=== Deploying Certificates ===");
        console.log("ActorsRegistry address:", actorsRegistry);

        // Deploy Certificates
        certificates = new Certificates(actorsRegistry);
        console.log("Certificates deployed at:", address(certificates));

        vm.stopBroadcast();

        console.log("\n=== Certificates Deployment Complete ===");
        console.log("Save this address: CERTIFICATES_ADDRESS=", address(certificates));
    }
}