pragma solidity ^0.5.0;

contract MultiSignatureWallet {
    event Confirmation(address indexed sender, uint indexed transactionId);
    event ConfirmationRevoked(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Submission(uint indexed transactionId);

    struct Transaction {
        bool executed;
        address destination;
        uint value;
        bytes data;
    }
    
    address[] public owners;
    uint public required;
    mapping (address => bool) public isOwner;
    uint public transactionCount;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    

    /// @dev Fallback function, which accepts ether when sent to contract
    function() external payable {}

    /*
     * Modifiers
     */
    modifier checkOwner(address owner) {
        require(isOwner[msg.sender]);
        _;
    }
    
    modifier transactionPending(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (_required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }
    

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required) public
        validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }    
        owners = owners;
        required = _required;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data) public checkOwner(msg.sender) returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public checkOwner(msg.sender) {
        require(transactions[transactionId].destination != address(0));
        require(!confirmations[transactionId][msg.sender]);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public checkOwner(msg.sender) transactionPending(transactionId) {
        emit ConfirmationRevoked(msg.sender, transactionId);
        confirmations[transactionId][msg.sender] = false;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public transactionPending(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage t = transactions[transactionId];
            t.executed = true;
            (bool success, ) = t.destination.call.value(t.value)(t.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                t.executed = false;
            }
        }
    }

		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) internal view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data) internal returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }
}