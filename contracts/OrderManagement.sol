// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Order Management Contract - Supply Chain Management System
/// @notice This contract manages the creation, updating, and tracking of orders within a supply chain.
/// @dev It includes order status tracking, role-based access control, and event logging for order management.

contract OrderManagement {
    
    // Enum to define different states an order can have
    enum OrderStatus { Pending, InTransit, Delivered, Cancelled }

    // Struct to define an order
    struct Order {
        uint256 orderId;
        address buyer;
        address seller;
        uint256 productId;
        uint256 quantity;
        uint256 timestamp;
        OrderStatus status;
        bool isRegistered;
    }

    // Mapping to store orders
    mapping(uint256 => Order) private orders;

    // Mapping to store addresses approved for managing orders
    mapping(address => bool) private approvedManagers;

    // Event emitted when a new order is created
    event OrderCreated(uint256 indexed orderId, address indexed buyer, address indexed seller, uint256 productId, uint256 quantity);

    // Event emitted when an order status is updated
    event OrderStatusUpdated(uint256 indexed orderId, OrderStatus newStatus);

    // Event emitted when a new manager is approved
    event ManagerApproved(address indexed manager);

    // Event emitted when a manager is removed
    event ManagerRemoved(address indexed manager);

    // State variable to indicate if the contract is paused
    bool private paused;

    // Modifier to restrict access to approved managers
    modifier onlyApprovedManager() {
        require(approvedManagers[msg.sender], "Access Denied: Not an authorized manager");
        _;
    }

    // Modifier to ensure an order is registered
    modifier isRegisteredOrder(uint256 _orderId) {
        require(orders[_orderId].isRegistered, "Query Error: Order not registered");
        _;
    }

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Constructor to assign the contract creator as the initial manager
    constructor() {
        approvedManagers[msg.sender] = true;
        emit ManagerApproved(msg.sender);
    }

    /// @notice Approve a new manager for order management
    /// @param _manager The address to be approved as a manager
    function approveManager(address _manager) external onlyApprovedManager whenNotPaused {
        require(!approvedManagers[_manager], "Approval Error: Manager already approved");
        approvedManagers[_manager] = true;
        emit ManagerApproved(_manager);
    }

    /// @notice Remove an existing manager
    /// @param _manager The address to be removed from approved managers
    function removeManager(address _manager) external onlyApprovedManager whenNotPaused {
        require(approvedManagers[_manager], "Removal Error: Manager not found");
        approvedManagers[_manager] = false;
        emit ManagerRemoved(_manager);
    }

    /// @notice Create a new order
    /// @param _orderId The unique ID of the order
    /// @param _buyer The address of the buyer
    /// @param _seller The address of the seller
    /// @param _productId The ID of the product being ordered
    /// @param _quantity The quantity of the product being ordered
    function createOrder(uint256 _orderId, address _buyer, address _seller, uint256 _productId, uint256 _quantity) 
        external onlyApprovedManager whenNotPaused 
    {
        require(!orders[_orderId].isRegistered, "Creation Error: Order already exists");
        require(_buyer != address(0) && _seller != address(0), "Creation Error: Invalid buyer or seller address");

        orders[_orderId] = Order({
            orderId: _orderId,
            buyer: _buyer,
            seller: _seller,
            productId: _productId,
            quantity: _quantity,
            timestamp: block.timestamp,
            status: OrderStatus.Pending,
            isRegistered: true
        });

        emit OrderCreated(_orderId, _buyer, _seller, _productId, _quantity);
    }

    /// @notice Update the status of an existing order
    /// @param _orderId The unique ID of the order
    /// @param _newStatus The new status to be assigned to the order
    function updateOrderStatus(uint256 _orderId, OrderStatus _newStatus) 
        external onlyApprovedManager isRegisteredOrder(_orderId) whenNotPaused 
    {
        require(_newStatus != orders[_orderId].status, "Update Error: New status must be different from the current status");
        orders[_orderId].status = _newStatus;

        emit OrderStatusUpdated(_orderId, _newStatus);
    }

    /// @notice Get the details of an order
    /// @param _orderId The unique ID of the order
    /// @return Order details including buyer, seller, product ID, quantity, timestamp, and status
    function getOrder(uint256 _orderId) 
        external view isRegisteredOrder(_orderId) 
        returns (address, address, uint256, uint256, uint256, OrderStatus) 
    {
        Order memory order = orders[_orderId];
        return (order.buyer, order.seller, order.productId, order.quantity, order.timestamp, order.status);
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
