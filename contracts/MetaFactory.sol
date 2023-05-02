// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./BlpToken.sol"; // Import the BLPToken contract interface
import "./BlpReward.sol"; // Import the BlpReward contract interface

contract MetaFactory is Ownable {
    using Create2 for bytes32;
    enum PoolStatus { FUNDING, COMPLETED, CANCELLED }

    struct Pool {
        string name;
        PoolStatus status;
        uint256 balance;
        bytes32 merkleRoot;
    }

    IERC20 public joyToken;
    Pool[] public pools;
    mapping(uint256 => address[]) public addressIndices;
    mapping(uint256 => mapping(address => uint256)) public poolContributions;

    constructor(IERC20 _joyToken) {
        joyToken = _joyToken;
    }

    function createPool(string calldata _name, bytes32 _merkleRoot) external onlyOwner {
        pools.push(Pool({name: _name, status: PoolStatus.FUNDING, balance: 0, merkleRoot: _merkleRoot}));
    }

    function contributeToPool(
        uint256 _poolId,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        require(_poolId < pools.length, "Invalid pool ID");
        require(
            pools[_poolId].status == PoolStatus.CANCELLED || pools[_poolId].status == PoolStatus.COMPLETED,
            "Pool is not cancelled or completed"
        );

        // Verify the user's Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, pools[_poolId].merkleRoot, leaf),
            "Not in the whitelist"
        );

        // verify address has enough joy token
        require(joyToken.balanceOf(msg.sender) >= _amount, "Insufficient Joy balance");
        joyToken.transferFrom(msg.sender, address(this), _amount);

        pools[_poolId].balance += _amount;
        poolContributions[_poolId][msg.sender] += _amount;

        // Check if the participant's address is already in addressIndices
        bool isAddressPresent = false;
        for (uint256 i = 0; i < addressIndices[_poolId].length; i++) {
            if (addressIndices[_poolId][i] == msg.sender) {
                isAddressPresent = true;
                break;
            }
        }

        // If the participant's address is not present in addressIndices, add it
        if (!isAddressPresent) {
            addressIndices[_poolId].push(msg.sender);
        }
    }

    function setMerkleRoot(uint256 _poolId, bytes32 _newMerkleRoot) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        pools[_poolId].merkleRoot = _newMerkleRoot;
    }

    function setPoolStatus(uint256 _poolId, PoolStatus _status) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        pools[_poolId].status = _status;
    }

    function claimPoolContribution(uint256 _poolId) external {
        require(_poolId < pools.length, "Invalid pool ID");
        require(
            pools[_poolId].status == PoolStatus.CANCELLED || pools[_poolId].status == PoolStatus.COMPLETED,
            "Pool is not cancelled or completed"
        );
        uint256 refundAmount = poolContributions[_poolId][msg.sender];
        require(refundAmount > 0, "No contribution found or already claimed");
        poolContributions[_poolId][msg.sender] = 0;
        pools[_poolId].balance -= refundAmount;
        joyToken.transfer(msg.sender, refundAmount);
    }

    function completePool(
        uint256 _poolId,
        uint256 _initialBlpPrice,
        uint256 _initialJoyReserve,
        uint256 _initialBlpMint,
        address _master_address
    ) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        require(pools[_poolId].status == PoolStatus.FUNDING, "Pool is not in funding status");

        uint256 numParticipants = addressIndices[_poolId].length;
        uint256 joyPerParticipant = _initialJoyReserve / numParticipants;        
        address[] memory _participantAddresses = new address[](numParticipants);
        uint256[] memory _participantBalances = new uint256[](numParticipants);

        // Deduct joy from each participant's contribution in the pool
        for (uint256 i = 0; i < numParticipants; i++) {
            address participantAddress = addressIndices[_poolId][i];
    
            require(poolContributions[_poolId][participantAddress] >= joyPerParticipant, "Insufficient joy in pool contribution");
            
            _participantAddresses[i] = participantAddress;
            if (poolContributions[_poolId][participantAddress] >= joyPerParticipant) {
                _participantBalances[i] = joyPerParticipant;
                poolContributions[_poolId][participantAddress] -= joyPerParticipant;
            } else {
                _participantBalances[i] = poolContributions[_poolId][participantAddress];
                poolContributions[_poolId][participantAddress] = 0;
            }

            // Update the pool's balance and ensure it doesn't go below 0
            if (pools[_poolId].balance >= joyPerParticipant) {
                pools[_poolId].balance -= joyPerParticipant;
            } else {
                pools[_poolId].balance = 0;
            }
        }

        // add revenue sharing based on pool balance

        pools[_poolId].status = PoolStatus.COMPLETED;

        bytes32 salt1 = keccak256(abi.encodePacked(_poolId, pools[_poolId].name, "blpReward"));
        address blpReward = address(
            Create2.deploy(0, salt1, type(BlpReward).creationCode)
        );

        bytes32 salt2 = keccak256(abi.encodePacked(_poolId, pools[_poolId].name));
        address blpToken = address(
            Create2.deploy(0, salt2, type(BlpToken).creationCode)
        );

        BlpReward(blpReward).initialize(blpToken, _participantAddresses, _participantBalances);

        BlpToken(blpToken).initialize(
            address(joyToken),
            _initialBlpPrice,
            _initialJoyReserve,
            _initialBlpMint,
            _master_address,
            blpReward
        );
    }
}
