// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ActorsRegistry.sol";
import "../src/FarmNFT.sol";
import "../src/Certificates.sol";
import "../src/AgroTrace1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

contract DeployScript is Script {
    // Direcciones de los contratos desplegados
    ActorsRegistry public actorsRegistry;
    FarmNFT public farmNFT;
    Certificates public certificates;
    AgroTrace1155 public agroTrace;

    // Configuración
    address public admin;
    string public baseURI = "https://api.agrotrace.io/metadata/";

    function setUp() public {
        admin = vm.envAddress("ADMIN_ADDRESS");
    }

    function run() public {
        vm.startBroadcast();

        console.log("=== Deploying AgroTrace Contracts ===");
        console.log("Admin address:", admin);
        console.log("Deployer:", admin);

        // 1. Deploy ActorsRegistry
        console.log("\n1. Deploying ActorsRegistry...");
        actorsRegistry = new ActorsRegistry(admin);
        console.log("ActorsRegistry deployed at:", address(actorsRegistry));

        // 2. Deploy FarmNFT
        console.log("\n2. Deploying FarmNFT...");
        farmNFT = new FarmNFT(admin);
        console.log("FarmNFT deployed at:", address(farmNFT));

        // 3. Deploy Certificates
        console.log("\n3. Deploying Certificates...");
        certificates = new Certificates(address(actorsRegistry));
        console.log("Certificates deployed at:", address(certificates));

        // 4. Deploy AgroTrace1155
        console.log("\n4. Deploying AgroTrace1155...");
        agroTrace = new AgroTrace1155(baseURI, address(farmNFT), address(actorsRegistry), admin);
        console.log("AgroTrace1155 deployed at:", address(agroTrace));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("ActorsRegistry:", address(actorsRegistry));
        console.log("FarmNFT:", address(farmNFT));
        console.log("Certificates:", address(certificates));
        console.log("AgroTrace1155:", address(agroTrace));

    }
}
