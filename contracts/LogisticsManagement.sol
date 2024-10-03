// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Logistics and Transportation Contract - Supply Chain Management System
/// @notice This contract manages the assignment of transporters for the movement of products, shipment details, and penalties for delays or losses.
/// @dev Includes shipment tracking, estimated delivery times, and penalty enforcement.

contract LogisticsManagement {

    // Enum to define possible shipment statuses
    enum ShipmentStatus { Pending, InTransit, Delivered, Delayed, Lost }

    // Struct to define shipment details
    struct Shipment {
        uint256 shipmentId;
        uint256 productId;
        address transporter;
        uint256 estimatedDeliveryTime;
        string currentLocation;
        ShipmentStatus status;
        uint256 timestamp;
        bool isRegistered;
    }

    // Mapping to store shipment details
    mapping(uint256 => Shipment) private shipments;

    // Mapping to store addresses approved for managing logistics (logistics managers)
    mapping(address => bool) private approvedManagers;

    // Event emitted when a new shipment is created
    event ShipmentCreated(uint256 indexed shipmentId, uint256 productId, address indexed transporter, uint256 estimatedDeliveryTime);

    // Event emitted when shipment status is updated
    event ShipmentStatusUpdated(uint256 indexed shipmentId, ShipmentStatus status, string currentLocation);

    // Event emitted when a logistics manager is approved
    event ManagerApproved(address indexed manager);

    // Event emitted when a logistics manager is removed
    event ManagerRemoved(address indexed manager);

    // Event emitted when a penalty is applied
    event PenaltyApplied(uint256 indexed shipmentId, address indexed transporter, string reason);

    // State variable to indicate if the contract is paused
    bool private paused;

    // Modifier to restrict access to approved logistics managers
    modifier onlyApprovedManager() {
        require(approvedManagers[msg.sender], "Access Denied: Not an authorized manager");
        _;
    }

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Modifier to ensure a shipment is registered
    modifier isRegisteredShipment(uint256 _shipmentId) {
        require(shipments[_shipmentId].isRegistered, "Query Error: Shipment not registered");
        _;
    }

    // Constructor to assign the contract creator as the initial logistics manager
    constructor() {
        approvedManagers[msg.sender] = true;
        emit ManagerApproved(msg.sender);
    }

    /// @notice Approve a new logistics manager
    /// @param _manager The address to be approved as a manager
    function approveManager(address _manager) external onlyApprovedManager whenNotPaused {
        require(!approvedManagers[_manager], "Approval Error: Manager already approved");
        approvedManagers[_manager] = true;
        emit ManagerApproved(_manager);
    }

    /// @notice Remove an existing logistics manager
    /// @param _manager The address to be removed from approved managers
    function removeManager(address _manager) external onlyApprovedManager whenNotPaused {
        require(approvedManagers[_manager], "Removal Error: Manager not found");
        approvedManagers[_manager] = false;
        emit ManagerRemoved(_manager);
    }

    /// @notice Create a new shipment for a product
    /// @param _shipmentId The unique ID of the shipment
    /// @param _productId The ID of the product being shipped
    /// @param _transporter The address of the transporter responsible for the shipment
    /// @param _estimatedDeliveryTime The estimated delivery time (in Unix timestamp)
    function createShipment(uint256 _shipmentId, uint256 _productId, address _transporter, uint256 _estimatedDeliveryTime) 
        external onlyApprovedManager whenNotPaused 
    {
        require(!shipments[_shipmentId].isRegistered, "Creation Error: Shipment already exists");
        require(_transporter != address(0), "Creation Error: Invalid transporter address");

        shipments[_shipmentId] = Shipment({
            shipmentId: _shipmentId,
            productId: _productId,
            transporter: _transporter,
            estimatedDeliveryTime: _estimatedDeliveryTime,
            currentLocation: "Origin",
            status: ShipmentStatus.Pending,
            timestamp: block.timestamp,
            isRegistered: true
        });

        emit ShipmentCreated(_shipmentId, _productId, _transporter, _estimatedDeliveryTime);
    }

    /// @notice Update the status and location of an existing shipment
    /// @param _shipmentId The unique ID of the shipment
    /// @param _status The updated status of the shipment
    /// @param _currentLocation The current location of the shipment
    function updateShipmentStatus(uint256 _shipmentId, ShipmentStatus _status, string calldata _currentLocation) 
        external onlyApprovedManager isRegisteredShipment(_shipmentId) whenNotPaused 
    {
        Shipment storage shipment = shipments[_shipmentId];
        shipment.status = _status;
        shipment.currentLocation = _currentLocation;

        emit ShipmentStatusUpdated(_shipmentId, _status, _currentLocation);
    }

    /// @notice Apply a penalty to a transporter for delays or loss
    /// @param _shipmentId The unique ID of the shipment
    /// @param _reason The reason for applying the penalty
    function applyPenalty(uint256 _shipmentId, string calldata _reason) 
        external onlyApprovedManager isRegisteredShipment(_shipmentId) whenNotPaused 
    {
        Shipment memory shipment = shipments[_shipmentId];
        require(shipment.status == ShipmentStatus.Delayed || shipment.status == ShipmentStatus.Lost, "Penalty Error: Shipment not delayed or lost");

        emit PenaltyApplied(_shipmentId, shipment.transporter, _reason);
    }

    /// @notice Get the details of a shipment
    /// @param _shipmentId The unique ID of the shipment
    /// @return productId The ID of the product being shipped
    /// @return transporter The address of the transporter responsible for the shipment
    /// @return estimatedDeliveryTime The estimated delivery time (in Unix timestamp)
    /// @return currentLocation The current location of the shipment
    /// @return status The current status of the shipment (Pending, InTransit, Delivered, Delayed, Lost)
    /// @return timestamp The time when the shipment was created
    function getShipment(uint256 _shipmentId) 
        external view isRegisteredShipment(_shipmentId) 
        returns (uint256 productId, address transporter, uint256 estimatedDeliveryTime, string memory currentLocation, ShipmentStatus status, uint256 timestamp) 
    {
        Shipment memory shipment = shipments[_shipmentId];
        return (shipment.productId, shipment.transporter, shipment.estimatedDeliveryTime, shipment.currentLocation, shipment.status, shipment.timestamp);
    }

    /// @notice Pause the contract to prevent certain operations
    function pauseContract() external onlyApprovedManager {
        paused = true;
    }

    /// @notice Unpause the contract to resume operations
    function unpauseContract() external onlyApprovedManager {
        paused = false;
    }
}
