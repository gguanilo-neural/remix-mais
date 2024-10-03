// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Payment Management Contract - Supply Chain Management System
/// @notice This contract manages payments between participants of a supply chain with escrow functionality.
/// @dev Payments are securely managed, including conditional releases and escrow mechanisms.

contract PaymentManagement {
    
    // Enum to define the possible status of a payment
    enum PaymentStatus { Pending, Released, Cancelled }

    // Struct to define payment details
    struct Payment {
        uint256 paymentId;
        address payer;
        address payee;
        uint256 amount;
        PaymentStatus status;
        uint256 timestamp;
        bool isRegistered;
    }

    // Mapping to store payments
    mapping(uint256 => Payment) private payments;

    // Mapping to store addresses approved for managing payments
    mapping(address => bool) private approvedManagers;

    // Event emitted when a payment is created
    event PaymentCreated(uint256 indexed paymentId, address indexed payer, address indexed payee, uint256 amount);

    // Event emitted when a payment is released
    event PaymentReleased(uint256 indexed paymentId, address indexed payee, uint256 amount);

    // Event emitted when a payment is cancelled
    event PaymentCancelled(uint256 indexed paymentId, address indexed payer);

    // Event emitted when a manager is approved
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

    // Modifier to ensure the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Operation Error: Contract is paused");
        _;
    }

    // Modifier to ensure a payment is registered
    modifier isRegisteredPayment(uint256 _paymentId) {
        require(payments[_paymentId].isRegistered, "Query Error: Payment not registered");
        _;
    }

    // Constructor to assign the contract creator as the initial manager
    constructor() {
        approvedManagers[msg.sender] = true;
        emit ManagerApproved(msg.sender);
    }

    /// @notice Approve a new manager for payment management
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

    /// @notice Create a new payment and put it in escrow
    /// @param _paymentId The unique ID of the payment
    /// @param _payee The address of the payee
    /// @param _amount The amount of payment (in wei)
    function createPayment(uint256 _paymentId, address _payee, uint256 _amount) 
        external payable whenNotPaused 
    {
        require(!payments[_paymentId].isRegistered, "Creation Error: Payment already exists");
        require(_payee != address(0), "Creation Error: Invalid payee address");
        require(msg.value == _amount, "Creation Error: Incorrect payment amount");

        payments[_paymentId] = Payment({
            paymentId: _paymentId,
            payer: msg.sender,
            payee: _payee,
            amount: _amount,
            status: PaymentStatus.Pending,
            timestamp: block.timestamp,
            isRegistered: true
        });

        emit PaymentCreated(_paymentId, msg.sender, _payee, _amount);
    }

    /// @notice Release a payment from escrow when conditions are met
    /// @param _paymentId The unique ID of the payment
    function releasePayment(uint256 _paymentId) 
        external onlyApprovedManager isRegisteredPayment(_paymentId) whenNotPaused 
    {
        Payment storage payment = payments[_paymentId];
        require(payment.status == PaymentStatus.Pending, "Release Error: Payment not in pending status");

        payment.status = PaymentStatus.Released;
        payable(payment.payee).transfer(payment.amount);

        emit PaymentReleased(_paymentId, payment.payee, payment.amount);
    }

    /// @notice Cancel a payment and return funds to the payer
    /// @param _paymentId The unique ID of the payment
    function cancelPayment(uint256 _paymentId) 
        external onlyApprovedManager isRegisteredPayment(_paymentId) whenNotPaused 
    {
        Payment storage payment = payments[_paymentId];
        require(payment.status == PaymentStatus.Pending, "Cancellation Error: Payment not in pending status");

        payment.status = PaymentStatus.Cancelled;
        payable(payment.payer).transfer(payment.amount);

        emit PaymentCancelled(_paymentId, payment.payer);
    }

    /// @notice Get the details of a payment
    /// @param _paymentId The unique ID of the payment
    /// @return payer The address of the payer
    /// @return payee The address of the payee
    /// @return amount The amount of the payment
    /// @return status The current status of the payment (Pending, Released, or Cancelled)
    /// @return timestamp The time when the payment was created
    function getPayment(uint256 _paymentId) 
        external view isRegisteredPayment(_paymentId) 
        returns (address payer, address payee, uint256 amount, PaymentStatus status, uint256 timestamp) 
    {
        Payment memory payment = payments[_paymentId];
        return (payment.payer, payment.payee, payment.amount, payment.status, payment.timestamp);
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
