# 🌱 AgroTrace - Sistema de Trazabilidad Agropecuaria en Blockchain

**AgroTrace** es un sistema completo de trazabilidad para productos agropecuarios que utiliza blockchain para garantizar transparencia y confiabilidad en toda la cadena de suministro, desde la producción en campo hasta el consumidor final.

## 🎯 ¿Qué es AgroTrace?

AgroTrace permite rastrear productos agrícolas (café, cacao, frutas, etc.) a través de toda su cadena de valor, registrando información crucial como:

- **Origen**: Finca, región, país, coordenadas geográficas
- **Proceso**: Datos IoT de temperatura, humedad y condiciones de cultivo
- **Certificaciones**: Orgánico, comercio justo, huella de carbono
- **Transporte**: Rutas, paradas, condiciones durante el envío
- **Calidad**: Verificaciones y auditorías en cada etapa

## 🏗️ Arquitectura del Sistema

### Contratos Inteligentes

1. **`ActorsRegistry.sol`** - Registro de Participantes
   - Gestiona identidades de productores, procesadores, transportistas, inspectores
   - Control de acceso basado en roles
   - Activación/desactivación de participantes

2. **`FarmNFT.sol`** - Identidad Digital de Fincas
   - Cada finca tiene un NFT único (ERC-721)
   - Metadatos: nombre, región, país, cultivo principal, fotos
   - Geolocalización con geohash para ubicación precisa

3. **`Certificates.sol`** - Gestión de Certificaciones
   - Certificados digitales verificables
   - Soporte para firmas EIP-1271 (contratos inteligentes)
   - Validación temporal y revocación de certificados

4. **`AgroTrace1155.sol`** - Trazabilidad Principal
   - Lotes de productos como tokens ERC-1155
   - Registro de 4 etapas principales con datos IoT
   - Linaje de productos (divisiones y procesamientos)
   - Estados en tiempo real del producto

## 🔄 Flujo de Trazabilidad

### Etapa 1: 🌾 Producción en Campo
- **Actor**: Productor
- **Datos registrados**:
  - Temperatura promedio y última medición
  - Humedad ambiente promedio y última
  - Humedad del suelo promedio y última
  - Hash de contenido con detalles adicionales

### Etapa 2: 🏭 Procesamiento y Empaque
- **Actor**: Procesador
- **Datos registrados**:
  - Tipo de proceso (clasificación, lavado, secado, empaquetado)
  - Temperatura y humedad durante procesamiento
  - Cambios en cantidad (entrada vs salida)

### Etapa 3: 🚛 Transporte
- **Actor**: Transportista
- **Datos registrados**:
  - Ruta declarada (origen → destino)
  - Paradas intermedias con timestamp
  - Condiciones de transporte (temperatura, humedad)
  - Documentación de recogida y entrega

### Etapa 4: 🏪 Llegada y Entrega
- **Actor**: Retailer/Distribuidor
- **Datos registrados**:
  - Ubicación final de entrega
  - Fecha y hora de recepción
  - Hash del recibo de entrega
  - Estado final del producto

## 📱 Frontend - Experiencia del Consumidor

El sistema está diseñado para alimentar un frontend con 3 pantallas principales:

### Pantalla 1: Portada del Producto
- Foto atractiva del producto
- Nombre y variedad (ej: "Café Arábica Colombia")
- Origen (región, país)
- Íconos de certificaciones
- Botón "Ver historia"

### Pantalla 2: Línea de Tiempo del Producto
Recorrido visual con 4 puntos principales:
1. **🌾 Producción**: Foto de finca + datos IoT
2. **🏭 Procesamiento**: Tipo de proceso + condiciones
3. **🚛 Transporte**: Ruta seguida + paradas
4. **🏪 Llegada**: Destino final + fecha

### Pantalla 3: Verificación Blockchain
- Lista de eventos con fechas y hashes
- Enlace al explorador blockchain
- Prueba criptográfica de autenticidad

## 🔧 Tecnología Utilizada

- **Blockchain**: Ethereum / Polygon / BSC
- **Estándares**: ERC-721, ERC-1155, ERC-1271, EIP-712
- **Framework**: Foundry (Forge, Cast, Anvil)
- **Lenguaje**: Solidity ^0.8.20
- **Librerías**: OpenZeppelin Contracts v5
- **Optimización**: Compilador IR habilitado

## 🌍 Casos de Uso

### Para Productores
- Certificar origen y calidad de productos
- Acceso a mercados premium que valoran trazabilidad
- Demostrar prácticas sostenibles

### Para Procesadores/Exportadores
- Mantener integridad de la cadena de suministro
- Cumplir regulaciones internacionales
- Diferenciación en mercados competitivos

### Para Retailers/Importadores
- Verificar autenticidad de productos
- Marketing basado en transparencia
- Gestión de riesgo en la cadena de suministro

### Para Consumidores
- Conocer el origen real de productos
- Verificar certificaciones (orgánico, comercio justo)
- Tomar decisiones de compra informadas

## 🚀 Ventajas Competitivas

✅ **Inmutable**: Registros blockchain no pueden ser alterados  
✅ **Transparente**: Información verificable públicamente  
✅ **Interoperable**: Estándares abiertos para integración  
✅ **Escalable**: Arquitectura modular y optimizada  
✅ **Auditables**: Trail completo desde origen  
✅ **Certificable**: Integración con organismos certificadores  

## 📊 Datos de Ejemplo

El sistema incluye datos de prueba completos:
- **Finca Los Andes** (Antioquia, Colombia)
- **1000 KG de Café Arábica Colombia**
- **Ruta**: Medellín → Bogotá
- **Certificaciones**: Orgánico + Comercio Justo
- **Datos IoT**: Temperaturas 20-25°C, humedad 50-70%

---

## 🛠️ Desarrollo

Este proyecto utiliza **Foundry** para desarrollo, testing y deployment.

### Instalación
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Build
```shell
forge build
```

### Test
```shell
forge test
```

### Deploy
```shell
# Ver documentación en script/README.md
forge script script/01_DeployActorsRegistry.s.sol --broadcast
```

Para instrucciones detalladas de deployment, consulta [`script/README.md`](script/README.md).

## 📚 Documentación Adicional

- **[Análisis de Contratos](RESUMEN.md)** - Resumen técnico detallado
- **[Scripts de Deploy](script/README.md)** - Guía completa de deployment
- **[Foundry Book](https://book.getfoundry.sh/)** - Documentación oficial de Foundry