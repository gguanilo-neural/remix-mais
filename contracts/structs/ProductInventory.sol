// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Product Inventory Struct
/// @notice Defines the structure for product inventory
struct ProductInventory {
    uint256 productId;
    uint256 stock;
    address owner;
    bool isRegistered;
}
