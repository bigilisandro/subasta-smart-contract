// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    // Variables de estado
    address public owner;
    uint256 public endTime;
    uint256 public minBidIncrease; // Incremento mínimo requerido del 5%
    uint256 public commissionRate; // Comisión del 2%
    uint256 public highestBid;
    address public highestBidder;
    bool public auctionEnded;
    
    // Mapeos para rastrear ofertas y montos reembolsables
    mapping(address => uint256) public bids;
    mapping(address => uint256) public refundableAmounts;
    
    // Eventos
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event RefundIssued(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 newEndTime);
    
    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, unicode"Solo el propietario puede llamar a esta función");
        _;
    }
    
    modifier auctionActive() {
        require(block.timestamp <= endTime, unicode"La subasta ha terminado");
        require(!auctionEnded, unicode"La subasta ha sido finalizada");
        _;
    }
    
    modifier whenAuctionEnded() {
        require(block.timestamp > endTime || auctionEnded, unicode"La subasta sigue activa");
        _;
    }
    
    // Constructor
    constructor(uint256 _durationInMinutes) {
        owner = msg.sender;
        endTime = block.timestamp + (_durationInMinutes * 1 minutes);
        minBidIncrease = 5; // 5%
        commissionRate = 2; // 2%
    }
    
    // Función para realizar una oferta
    function placeBid() external payable auctionActive {
        require(msg.value > 0, unicode"La oferta debe ser mayor que 0");
        
        // Calcular oferta mínima requerida
        uint256 minRequiredBid = highestBid + (highestBid * minBidIncrease / 100);
        require(msg.value >= minRequiredBid, unicode"La oferta debe ser al menos 5% mayor que la oferta más alta actual");
        
        // Almacenar el monto reembolsable del anterior mejor postor
        if (highestBidder != address(0)) {
            refundableAmounts[highestBidder] += highestBid;
        }
        
        // Actualizar la mejor oferta
        highestBid = msg.value;
        highestBidder = msg.sender;
        bids[msg.sender] = msg.value;
        
        // Extender la subasta si se realiza una oferta en los últimos 10 minutos
        if (endTime - block.timestamp <= 10 minutes) {
            endTime = block.timestamp + 10 minutes;
            emit AuctionExtended(endTime);
        }
        
        emit NewBid(msg.sender, msg.value);
    }
    
    // Función para retirar el monto reembolsable
    function withdrawRefund() external {
        uint256 amount = refundableAmounts[msg.sender];
        require(amount > 0, unicode"No hay reembolso disponible");
        
        refundableAmounts[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, unicode"La transferencia del reembolso falló");
        
        emit RefundIssued(msg.sender, amount);
    }
    
    // Función para finalizar la subasta
    function endAuction() external whenAuctionEnded {
        require(!auctionEnded, unicode"La subasta ya ha terminado");
        
        auctionEnded = true;
        
        if (highestBidder != address(0)) {
            // Calcular la comisión
            uint256 commission = (highestBid * commissionRate) / 100;
            uint256 finalAmount = highestBid - commission;
            
            // Transferir la comisión al propietario
            (bool success, ) = owner.call{value: commission}("");
            require(success, unicode"La transferencia de la comisión falló");
            
            // Transferir el monto restante al mejor postor
            (success, ) = highestBidder.call{value: finalAmount}("");
            require(success, unicode"La transferencia al ganador falló");
        }
        
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    // Función para obtener detalles de la subasta
    function getAuctionDetails() external view returns (
        address _highestBidder,
        uint256 _highestBid,
        uint256 _endTime,
        bool _auctionEnded
    ) {
        return (highestBidder, highestBid, endTime, auctionEnded);
    }
    
    // Función para obtener detalles del postor
    function getBidderDetails(address bidder) external view returns (
        uint256 _bidAmount,
        uint256 _refundableAmount
    ) {
        return (bids[bidder], refundableAmounts[bidder]);
    }
    
    // Función para obtener el balance del contrato
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Función para obtener el tiempo restante
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }

    // Función para obtener todas las ofertas
    function getAllBids() external view returns (address[] memory bidders, uint256[] memory amounts) {
        uint256 count = 0;
        for (uint256 i = 0; i < type(uint256).max; i++) {
            if (bids[address(uint160(i))] > 0) {
                count++;
            }
        }
        
        bidders = new address[](count);
        amounts = new uint256[](count);
        
        uint256 index = 0;
        for (uint256 i = 0; i < type(uint256).max; i++) {
            if (bids[address(uint160(i))] > 0) {
                bidders[index] = address(uint160(i));
                amounts[index] = bids[address(uint160(i))];
                index++;
            }
        }
    }
} 