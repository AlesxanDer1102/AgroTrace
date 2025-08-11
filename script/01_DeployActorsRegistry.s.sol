// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ActorsRegistry.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract DeployActorsRegistryScript is Script {
    ActorsRegistry public actorsRegistry;
    address public admin;

    function setUp() public {
        admin = vm.envAddress("ADMIN_ADDRESS");
    }

    function run() public {
        vm.startBroadcast();

        console.log("=== Deploying ActorsRegistry ===");
        console.log("Admin address:", admin);
        console.log("Deployer:", admin);

        // Deploy ActorsRegistry
        actorsRegistry = new ActorsRegistry(admin);
        console.log("ActorsRegistry deployed at:", address(actorsRegistry));

        // Verify interface
        console.log("ActorsRegistry supports IAccessControl:", 
            actorsRegistry.supportsInterface(type(IAccessControl).interfaceId));

        vm.stopBroadcast();

        console.log("\n=== ActorsRegistry Deployment Complete ===");
        console.log("Save this address: ACTORS_REGISTRY_ADDRESS=", address(actorsRegistry));
    }
}