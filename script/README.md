# Scripts de Deploy para AgroTrace

Este directorio contiene los scripts de Foundry para desplegar y configurar los contratos de trazabilidad agropecuaria.

## Scripts Disponibles

### Scripts de Deploy (Separados)

#### 1. `01_DeployActorsRegistry.s.sol`
Despliega únicamente el contrato `ActorsRegistry` - Registro de participantes

#### 2. `02_DeployFarmNFT.s.sol`
Despliega únicamente el contrato `FarmNFT` - NFTs de fincas

#### 3. `03_DeployCertificates.s.sol`
Despliega únicamente el contrato `Certificates` - Gestión de certificaciones
**Requiere**: `ACTORS_REGISTRY_ADDRESS` en .env

#### 4. `04_DeployAgroTrace1155.s.sol`
Despliega únicamente el contrato `AgroTrace1155` - Contrato principal de trazabilidad
**Requiere**: `ACTORS_REGISTRY_ADDRESS` y `FARM_NFT_ADDRESS` en .env

### Scripts de Configuración

#### 5. `SetupActors.s.sol`
Configura **solo 3 actores mínimos** con roles múltiples:
- **Producer**: Finca Los Andes (PRODUCER + TRANSPORTER + RETAILER)
- **Processor**: Procesadora AgroMax (PROCESSOR)  
- **Inspector**: Certificadora EcoVerde (INSPECTOR)
**Requiere**: Todas las direcciones de contratos en .env

#### 6. `CreateTestData.s.sol`
Crea **1 flujo completo** de prueba para testing del frontend:
- 1 finca de café (Finca Los Andes, Antioquia, CO)
- 1 lote con trazabilidad completa (ID: 101)
- Flujo completo de 4 etapas con datos IoT
- 2 certificaciones (Orgánico + Comercio Justo)
**Requiere**: Todas las direcciones de contratos y actores en .env

## Variables de Entorno

Crear archivo `.env` con las siguientes variables:

```bash
# Configuración general
PRIVATE_KEY=0x...
ADMIN_ADDRESS=0x...

# Direcciones de contratos (después del deploy)
ACTORS_REGISTRY_ADDRESS=0x...
FARM_NFT_ADDRESS=0x...
CERTIFICATES_ADDRESS=0x...
AGROTRACE_ADDRESS=0x...

# Direcciones de actores (solo 3 necesarias)
PRODUCER_ADDRESS=0x...
PROCESSOR_ADDRESS=0x...
INSPECTOR_ADDRESS=0x...

# RPC URLs
RPC_URL_MAINNET=https://...
RPC_URL_SEPOLIA=https://...
RPC_URL_LOCAL=http://127.0.0.1:8545
```

## Comandos de Deploy

### 1. Deploy en red local (Anvil) - ORDEN SECUENCIAL
```bash
# Iniciar anvil
anvil

# 1. Deploy ActorsRegistry
forge script script/01_DeployActorsRegistry.s.sol --rpc-url $RPC_URL_LOCAL --broadcast
# Copiar dirección en .env como ACTORS_REGISTRY_ADDRESS

# 2. Deploy FarmNFT  
forge script script/02_DeployFarmNFT.s.sol --rpc-url $RPC_URL_LOCAL --broadcast
# Copiar dirección en .env como FARM_NFT_ADDRESS

# 3. Deploy Certificates
forge script script/03_DeployCertificates.s.sol --rpc-url $RPC_URL_LOCAL --broadcast
# Copiar dirección en .env como CERTIFICATES_ADDRESS

# 4. Deploy AgroTrace1155
forge script script/04_DeployAgroTrace1155.s.sol --rpc-url $RPC_URL_LOCAL --broadcast
# Copiar dirección en .env como AGROTRACE_ADDRESS

# 5. Setup actores
forge script script/SetupActors.s.sol --rpc-url $RPC_URL_LOCAL --broadcast

# 6. Crear datos de prueba
forge script script/CreateTestData.s.sol --rpc-url $RPC_URL_LOCAL --broadcast
```

