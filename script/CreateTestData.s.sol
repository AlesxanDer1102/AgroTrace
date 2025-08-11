// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ActorsRegistry.sol";
import "../src/FarmNFT.sol";
import "../src/Certificates.sol";
import "../src/AgroTrace1155.sol";
import "../src/IAgroTrace1155.sol";

contract CreateTestDataScript is Script {
    ActorsRegistry public actorsRegistry;
    FarmNFT public farmNFT;
    Certificates public certificates;
    AgroTrace1155 public agroTrace;

    address public producer;
    address public processor;
    address public inspector;

    function setUp() public {
        actorsRegistry = ActorsRegistry(vm.envAddress("ACTORS_REGISTRY_ADDRESS"));
        farmNFT = FarmNFT(vm.envAddress("FARM_NFT_ADDRESS"));
        certificates = Certificates(vm.envAddress("CERTIFICATES_ADDRESS"));
        agroTrace = AgroTrace1155(vm.envAddress("AGROTRACE_ADDRESS"));

        producer = vm.envAddress("PRODUCER_ADDRESS");
        processor = vm.envAddress("PROCESSOR_ADDRESS");
        inspector = vm.envAddress("INSPECTOR_ADDRESS");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Creating Single Test Flow ===");

        // 1. Registrar 1 finca de café
        console.log("\n1. Registering coffee farm...");
        createSingleFarm();

        // 2. Crear 1 lote de café con flujo completo
        console.log("\n2. Creating coffee lot with full traceability...");
        createSingleLotWithFullFlow();

        vm.stopBroadcast();

        console.log("\n=== Single Test Flow Complete ===");
        console.log("Ready for frontend testing with lot ID: 101");
    }

    function createSingleFarm() internal {
        // Solo 1 finca de café
        farmNFT.registerFarm(
            1,
            producer,
            FarmNFT.FarmData({
                name: "Finca Los Andes",
                region: "Antioquia",
                countryISO: "CO",
                geohash: bytes12("ezpkqtpkmyqh"), // Medellín, Colombia
                cropFocus: "cafe",
                photoURI: "https://ipfs.io/ipfs/QmCoffeePhoto",
                metaURI: "https://api.agrotrace.io/farms/1"
            }),
            "https://api.agrotrace.io/farms/1/metadata"
        );
        console.log("Coffee farm registered to producer");
    }

    function createSingleLotWithFullFlow() internal {
        uint64 currentTime = uint64(block.timestamp);

        // 1. Crear cosecha
        bytes32 harvestId = agroTrace.createHarvest(
            1, // farmNftId
            "cafe",
            currentTime - 30 days,
            2024,
            1 // sequence
        );
        console.log("Coffee harvest created");

        // 2. Crear lote
        IAgroTrace1155.LotMeta memory lotMeta = IAgroTrace1155.LotMeta({
            farmNftId: 1,
            harvestId: harvestId,
            product: "cafe",
            variety: "Arabica Colombia",
            unit: keccak256("KG"),
            unitDecimals: 0,
            tokenURI: "https://api.agrotrace.io/lots/101",
            active: true
        });

        agroTrace.mintLot(101, lotMeta, 1000, producer);
        console.log("Coffee lot 101 minted (1000 KG)");

        // === FLUJO COMPLETO DE TRAZABILIDAD ===

        // Etapa 1: Producción en campo
        agroTrace.stageAnchor(
            101,
            IAgroTrace1155.Stage.Produccion,
            currentTime - 25 days,
            keccak256("produccion_data"),
            2500, // 25.00°C promedio
            2400, // 24.00°C última
            6500, // 65.00% humedad promedio
            6200, // 62.00% humedad última
            4500, // 45.00% humedad suelo promedio
            4200, // 42.00% humedad suelo última
            keccak256("sensor_root_1")
        );
        console.log("Stage 1: Produccion completed");

        // Transferir a procesador
        vm.prank(producer);
        agroTrace.safeTransferFrom(producer, processor, 101, 800, "");

        // Etapa 2: Procesamiento y empaque
        vm.prank(processor);
        agroTrace.stageAnchor(
            101,
            IAgroTrace1155.Stage.ProcesoEmpaque,
            currentTime - 20 days,
            keccak256("proceso_data"),
            2200, // 22.00°C promedio
            2100, // 21.00°C última
            5000, // 50.00% humedad promedio
            4800, // 48.00% humedad última
            0,
            0, // No aplica humedad suelo en procesamiento
            keccak256("sensor_root_2")
        );
        console.log("Stage 2: ProcesoEmpaque completed");

        // Declarar ruta (processor actúa como transporter también)
        vm.prank(processor);
        agroTrace.declareRoute(
            101,
            bytes12("ezpkqtpkmyqh"), // Medellín (origen)
            bytes12("9q5ct20p6ms7"), // Bogotá (destino)
            producer, // producer actúa como transporter
            currentTime - 10 days
        );

        // Transferir de vuelta al producer (que actúa como transporter)
        vm.prank(processor);
        agroTrace.safeTransferFrom(processor, producer, 101, 800, "");

        // Etapa 3: Transporte
        vm.prank(producer);
        agroTrace.stageAnchor(
            101,
            IAgroTrace1155.Stage.Transporte,
            currentTime - 15 days,
            keccak256("transporte_data"),
            2000, // 20.00°C promedio
            1900, // 19.00°C última
            7000, // 70.00% humedad promedio
            6800, // 68.00% humedad última
            0,
            0, // No aplica humedad suelo en transporte
            keccak256("sensor_root_3")
        );
        console.log("Stage 3: Transporte completed");

        // Etapa 4: Llegada/Entrega (producer actúa como retailer)
        vm.prank(producer);
        agroTrace.markDelivered(
            101,
            bytes12("9q5ct20p6ms7"), // Bogotá destino
            currentTime - 5 days,
            keccak256("delivery_receipt")
        );
        console.log("Stage 4: Llegada completed");

        // Agregar certificaciones
        vm.prank(inspector);
        certificates.linkByRole(
            101,
            keccak256("ORGANIC"),
            keccak256("organic_cert_doc"),
            inspector,
            currentTime - 60 days,
            currentTime + 365 days
        );
        console.log("Organic certificate added");

        vm.prank(inspector);
        certificates.linkByRole(
            101,
            keccak256("FAIR_TRADE"),
            keccak256("fair_trade_cert_doc"),
            inspector,
            currentTime - 45 days,
            currentTime + 365 days
        );
        console.log("Fair trade certificate added");

        console.log("\nComplete traceability flow for lot 101 finished!");
        console.log("Farm: Finca Los Andes (Antioquia, CO)");
        console.log("Product: 1000 KG Arabica Colombia Coffee");
        console.log("Certifications: Organic + Fair Trade");
        console.log("All 4 stages completed with IoT data");
    }
}
