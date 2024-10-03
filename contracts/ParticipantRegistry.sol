// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Participant Registry - Supply Chain Management System
/// @notice This contract manages the registration and role assignment of participants in a supply chain.
/// @dev Includes role-based access control and event logging for transparency.

contract ParticipantRegistry {
    
    // Enum to define various roles within the supply chain
    enum Role { None, Manufacturer, Supplier, Distributor, Retailer, Customer }

    // Struct to define a participant
    struct Participant {
        address participantAddress;
        Role role;
        bool isRegistered;
    }

    // Mapping to store registered participants
    mapping(address => Participant) private participants;

    // Mapping to store addresses approved for participant registration
    mapping(address => bool) private approvedRegistrars;

    // Event emitted when a new participant is registered
    event ParticipantRegistered(address indexed participantAddress, Role role);

    // Event emitted when a participant's role is updated
    event RoleUpdated(address indexed participantAddress, Role newRole);

    // Event emitted when a new registrar is approved
    event RegistrarApproved(address indexed registrar);

    // Event emitted when a registrar is removed
    event RegistrarRemoved(address indexed registrar);

    // Event emitted when a participant is removed
    event ParticipantRemoved(address indexed participantAddress);

    // State variable to indicate if the contract is paused
    bool private paused;

    // Modifier to restrict access to approved registrars
    modifier onlyApprovedRegistrar() {
        require(approvedRegistrars[msg.sender], "Access Denied: Not an authorized registrar");
        _;
    }

    // Modifier to ensure a participant is not already registered
    modifier notRegistered(address _address) {
        require(!participants[_address].isRegistered, "Registration Error: Address is already registered");
        _;
    }

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Constructor to assign the contract creator as the initial registrar
    constructor() {
        approvedRegistrars[msg.sender] = true;
        emit RegistrarApproved(msg.sender);
    }

    /// @notice Approve a new registrar for participant registration
    /// @param _registrar The address to be approved as a registrar
    function approveRegistrar(address _registrar) external onlyApprovedRegistrar whenNotPaused {
        require(!approvedRegistrars[_registrar], "Approval Error: Registrar already approved");
        approvedRegistrars[_registrar] = true;
        emit RegistrarApproved(_registrar);
    }

    /// @notice Remove an existing registrar
    /// @param _registrar The address to be removed from approved registrars
    function removeRegistrar(address _registrar) external onlyApprovedRegistrar whenNotPaused {
        require(approvedRegistrars[_registrar], "Removal Error: Registrar not found");
        approvedRegistrars[_registrar] = false;
        emit RegistrarRemoved(_registrar);
    }

    /// @notice Register a new participant with a specified role
    /// @param _participantAddress The address of the participant to be registered
    /// @param _role The role assigned to the participant
    function registerParticipant(address _participantAddress, Role _role) external onlyApprovedRegistrar notRegistered(_participantAddress) whenNotPaused {
        require(_role != Role.None, "Registration Error: Invalid role specified");
        participants[_participantAddress] = Participant(_participantAddress, _role, true);
        emit ParticipantRegistered(_participantAddress, _role);
    }

    /// @notice Update the role of an existing participant
    /// @param _participantAddress The address of the participant whose role is to be updated
    /// @param _newRole The new role to be assigned to the participant
    function updateRole(address _participantAddress, Role _newRole) external onlyApprovedRegistrar whenNotPaused {
        require(participants[_participantAddress].isRegistered, "Update Error: Participant not registered");
        require(_newRole != Role.None, "Update Error: Invalid role specified");
        participants[_participantAddress].role = _newRole;
        emit RoleUpdated(_participantAddress, _newRole);
    }

    /// @notice Get the role of a registered participant
    /// @param _participantAddress The address of the participant
    /// @return The role of the participant
    function getParticipant(address _participantAddress) external view returns (Role) {
        require(participants[_participantAddress].isRegistered, "Query Error: Participant not registered");
        return participants[_participantAddress].role;
    }

    /// @notice Remove an existing participant from the registry
    /// @param _participantAddress The address of the participant to be removed
    function removeParticipant(address _participantAddress) external onlyApprovedRegistrar whenNotPaused {
        require(participants[_participantAddress].isRegistered, "Removal Error: Participant not registered");
        participants[_participantAddress].isRegistered = false;
        emit ParticipantRemoved(_participantAddress);
    }

    /// @notice Pause the contract to prevent certain operations
    function pauseContract() external onlyApprovedRegistrar {
        paused = true;
    }

    /// @notice Unpause the contract to resume operations
    function unpauseContract() external onlyApprovedRegistrar {
        paused = false;
    }
}
