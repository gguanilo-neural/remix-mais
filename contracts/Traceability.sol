// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Traceability and Tracking Contract - Supply Chain Management System
/// @notice This contract manages the recording of events related to product movements within the supply chain.
/// @dev It includes transaction data, location, participants, and ensures product authenticity and provenance verification.

contract Traceability {

    // Struct to define the details of a product movement event
    struct MovementEvent {
        uint256 productId;
        string location;
        address from;
        address to;
        uint256 timestamp;
        string eventDetails;
    }

    // Struct to define a product's authenticity information
    struct Product {
        uint256 productId;
        bool isRegistered;
        address origin;
        uint256 creationDate;
    }

    // Mapping to store the movement history of products
    mapping(uint256 => MovementEvent[]) private productMovements;

    // Mapping to store product registration information
    mapping(uint256 => Product) private products;

    // Mapping to store addresses approved for managing product movements
    mapping(address => bool) private approvedManagers;

    // Event emitted when a new product is registered
    event ProductRegistered(uint256 indexed productId, address indexed origin);

    // Event emitted when a product movement is recorded
    event ProductMoved(uint256 indexed productId, address indexed from, address indexed to, string location);

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

    // Modifier to ensure a product is registered
    modifier isRegisteredProduct(uint256 _productId) {
        require(products[_productId].isRegistered, "Query Error: Product not registered");
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

    /// @notice Approve a new manager for product movement management
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

    /// @notice Register a new product to start its traceability
    /// @param _productId The unique ID of the product
    function registerProduct(uint256 _productId) external onlyApprovedManager whenNotPaused {
        require(!products[_productId].isRegistered, "Registration Error: Product already registered");
        products[_productId] = Product(_productId, true, msg.sender, block.timestamp);
        emit ProductRegistered(_productId, msg.sender);
    }

    /// @notice Record a product movement event
    /// @param _productId The unique ID of the product being moved
    /// @param _location The location where the event occurred
    /// @param _to The address of the recipient
    /// @param _eventDetails Additional details of the event
    function recordMovement(uint256 _productId, string calldata _location, address _to, string calldata _eventDetails)
        external onlyApprovedManager isRegisteredProduct(_productId) whenNotPaused 
    {
        Product memory product = products[_productId];
        address previousOwner = product.origin;

        // Record the movement event
        productMovements[_productId].push(MovementEvent(
            _productId,
            _location,
            previousOwner,
            _to,
            block.timestamp,
            _eventDetails
        ));

        // Update the origin to the new owner for future reference
        products[_productId].origin = _to;

        emit ProductMoved(_productId, previousOwner, _to, _location);
    }

    /// @notice Get the movement history of a product
    /// @param _productId The unique ID of the product
    /// @return An array of MovementEvent structs representing the product's history
    function getProductMovementHistory(uint256 _productId)
        external view isRegisteredProduct(_productId) returns (MovementEvent[] memory)
    {
        return productMovements[_productId];
    }

    /// @notice Verify the authenticity and provenance of a product
    /// @param _productId The unique ID of the product
    /// @return origin The address of the product's origin, and creationDate indicating the initial registration date
    function verifyProductAuthenticity(uint256 _productId)
        external view isRegisteredProduct(_productId) returns (address origin, uint256 creationDate)
    {
        Product memory product = products[_productId];
        return (product.origin, product.creationDate);
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