### 2. Deploy en Sepolia testnet - ORDEN SECUENCIAL
```bash
# Seguir el mismo orden secuencial, actualizar .env después de cada deploy

forge script script/01_DeployActorsRegistry.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast --verify
forge script script/02_DeployFarmNFT.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast --verify
forge script script/03_DeployCertificates.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast --verify
forge script script/04_DeployAgroTrace1155.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast --verify
forge script script/SetupActors.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast
forge script script/CreateTestData.s.sol --rpc-url $RPC_URL_SEPOLIA --broadcast
```

### 3. Deploy en Mainnet - ORDEN SECUENCIAL
```bash
# Deploy contratos (SIN datos de prueba) - Seguir orden secuencial

forge script script/01_DeployActorsRegistry.s.sol --rpc-url $RPC_URL_MAINNET --broadcast --verify
forge script script/02_DeployFarmNFT.s.sol --rpc-url $RPC_URL_MAINNET --broadcast --verify  
forge script script/03_DeployCertificates.s.sol --rpc-url $RPC_URL_MAINNET --broadcast --verify
forge script script/04_DeployAgroTrace1155.s.sol --rpc-url $RPC_URL_MAINNET --broadcast --verify

# Setup actores reales (NO ejecutar CreateTestData en mainnet)
forge script script/SetupActors.s.sol --rpc-url $RPC_URL_MAINNET --broadcast
```

## Datos de Prueba Creados

Después de ejecutar `CreateTestData.s.sol`, tendrás **1 flujo completo**:

### Finca
- **Finca 1**: Los Andes (Café, Antioquia, CO)

### Lote con Trazabilidad Completa
- **Lote 101**: 1000 KG Café Arábica Colombia
  - ✅ Etapa 1: Producción (25°C, 65% humedad, 45% suelo)
  - ✅ Etapa 2: Procesamiento (22°C, 50% humedad)
  - ✅ Etapa 3: Transporte (20°C, 70% humedad) 
  - ✅ Etapa 4: Entrega (Bogotá)
  - ✅ Certificados: Orgánico + Comercio Justo

### Flujo Simplificado
```
Producer → Processor → Producer (como transporter) → Producer (como retailer)
  ↓            ↓              ↓                         ↓
Producción  Proceso      Transporte               Entrega
            Inspector agrega certificados
```

**Total wallets necesarias: 4**
- 1 Admin + 3 Actores (Producer, Processor, Inspector)

## Verificación Post-Deploy

Para verificar que todo se desplegó correctamente:

```bash
# Verificar interfaces
cast call $AGROTRACE_ADDRESS "supportsInterface(bytes4)" "0xd9b67a26" --rpc-url $RPC_URL

# Verificar roles
cast call $ACTORS_REGISTRY_ADDRESS "hasRole(address,bytes32)" $PRODUCER_ADDRESS $(cast keccak "PRODUCER") --rpc-url $RPC_URL

# Verificar lotes
cast call $AGROTRACE_ADDRESS "exists(uint256)" 101 --rpc-url $RPC_URL
```

## Notas Importantes

1. **Orden SECUENCIAL obligatorio**: 
   - 01_DeployActorsRegistry → 02_DeployFarmNFT → 03_DeployCertificates → 04_DeployAgroTrace1155 → SetupActors → CreateTestData
2. **Actualizar .env ENTRE deployments**: Después de cada script de deploy individual, copiar la dirección al .env antes del siguiente
3. **Evita problemas de tamaño**: Los contratos separados evitan límites de gas y facilitan debugging
4. **Gas estimation**: Los scripts incluyen console.log para tracking, usar `--gas-estimate` si es necesario
5. **Verificación**: Usar `--verify` en testnets y mainnet para verificar contratos automáticamente

### ⚠️ IMPORTANTE: Dependencias
- `03_DeployCertificates` requiere `ACTORS_REGISTRY_ADDRESS`
- `04_DeployAgroTrace1155` requiere `ACTORS_REGISTRY_ADDRESS` y `FARM_NFT_ADDRESS`
- `SetupActors` requiere todas las direcciones de contratos
- `CreateTestData` requiere todas las direcciones de contratos y actores