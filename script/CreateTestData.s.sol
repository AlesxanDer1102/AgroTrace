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
    address public transporter;

    function setUp() public {
        actorsRegistry = ActorsRegistry(
            vm.envAddress("ACTORS_REGISTRY_ADDRESS")
        );
        farmNFT = FarmNFT(vm.envAddress("FARM_NFT_ADDRESS"));
        certificates = Certificates(vm.envAddress("CERTIFICATES_ADDRESS"));
        agroTrace = AgroTrace1155(vm.envAddress("AGROTRACE_ADDRESS"));

        producer = vm.envAddress("PRODUCER_ADDRESS");
        processor = vm.envAddress("PROCESSOR_ADDRESS");
        inspector = vm.envAddress("INSPECTOR_ADDRESS");
        transporter = vm.envAddress("TRANSPORTER_ROLE");
    }

    function run() public {
        uint256 producerPK = vm.envUint("PRODUCER_ADDRESS_PK");
        vm.startBroadcast(producerPK);

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
                name: "Finca San Pedro",
                region: "Cusco",
                countryISO: "PE",
                geohash: bytes12("6qj47f2kj5mr"), // Cusco, Perú
                cropFocus: "cafe",
                photoURI: "https://upload.wikimedia.org/wikipedia/commons/c/ca/Machu_Picchu%2C_Peru_%282018%29.jpg",
                metaURI: "data:application/json;base64,eyJmYXJtRGV0YWlscyI6eyJhbHRpdHVkZSI6IjE4MDBtIiwic29pbFR5cGUiOiJBcmNpbGxvc28iLCJvcmdhbmljQ2VydGlmaWVkIjp0cnVlLCJ5ZWFyRXN0YWJsaXNoZWQiOjIwMTB9LCJjb250YWN0Ijp7Im93bmVyIjoiSnVhbiBQw6lyZXoiLCJwaG9uZSI6Iis1MS05ODc2NTQzMjEifX0="
            }),
            "data:application/json;base64,eyJuYW1lIjoiRmluY2EgU2FuIFBlZHJvIiwiZGVzY3JpcHRpb24iOiJGaW5jYSBkZSBjYWbDqSBvcmfDoW5pY28gZW4gQ3VzY28sIFBlcsO6LCBlc3BlY2lhbGl6YWRhIGVuIEFyYWJpY2EgZGUgYWx0YSBjYWxpZGFkIiwiaW1hZ2UiOiJodHRwczovL3VwbG9hZC53aWtpbWVkaWEub3JnL3dpa2lwZWRpYS9jb21tb25zL2MvY2EvTWFjaHVfUGljY2h1JTJDX1BlcnVfJTI4MjAxOCUyOS5qcGciLCJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjoiUmVnaW9uIiwidmFsdWUiOiJDdXNjbyJ9LHsidHJhaXRfdHlwZSI6IkNvdW50cnkiLCJ2YWx1ZSI6IlBlcsO6In0seyJ0cmFpdF90eXBlIjoiQ3JvcCIsInZhbHVlIjoiQ2Fmw6kifSx7InRyYWl0X3R5cGUiOiJTaXplIiwidmFsdWUiOiI1MCBoZWN0w6FyZWFzIn1dfQ=="
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
            variety: "Arabica Peruano",
            unit: keccak256("KG"),
            unitDecimals: 0,
            tokenURI: "data:application/json;base64,eyJuYW1lIjoiTG90ZSAxMDEgLSBDYWbDqSBBcmFiaWNhIFBlcnVhbm8iLCJkZXNjcmlwdGlvbiI6IkxvdGUgZGUgMTAwMCBLRyBkZSBjYWbDqSBBcmFiaWNhIGRlIGxhIEZpbmNhIFNhbiBQZWRybyBlbiBDdXNjbywgUGVyw7oiLCJpbWFnZSI6Imh0dHBzOi8vd3d3LnNlbmFzYS5nb2IucGUvc2VuYXNhY29udGlnby93cC1jb250ZW50L3VwbG9hZHMvMjAxOS8wNS9jYWZlLW9yZ2FuaWNvLmpwZyIsImF0dHJpYnV0ZXMiOlt7InRyYWl0X3R5cGUiOiJGYXJtIiwidmFsdWUiOiJGaW5jYSBTYW4gUGVkcm8ifSx7InRyYWl0X3R5cGUiOiJQcm9kdWN0IiwidmFsdWUiOiJDYWbDqSJ9LHsidHJhaXRfdHlwZSI6IlZhcmlldHkiLCJ2YWx1ZSI6IkFyYWJpY2EgUGVydWFubyJ9LHsidHJhaXRfdHlwZSI6IlF1YW50aXR5IiwidmFsdWUiOiIxMDAwIEtHIn1dfQ==",
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
        agroTrace.safeTransferFrom(producer, processor, 101, 800, "");

        vm.stopBroadcast();

        // Cambiar a procesador
        uint256 processorPK = vm.envUint("PROCESSOR_ADDRESS_PK");
        vm.startBroadcast(processorPK);

        // Etapa 2: Procesamiento y empaque
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

        // Declarar ruta con transporter dedicado
        agroTrace.declareRoute(
            101,
            bytes12("6qj47f2kj5mr"), // Cusco (origen)
            bytes12("6p8vuy2hgw8r"), // Lima (destino)
            transporter, // transporter dedicado
            currentTime - 10 days
        );

        // Transferir a transporter
        agroTrace.safeTransferFrom(processor, transporter, 101, 800, "");

        vm.stopBroadcast();

        // Cambiar a transporter
        uint256 transporterPK = vm.envUint("TRANSPORTER_ROLE_PK");
        vm.startBroadcast(transporterPK);

        // Etapa 3: Transporte
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

        // Transferir a retailer (producer actúa como retailer final)
        agroTrace.safeTransferFrom(transporter, producer, 101, 800, "");

        vm.stopBroadcast();

        // Cambiar de vuelta a producer para entrega final
        uint256 producerPK = vm.envUint("PRODUCER_ADDRESS_PK");
        vm.startBroadcast(producerPK);

        // Etapa 4: Llegada/Entrega
        agroTrace.markDelivered(
            101,
            bytes12("6p8vuy2hgw8r"), // Lima destino
            currentTime - 5 days,
            keccak256("delivery_receipt")
        );
        console.log("Stage 4: Llegada completed");

        vm.stopBroadcast();

        // Cambiar a inspector
        uint256 inspectorPK = vm.envUint("INSPECTOR_ADDRESS_PK");
        vm.startBroadcast(inspectorPK);

        // Agregar certificaciones
        certificates.linkByRole(
            101,
            keccak256("ORGANIC"),
            keccak256("organic_cert_doc"),
            inspector,
            currentTime - 60 days,
            currentTime + 365 days
        );
        console.log("Organic certificate added");

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
        console.log("Farm: Finca San Pedro (Cusco, PE)");
        console.log("Product: 1000 KG Arabica Peruano Coffee");
        console.log("Certifications: Organic + Fair Trade");
        console.log("All 4 stages completed with IoT data");
    }
}
