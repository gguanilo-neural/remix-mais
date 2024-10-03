// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Audit Management Contract - Supply Chain Management System
/// @notice This contract manages automatic audits for events in the supply chain to ensure transparency and verifiability.
/// @dev Events are recorded to provide a complete audit trail, and participants can access audit records.

contract AuditManagement {

    // Struct to define an audit event
    struct AuditEvent {
        uint256 eventId;
        string eventType;
        address actor;
        string description;
        uint256 timestamp;
    }

    // Mapping to store audit events
    mapping(uint256 => AuditEvent) private auditEvents;

    // Counter for generating unique audit event IDs
    uint256 private eventCounter;

    // Mapping to store addresses approved for recording audit events
    mapping(address => bool) private approvedAuditors;

    // Event emitted when a new audit event is recorded
    event AuditEventRecorded(uint256 indexed eventId, string eventType, address indexed actor, string description, uint256 timestamp);

    // Event emitted when an auditor is approved
    event AuditorApproved(address indexed auditor);

    // Event emitted when an auditor is removed
    event AuditorRemoved(address indexed auditor);

    // State variable to indicate if the contract is paused
    bool private paused;

    // Modifier to restrict access to approved auditors
    modifier onlyApprovedAuditor() {
        require(approvedAuditors[msg.sender], "Access Denied: Not an authorized auditor");
        _;
    }

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Constructor to assign the contract creator as the initial auditor
    constructor() {
        approvedAuditors[msg.sender] = true;
        emit AuditorApproved(msg.sender);
    }

    /// @notice Approve a new auditor for recording audit events
    /// @param _auditor The address to be approved as an auditor
    function approveAuditor(address _auditor) external onlyApprovedAuditor whenNotPaused {
        require(!approvedAuditors[_auditor], "Approval Error: Auditor already approved");
        approvedAuditors[_auditor] = true;
        emit AuditorApproved(_auditor);
    }

    /// @notice Remove an existing auditor
    /// @param _auditor The address to be removed from approved auditors
    function removeAuditor(address _auditor) external onlyApprovedAuditor whenNotPaused {
        require(approvedAuditors[_auditor], "Removal Error: Auditor not found");
        approvedAuditors[_auditor] = false;
        emit AuditorRemoved(_auditor);
    }

    /// @notice Record a new audit event
    /// @param _eventType The type of the event (e.g., ProductRegistered, PaymentReleased)
    /// @param _actor The address of the participant who performed the action
    /// @param _description A detailed description of the event
    function recordAuditEvent(string calldata _eventType, address _actor, string calldata _description) 
        external onlyApprovedAuditor whenNotPaused 
    {
        require(_actor != address(0), "Recording Error: Invalid actor address");

        eventCounter++;
        auditEvents[eventCounter] = AuditEvent({
            eventId: eventCounter,
            eventType: _eventType,
            actor: _actor,
            description: _description,
            timestamp: block.timestamp
        });

        emit AuditEventRecorded(eventCounter, _eventType, _actor, _description, block.timestamp);
    }

    /// @notice Get the details of an audit event
    /// @param _eventId The unique ID of the audit event
    /// @return eventType The type of the audit event (e.g., ProductRegistered, PaymentReleased)
    /// @return actor The address of the participant who performed the action
    /// @return description A detailed description of the event
    /// @return timestamp The time when the event occurred
    function getAuditEvent(uint256 _eventId) 
        external view 
        returns (string memory eventType, address actor, string memory description, uint256 timestamp) 
    {
        AuditEvent memory auditEvent = auditEvents[_eventId];
        require(auditEvent.eventId != 0, "Query Error: Audit event not found");

        return (auditEvent.eventType, auditEvent.actor, auditEvent.description, auditEvent.timestamp);
    }

    /// @notice Pause the contract to prevent certain operations
    function pauseContract() external onlyApprovedAuditor {
        paused = true;
    }

    /// @notice Unpause the contract to resume operations
    function unpauseContract() external onlyApprovedAuditor {
        paused = false;
    }
}
