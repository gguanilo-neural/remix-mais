// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./structs/ProductInventory.sol";

/// @title Inventory Management Contract - Supply Chain Management System
/// @notice This contract manages the inventory of products available at different stages of the supply chain.
/// @dev Inventory levels are tracked in real-time and updated as transactions occur, ensuring transparency and traceability.

contract InventoryManagement {

    // Mapping to store inventory details for each product and owner
    mapping(uint256 => ProductInventory) private inventories;

    // Mapping to store addresses approved for managing inventory
    mapping(address => bool) private approvedManagers;

    // Event emitted when a new product inventory is registered
    event InventoryRegistered(uint256 indexed productId, address indexed owner, uint256 stock);

    // Event emitted when inventory stock is updated
    event InventoryUpdated(uint256 indexed productId, address indexed owner, uint256 newStock);

    // Event emitted when a manager is approved
    event ManagerApproved(address indexed manager);

    // Event emitted when a manager is removed
    event ManagerRemoved(address indexed manager);

    // State variable to indicate if the contract is paused
    bool private paused;

    // Modifier to restrict access to approved inventory managers
    modifier onlyApprovedManager() {
        require(approvedManagers[msg.sender], "Access Denied: Not an authorized manager");
        _;
    }

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Modifier to ensure a product is registered
    modifier isRegisteredProduct(uint256 _productId) {
        require(inventories[_productId].isRegistered, "Query Error: Product not registered in inventory");
        _;
    }

    // Constructor to assign the contract creator as the initial inventory manager
    constructor() {
        approvedManagers[msg.sender] = true;
        emit ManagerApproved(msg.sender);
    }

    /// @notice Approve a new inventory manager
    /// @param _manager The address to be approved as a manager
    function approveManager(address _manager) external onlyApprovedManager whenNotPaused {
        require(!approvedManagers[_manager], "Approval Error: Manager already approved");
        approvedManagers[_manager] = true;
        emit ManagerApproved(_manager);
    }

    /// @notice Remove an existing inventory manager
    /// @param _manager The address to be removed from approved managers
    function removeManager(address _manager) external onlyApprovedManager whenNotPaused {
        require(approvedManagers[_manager], "Removal Error: Manager not found");
        approvedManagers[_manager] = false;
        emit ManagerRemoved(_manager);
    }

    /// @notice Register a new product inventory for an owner
    /// @param _productId The unique ID of the product
    /// @param _stock The initial stock level of the product
    /// @param _owner The address of the inventory owner
    function registerInventory(uint256 _productId, uint256 _stock, address _owner) 
        external onlyApprovedManager whenNotPaused 
    {
        require(!inventories[_productId].isRegistered, "Registration Error: Product inventory already registered");
        require(_owner != address(0), "Registration Error: Invalid owner address");

        inventories[_productId] = ProductInventory({
            productId: _productId,
            stock: _stock,
            owner: _owner,
            isRegistered: true
        });

        emit InventoryRegistered(_productId, _owner, _stock);
    }

    /// @notice Update the inventory stock of a product
    /// @param _productId The unique ID of the product
    /// @param _newStock The new stock level of the product
    function updateInventory(uint256 _productId, uint256 _newStock) 
        external onlyApprovedManager isRegisteredProduct(_productId) whenNotPaused 
    {
        ProductInventory storage inventory = inventories[_productId];
        inventory.stock = _newStock;

        emit InventoryUpdated(_productId, inventory.owner, _newStock);
    }

    /// @notice Get the inventory details of a product
    /// @param _productId The unique ID of the product
    /// @return productId The unique ID of the product
    /// @return stock The current stock level of the product
    /// @return owner The address of the inventory owner
    /// @return isRegistered Indicates if the product is registered in the inventory
    function getInventory(uint256 _productId) 
        external view isRegisteredProduct(_productId) 
        returns (uint256 productId, uint256 stock, address owner, bool isRegistered) 
    {
        ProductInventory memory inventory = inventories[_productId];
        return (inventory.productId, inventory.stock, inventory.owner, inventory.isRegistered);
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
