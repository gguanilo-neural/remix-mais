// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Product Management Contract - Supply Chain Management System
/// @notice This contract manages the creation, updating, and tracking of products within a supply chain.
/// @dev Includes role-based access, event logging, and historical movement tracking for products.

contract ProductManagement {
    
    // Struct to define the properties of a product
    struct Product {
        uint256 productId;
        string productType;
        string description;
        uint256 productionDate;
        address currentOwner;
        bool isRegistered;
    }

    // Struct to define product movement details
    struct Movement {
        uint256 timestamp;
        address from;
        address to;
    }

    // Mapping to store product details
    mapping(uint256 => Product) private products;

    // Mapping to store product movement history
    mapping(uint256 => Movement[]) private productMovements;

    // Mapping to store addresses approved for product management
    mapping(address => bool) private approvedManagers;

    // Event emitted when a new product is registered
    event ProductRegistered(uint256 indexed productId, string productType, address indexed owner);

    // Event emitted when a product is updated
    event ProductUpdated(uint256 indexed productId, string newDescription);

    // Event emitted when a product is transferred to a new owner
    event ProductTransferred(uint256 indexed productId, address indexed from, address indexed to);

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

    // Modifier to ensure a product is not already registered
    modifier notRegistered(uint256 _productId) {
        require(!products[_productId].isRegistered, "Registration Error: Product is already registered");
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

    /// @notice Approve a new manager for product management
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

    /// @notice Register a new product
    /// @param _productId The unique ID of the product
    /// @param _productType The type of the product (e.g., electronics, food)
    /// @param _description A description of the product
    /// @param _productionDate The production date of the product (in Unix timestamp)
    function registerProduct(uint256 _productId, string calldata _productType, string calldata _description, uint256 _productionDate) 
        external onlyApprovedManager notRegistered(_productId) whenNotPaused 
    {
        products[_productId] = Product(_productId, _productType, _description, _productionDate, msg.sender, true);
        emit ProductRegistered(_productId, _productType, msg.sender);
    }

    /// @notice Update the description of an existing product
    /// @param _productId The unique ID of the product
    /// @param _newDescription The new description of the product
    function updateProduct(uint256 _productId, string calldata _newDescription) external onlyApprovedManager whenNotPaused {
        require(products[_productId].isRegistered, "Update Error: Product not registered");
        products[_productId].description = _newDescription;
        emit ProductUpdated(_productId, _newDescription);
    }

    /// @notice Transfer ownership of a product to a new owner
    /// @param _productId The unique ID of the product
    /// @param _newOwner The address of the new owner
    function transferProduct(uint256 _productId, address _newOwner) external onlyApprovedManager whenNotPaused {
        require(products[_productId].isRegistered, "Transfer Error: Product not registered");
        address previousOwner = products[_productId].currentOwner;
        products[_productId].currentOwner = _newOwner;

        // Record movement in product history
        productMovements[_productId].push(Movement(block.timestamp, previousOwner, _newOwner));
        
        emit ProductTransferred(_productId, previousOwner, _newOwner);
    }

    /// @notice Get the details of a registered product
    /// @param _productId The unique ID of the product
    /// @return Product details including product type, description, production date, and current owner
    function getProduct(uint256 _productId) external view returns (string memory, string memory, uint256, address) {
        require(products[_productId].isRegistered, "Query Error: Product not registered");
        Product memory product = products[_productId];
        return (product.productType, product.description, product.productionDate, product.currentOwner);
    }

    /// @notice Get the movement history of a product
    /// @param _productId The unique ID of the product
    /// @return An array of movements including timestamps, sender, and receiver addresses
    function getProductMovements(uint256 _productId) external view returns (Movement[] memory) {
        require(products[_productId].isRegistered, "Query Error: Product not registered");
        return productMovements[_productId];
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
