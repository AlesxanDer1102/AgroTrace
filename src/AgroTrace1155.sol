// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IFarmNFT.sol";
import "./IActorsRegistry.sol";
import "./IAgroTrace1155.sol";

contract AgroTrace1155 is ERC1155Supply, ERC1155Burnable, AccessControl, IAgroTrace1155 {
    using Strings for uint256;

    // ===== Dependencias =====
    IFarmNFT public immutable farmNft;
    IActorsRegistry public immutable registry;

    // Roles interoperables
    bytes32 private constant ROLE_PRODUCER = keccak256("PRODUCER");
    bytes32 private constant ROLE_PROCESSOR = keccak256("PROCESSOR");
    bytes32 private constant ROLE_TRANSPORTER = keccak256("TRANSPORTER");

    // ===== Datos de lotes =====
    mapping(uint256 => LotMeta) public lot; // tokenId -> metadatos
    mapping(uint256 => string) private _tokenURI;
    mapping(uint256 => LotState) public state;

    // Linaje
    mapping(uint256 => uint256) public parentOf;
    mapping(uint256 => uint256[]) private _childrenOf;

    // Harvest -> lotes
    mapping(bytes32 => uint256[]) private _harvestLots;

    constructor(string memory baseURI, address farmNFT_, address actorsRegistry_, address admin) ERC1155(baseURI) {
        farmNft = IFarmNFT(farmNFT_);
        registry = IActorsRegistry(actorsRegistry_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // ===== Modificadores =====
    modifier onlyActive(bytes32 role_) {
        require(registry.isActive(msg.sender) && registry.hasRole(msg.sender, role_), "Trace: role inactive");
        _;
    }

    modifier onlyCustodianOrRole(bytes32 role_, uint256 id) {
        require(
            balanceOf(msg.sender, id) > 0 || (registry.isActive(msg.sender) && registry.hasRole(msg.sender, role_)),
            "Trace: not custodian/role"
        );
        _;
    }

    // ===== Harvest / Lote =====
    function createHarvest(uint256 farmNftId, string calldata product, uint64 startDate, uint64 season, uint64 seq)
        external
        onlyActive(ROLE_PRODUCER)
        returns (bytes32 harvestId)
    {
        require(farmNft.exists(farmNftId), "Trace: farm unknown");
        harvestId = keccak256(abi.encode(farmNftId, product, season, seq));
        emit HarvestCreated(harvestId, farmNftId, product, startDate);
    }

    function mintLot(uint256 id, LotMeta calldata m, uint256 amount, address owner)
        external
        onlyActive(ROLE_PRODUCER)
    {
        require(lot[id].harvestId == bytes32(0), "Trace: lot exists");
        require(amount > 0, "Trace: amount=0");
        require(farmNft.exists(m.farmNftId), "Trace: farm unknown");

        lot[id] = m;
        _tokenURI[id] = m.tokenURI;
        state[id] = LotState.EnFinca;

        _mint(owner, id, amount, "");
        _harvestLots[m.harvestId].push(id);

        emit LotMinted(id, m.harvestId, amount, owner);
    }

    function setState(uint256 id, LotState s, uint64 t) external onlyCustodianOrRole(ROLE_PRODUCER, id) {
        require(exists(id), "Trace: unknown lot");
        state[id] = s;
        emit StateChanged(id, s, t);
    }

    // ===== Etapas / Anclajes =====
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
    ) external onlyCustodianOrRole(ROLE_PROCESSOR, id) {
        require(exists(id), "Trace: unknown lot");
        emit StageAnchored(id, stage, time, contentHash, avgT, lastT, avgH, lastH, avgSoil, lastSoil, sensorRoot);
    }

    function recordStop(uint256 id, bytes12 place, bytes32 docRefHash, bytes32 sensorRoot, uint64 time)
        external
        onlyCustodianOrRole(ROLE_TRANSPORTER, id)
    {
        require(exists(id), "Trace: unknown lot");
        emit StopRecorded(id, place, msg.sender, time, docRefHash, sensorRoot);
    }

    function appendSensorRoot(uint256 id, bytes32 root, uint64, /*t0*/ uint64 t1)
        external
        onlyCustodianOrRole(ROLE_TRANSPORTER, id)
    {
        require(exists(id), "Trace: unknown lot");
        // Anclaje agregado de transporte (usar StageAnchored como evento genérico)
        emit StageAnchored(id, Stage.Transporte, t1, bytes32(0), 0, 0, 0, 0, 0, 0, root);
    }

    function declareRoute(uint256 id, bytes12 fromG, bytes12 toG, address carrier, uint64 eta)
        external
        onlyCustodianOrRole(ROLE_PRODUCER, id)
    {
        require(exists(id), "Trace: unknown lot");
        require(registry.hasRole(carrier, ROLE_TRANSPORTER), "Trace: carrier not transporter");
        emit RouteDeclared(id, fromG, toG, carrier, eta);
    }

    function markDelivered(uint256 id, bytes12 destG, uint64 t, bytes32 receiptHash)
        external
        onlyCustodianOrRole(ROLE_RETAILER(), id)
    {
        require(exists(id), "Trace: unknown lot");
        emit Delivered(id, destG, t, receiptHash);
        state[id] = LotState.Entregado;
        emit StateChanged(id, LotState.Entregado, t);
    }

    // ===== Split / Proceso =====
    function splitToChild(uint256 parent, uint256 child, uint256 amount) external {
        require(exists(parent), "Trace: unknown parent");
        require(lot[child].harvestId == bytes32(0), "Trace: child exists");
        require(balanceOf(msg.sender, parent) >= amount && amount > 0, "Trace: insufficient");

        _burn(msg.sender, parent, amount);

        LotMeta memory p = lot[parent];
        lot[child] = LotMeta(p.farmNftId, p.harvestId, p.product, p.variety, p.unit, p.unitDecimals, p.tokenURI, true);
        state[child] = state[parent];
        parentOf[child] = parent;
        _childrenOf[parent].push(child);

        _mint(msg.sender, child, amount, "");
        emit LotDerived(parent, child, amount, amount, keccak256("SPLIT"));
    }

    function processToChild(uint256 parent, uint256 child, uint256 inAmt, uint256 outAmt, bytes32 processType)
        external
        onlyActive(ROLE_PROCESSOR)
    {
        require(exists(parent), "Trace: unknown parent");
        require(lot[child].harvestId == bytes32(0), "Trace: child exists");
        require(inAmt > 0 && outAmt > 0, "Trace: amount=0");
        require(balanceOf(msg.sender, parent) >= inAmt, "Trace: insufficient");

        _burn(msg.sender, parent, inAmt);

        LotMeta memory p = lot[parent];
        lot[child] = LotMeta(p.farmNftId, p.harvestId, p.product, p.variety, p.unit, p.unitDecimals, p.tokenURI, true);
        state[child] = LotState.EnProceso;
        parentOf[child] = parent;
        _childrenOf[parent].push(child);

        _mint(msg.sender, child, outAmt, "");
        emit LotDerived(parent, child, inAmt, outAmt, processType);
    }

    // ===== Interceptar data de transferencias (OZ v5) =====
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        virtual
        override(ERC1155)
    {
        super.safeTransferFrom(from, to, id, amount, data);

        // after transfer: si se incluyó data con parada, la registramos
        if (from != address(0) && to != address(0) && data.length == 128) {
            (bytes12 place, bytes32 docRefHash, bytes32 sensorRoot, uint64 time) =
                abi.decode(data, (bytes12, bytes32, bytes32, uint64));
            emit StopRecorded(id, place, _msgSender(), time, docRefHash, sensorRoot);
            state[id] = LotState.EnTransito;
            emit StateChanged(id, LotState.EnTransito, time);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        if (from != address(0) && to != address(0) && data.length == 128) {
            (bytes12 place, bytes32 docRefHash, bytes32 sensorRoot, uint64 time) =
                abi.decode(data, (bytes12, bytes32, bytes32, uint64));
            for (uint256 i = 0; i < ids.length; i++) {
                emit StopRecorded(ids[i], place, _msgSender(), time, docRefHash, sensorRoot);
                state[ids[i]] = LotState.EnTransito;
                emit StateChanged(ids[i], LotState.EnTransito, time);
            }
        }
    }

    // ===== Hook de OZ v5 (necesario por herencia múltiple) =====
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
        // Nota: aquí no tenemos "data"; los eventos de parada se manejan en safeTransferFrom.
    }

    // ===== Getters =====
    function uri(uint256 id) public view override(ERC1155, IAgroTrace1155) returns (string memory) {
        if (bytes(_tokenURI[id]).length > 0) return _tokenURI[id];
        return super.uri(id);
    }

    function setTokenURI(uint256 id, string calldata newURI) external {
        require(exists(id), "Trace: unknown");
        require(registry.hasRole(msg.sender, ROLE_PRODUCER), "Trace: not producer");
        _tokenURI[id] = newURI;
    }

    function getChildren(uint256 parent) external view returns (uint256[] memory) {
        return _childrenOf[parent];
    }

    function harvestLots(bytes32 hId, uint256 idx) external view returns (uint256) {
        return _harvestLots[hId][idx];
    }

    function ROLE_RETAILER() public pure returns (bytes32) {
        return keccak256("RETAILER");
    }

    function supportsInterface(bytes4 iid) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(iid) || iid == type(IAgroTrace1155).interfaceId;
    }
}
