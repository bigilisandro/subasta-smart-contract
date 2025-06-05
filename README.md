# Smart Contract de Subasta

Este contrato inteligente implementa una subasta en la blockchain Ethereum, específicamente en la red de prueba Sepolia.

## Características Principales

- Subasta con duración configurable
- Incremento mínimo de ofertas del 5%
- Comisión del 2% sobre la oferta ganadora
- Extensión automática de 10 minutos si hay ofertas en los últimos 10 minutos
- Sistema de reembolsos para oferentes no ganadores

## Variables de Estado

- `owner`: Dirección del propietario del contrato
- `endTime`: Tiempo de finalización de la subasta
- `minBidIncrease`: Porcentaje mínimo de incremento (5%)
- `commissionRate`: Porcentaje de comisión (2%)
- `highestBid`: Monto de la mayor oferta
- `highestBidder`: Dirección del mejor postor
- `auctionEnded`: Estado de la subasta
- `bids`: Mapeo de direcciones a montos ofrecidos
- `refundableAmounts`: Mapeo de direcciones a montos reembolsables

## Funciones Principales

### Constructor
```solidity
constructor(uint256 _durationInMinutes)
```
Inicializa la subasta con una duración específica en minutos.

### placeBid
```solidity
function placeBid() external payable
```
Permite realizar una oferta. Requiere que:
- La oferta sea mayor que 0
- Sea al menos 5% mayor que la oferta actual
- La subasta esté activa

### withdrawRefund
```solidity
function withdrawRefund() external
```
Permite retirar el monto reembolsable de una oferta anterior.

### endAuction
```solidity
function endAuction() external
```
Finaliza la subasta, transfiere la comisión al propietario y el monto restante al ganador.

### Funciones de Consulta
- `getAuctionDetails()`: Retorna detalles de la subasta
- `getBidderDetails(address)`: Retorna detalles de un postor específico
- `getContractBalance()`: Retorna el balance del contrato
- `getRemainingTime()`: Retorna el tiempo restante de la subasta
- `getAllBids()`: Retorna todas las ofertas realizadas

## Eventos

- `NewBid`: Emitido cuando se realiza una nueva oferta
- `AuctionEnded`: Emitido cuando finaliza la subasta
- `RefundIssued`: Emitido cuando se realiza un reembolso
- `AuctionExtended`: Emitido cuando se extiende la subasta

## Modificadores

- `onlyOwner`: Restringe funciones al propietario
- `auctionActive`: Verifica que la subasta esté activa
- `whenAuctionEnded`: Verifica que la subasta haya terminado

## Consideraciones de Seguridad

- Manejo de reentrancia en transferencias
- Validación de montos y estados
- Protección contra manipulaciones de tiempo
- Manejo seguro de fondos

## Despliegue

El contrato está desplegado en la red Sepolia y verificado para acceso público al código fuente. 