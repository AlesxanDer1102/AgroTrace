// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FarmNFT.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract DeployFarmNFTScript is Script {
    FarmNFT public farmNFT;
    address public admin;

    function setUp() public {
        admin = vm.envAddress("ADMIN_ADDRESS");
    }

    function run() public {
        vm.startBroadcast();

        console.log("=== Deploying FarmNFT ===");
        console.log("Admin address:", admin);
        console.log("Deployer:", admin);

        // Deploy FarmNFT
        farmNFT = new FarmNFT(admin);
        console.log("FarmNFT deployed at:", address(farmNFT));

        // Verify interface
        console.log("FarmNFT supports IERC721:", 
            farmNFT.supportsInterface(type(IERC721).interfaceId));

        vm.stopBroadcast();

        console.log("\n=== FarmNFT Deployment Complete ===");
        console.log("Save this address: FARM_NFT_ADDRESS=", address(farmNFT));
    }
}