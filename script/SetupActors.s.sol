// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ActorsRegistry.sol";
import "../src/FarmNFT.sol";

contract SetupActorsScript is Script {
    ActorsRegistry public actorsRegistry;
    FarmNFT public farmNFT;

    // Solo 3 direcciones mínimas para flujo completo
    address public producer;
    address public processor;
    address public inspector;

    function setUp() public {
        actorsRegistry = ActorsRegistry(vm.envAddress("ACTORS_REGISTRY_ADDRESS"));
        farmNFT = FarmNFT(vm.envAddress("FARM_NFT_ADDRESS"));

        // Cargar direcciones mínimas desde .env
        producer = vm.envAddress("PRODUCER_ADDRESS");
        processor = vm.envAddress("PROCESSOR_ADDRESS");
        inspector = vm.envAddress("INSPECTOR_ADDRESS");
    }

    function run() public {
        vm.startBroadcast();

        console.log("=== Setting up Minimal Actors ===");

        // 1. Setup Producer (maneja producción, transporte y retail)
        console.log("\n1. Setting up Producer (multi-role)...");
        actorsRegistry.addActor(
            producer, "Finca Los Andes", "did:agro:producer", "https://api.agrotrace.io/actors/producer", true
        );
        actorsRegistry.grantRoleFor(producer, actorsRegistry.ROLE_PRODUCER());
        actorsRegistry.grantRoleFor(producer, actorsRegistry.ROLE_TRANSPORTER());
        actorsRegistry.grantRoleFor(producer, actorsRegistry.ROLE_RETAILER());
        console.log("Producer setup (PRODUCER + TRANSPORTER + RETAILER):", producer);

        // 2. Setup Processor
        console.log("\n2. Setting up Processor...");
        actorsRegistry.addActor(
            processor, "Procesadora AgroMax", "did:agro:processor", "https://api.agrotrace.io/actors/processor", true
        );
        actorsRegistry.grantRoleFor(processor, actorsRegistry.ROLE_PROCESSOR());
        console.log("Processor setup:", processor);

        // 3. Setup Inspector
        console.log("\n3. Setting up Inspector...");
        actorsRegistry.addActor(
            inspector, "Certificadora EcoVerde", "did:agro:inspector", "https://api.agrotrace.io/actors/inspector", true
        );
        actorsRegistry.grantRoleFor(inspector, actorsRegistry.ROLE_INSPECTOR());
        console.log("Inspector setup:", inspector);

        vm.stopBroadcast();

        console.log("\n=== Minimal Actors Setup Complete ===");
        console.log("Total wallets needed: 3 + admin = 4");
    }
}
