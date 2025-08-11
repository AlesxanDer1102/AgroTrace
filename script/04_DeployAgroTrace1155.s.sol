// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgroTrace1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

contract DeployAgroTrace1155Script is Script {
    AgroTrace1155 public agroTrace;
    address public admin;
    address public farmNFT;
    address public actorsRegistry;
    string public baseURI = "https://api.agrotrace.io/metadata/";

    function setUp() public {
        admin = vm.envAddress("ADMIN_ADDRESS");
        farmNFT = vm.envAddress("FARM_NFT_ADDRESS");
        actorsRegistry = vm.envAddress("ACTORS_REGISTRY_ADDRESS");
    }

    function run() public {
        vm.startBroadcast();

        console.log("=== Deploying AgroTrace1155 ===");
        console.log("Admin address:", admin);
        console.log("FarmNFT address:", farmNFT);
        console.log("ActorsRegistry address:", actorsRegistry);
        console.log("Base URI:", baseURI);

        // Deploy AgroTrace1155
        agroTrace = new AgroTrace1155(
            baseURI,
            farmNFT,
            actorsRegistry,
            admin
        );
        console.log("AgroTrace1155 deployed at:", address(agroTrace));

        // Verify interface
        console.log("AgroTrace1155 supports IERC1155:", 
            agroTrace.supportsInterface(type(IERC1155).interfaceId));

        vm.stopBroadcast();
    }
}