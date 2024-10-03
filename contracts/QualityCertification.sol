// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Quality Certification Contract - Supply Chain Management System
/// @notice This contract manages quality criteria, product certifications, and compliance tracking.
/// @dev It includes quality inspector roles, product certification records, and quality verification functions.

contract QualityCertification {

    // Enum to define possible quality statuses
    enum QualityStatus { NotCertified, Certified, Failed }

    // Struct to define a quality certification record
    struct Certification {
        uint256 productId;
        string criteria;
        QualityStatus status;
        uint256 timestamp;
        address inspector;
    }

    // Mapping to store product certifications
    mapping(uint256 => Certification) private productCertifications;

    // Mapping to store addresses approved for managing quality certifications (inspectors)
    mapping(address => bool) private approvedInspectors;

    // Event emitted when a new quality certification is added
    event CertificationAdded(uint256 indexed productId, string criteria, QualityStatus status, address indexed inspector);

    // Event emitted when an inspector is approved
    event InspectorApproved(address indexed inspector);

    // Event emitted when an inspector is removed
    event InspectorRemoved(address indexed inspector);

    // State variable to indicate if the contract is paused
    bool private paused;

    // Modifier to restrict access to approved inspectors
    modifier onlyApprovedInspector() {
        require(approvedInspectors[msg.sender], "Access Denied: Not an authorized inspector");
        _;
    }

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Constructor to assign the contract creator as the initial inspector
    constructor() {
        approvedInspectors[msg.sender] = true;
        emit InspectorApproved(msg.sender);
    }

    /// @notice Approve a new inspector for quality certification
    /// @param _inspector The address to be approved as an inspector
    function approveInspector(address _inspector) external onlyApprovedInspector whenNotPaused {
        require(!approvedInspectors[_inspector], "Approval Error: Inspector already approved");
        approvedInspectors[_inspector] = true;
        emit InspectorApproved(_inspector);
    }

    /// @notice Remove an existing inspector
    /// @param _inspector The address to be removed from approved inspectors
    function removeInspector(address _inspector) external onlyApprovedInspector whenNotPaused {
        require(approvedInspectors[_inspector], "Removal Error: Inspector not found");
        approvedInspectors[_inspector] = false;
        emit InspectorRemoved(_inspector);
    }

    /// @notice Add a quality certification for a product
    /// @param _productId The unique ID of the product
    /// @param _criteria The quality criteria applied for certification
    /// @param _status The quality status of the product
    function addCertification(uint256 _productId, string calldata _criteria, QualityStatus _status)
        external onlyApprovedInspector whenNotPaused 
    {
        require(_status != QualityStatus.NotCertified, "Certification Error: Invalid quality status");
        
        productCertifications[_productId] = Certification({
            productId: _productId,
            criteria: _criteria,
            status: _status,
            timestamp: block.timestamp,
            inspector: msg.sender
        });

        emit CertificationAdded(_productId, _criteria, _status, msg.sender);
    }

    /// @notice Get the quality certification details of a product
    /// @param _productId The unique ID of the product
    /// @return criteria The quality criteria applied for certification
    /// @return status The quality status of the product
    /// @return timestamp The time when the certification was recorded
    /// @return inspector The address of the inspector who certified the product
    function getCertification(uint256 _productId) 
        external view 
        returns (string memory criteria, QualityStatus status, uint256 timestamp, address inspector) 
    {
        Certification memory certification = productCertifications[_productId];
        require(certification.status != QualityStatus.NotCertified, "Query Error: Product not certified");
        
        return (certification.criteria, certification.status, certification.timestamp, certification.inspector);
    }

    /// @notice Pause the contract to prevent certain operations
    function pauseContract() external onlyApprovedInspector {
        paused = true;
    }

    /// @notice Unpause the contract to resume operations
    function unpauseContract() external onlyApprovedInspector {
        paused = false;
    }
}
