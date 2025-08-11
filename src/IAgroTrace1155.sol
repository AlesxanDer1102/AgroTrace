// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAgroTrace1155 {
    // Etapas (para la línea de tiempo 4 puntos)
    enum Stage {
        Produccion,
        ProcesoEmpaque,
        Transporte,
        Llegada
    }
    // Estados (para dashboards)
    enum LotState {
        EnFinca,
        EnProceso,
        EnTransito,
        EnAduana,
        EnBodega,
        Entregado,
        Cerrado
    }

    struct LotMeta {
        uint256 farmNftId;
        bytes32 harvestId;
        string product;
        string variety;
        bytes32 unit;
        uint8 unitDecimals;
        string tokenURI;
        bool active;
    }

    // Eventos clave
    event HarvestCreated(bytes32 indexed harvestId, uint256 indexed farmNftId, string product, uint64 startDate);
    event LotMinted(uint256 indexed id, bytes32 indexed harvestId, uint256 amount, address owner);

    event StageAnchored(
        uint256 indexed lotId,
        Stage indexed stage,
        uint64 time,
        bytes32 contentHash,
        int32 avgTemp_cDeci,
        int32 lastTemp_cDeci,
        int32 avgHumRel_pDeci,
        int32 lastHumRel_pDeci,
        int32 avgSoilMoist_pDeci,
        int32 lastSoilMoist_pDeci,
        bytes32 sensorRoot
    );

    event StopRecorded(
        uint256 indexed lotId, bytes12 placeGeohash, address actor, uint64 time, bytes32 docRefHash, bytes32 sensorRoot
    );
    event RouteDeclared(uint256 indexed lotId, bytes12 fromGeohash, bytes12 toGeohash, address carrier, uint64 eta);
    event Delivered(uint256 indexed lotId, bytes12 destinationGeohash, uint64 deliveredAt, bytes32 receiptHash);

    event LotDerived(
        uint256 indexed parent, uint256 indexed child, uint256 amountIn, uint256 amountOut, bytes32 processType
    );
    event StateChanged(uint256 indexed id, LotState newState, uint64 time);

    // Funciones mínimas
    function createHarvest(uint256 farmNftId, string calldata product, uint64 startDate, uint64 season, uint64 seq)
        external
        returns (bytes32 harvestId);

    function mintLot(uint256 id, LotMeta calldata m, uint256 amount, address owner) external;

    function setState(uint256 id, LotState s, uint64 t) external;

    function stageAnchor(
        uint256 id,
        Stage stage,
        uint64 time,
        bytes32 contentHash,
        int32 avgT,
        int32 lastT,
        int32 avgH,
        int32 lastH,
        int32 avgSoil,
        int32 lastSoil,
        bytes32 sensorRoot
    ) external;

    function recordStop(uint256 id, bytes12 place, bytes32 docRefHash, bytes32 sensorRoot, uint64 time) external;
    function appendSensorRoot(uint256 id, bytes32 root, uint64 t0, uint64 t1) external;
    function declareRoute(uint256 id, bytes12 fromG, bytes12 toG, address carrier, uint64 eta) external;
    function markDelivered(uint256 id, bytes12 destG, uint64 t, bytes32 receiptHash) external;

    function splitToChild(uint256 parent, uint256 child, uint256 amount) external;
    function processToChild(uint256 parent, uint256 child, uint256 inAmt, uint256 outAmt, bytes32 processType)
        external;

    function uri(uint256 id) external view returns (string memory);
    function getChildren(uint256 parent) external view returns (uint256[] memory);
    function harvestLots(bytes32 hId, uint256 idx) external view returns (uint256); // opcional getter simulado
}
