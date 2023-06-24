// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./PoolManagement.sol";

contract UserContribution is Ownable {
    PoolManagement public poolManagement;
    address public poolCompletionAddress;
    mapping(uint256 => address[]) public addressIndices;
    mapping(uint256 => mapping(address => uint256)) public poolContributions;

    constructor(PoolManagement _poolManagement) {
        poolManagement = _poolManagement;
    }

    function contributeToPool(
        uint256 _poolId,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        require(_poolId < poolManagement.poolsCount(), "Invalid pool ID");

        PoolManagement.PoolStatus status;
        uint256 minContribution;
        uint256 maxContribution;
        bytes32 merkleRoot;
        (, status, , merkleRoot) = poolManagement.getPool(_poolId);
        
        require(_amount >= minContribution, "Contribution less than minimum allowed");
        require(_amount <= maxContribution, "Contribution more than maximum allowed");     
        require(
            status == PoolManagement.PoolStatus.CANCELLED || status == PoolManagement.PoolStatus.COMPLETED,
            "Pool is not cancelled or completed"
        );

        // Verify the user's Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not in the whitelist"
        );

        // verify address has enough joy token
        IERC20 joyToken = poolManagement.joyToken();
        require(joyToken.balanceOf(msg.sender) >= _amount, "Insufficient Joy balance");
        joyToken.transferFrom(msg.sender, address(this), _amount);

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

    function claimPoolContribution(uint256 _poolId) external {
        require(_poolId < poolManagement.poolsCount(), "Invalid pool ID");

        PoolManagement.PoolStatus status;
        (, status, , ) = poolManagement.getPool(_poolId);
        
        require(
            status == PoolManagement.PoolStatus.CANCELLED,
            "Pool is not cancelled"
        );
        
        uint256 refundAmount = poolContributions[_poolId][msg.sender];
        require(refundAmount > 0, "No contribution found or already claimed");
        poolContributions[_poolId][msg.sender] = 0;

        poolManagement.updatePoolBalance(_poolId, -(int256(refundAmount)));

        IERC20 joyToken = poolManagement.joyToken();
        joyToken.transfer(msg.sender, refundAmount);
    }

    function getAddressIndicesLength(uint256 _poolId) external view returns (uint256) {
        return addressIndices[_poolId].length;
    }

    function setPoolCompletionAddress(address _poolCompletionAddress) external onlyOwner {
        poolCompletionAddress = _poolCompletionAddress;
    }

    function updatePoolContribution(uint256 _poolId, address _contributor, uint256 _newContribution) external {
        // Add a require statement here to check that the caller is PoolCompletion
        require(msg.sender == poolCompletionAddress, "Only PoolCompletion can call this function");
        poolContributions[_poolId][_contributor] = _newContribution;
    }

    function getAddressIndex(uint256 _poolId, uint256 _index) external view returns (address) {
        return addressIndices[_poolId][_index];
    }

    function getAddressIndicesCount(uint256 _poolId) external view returns (uint256) {
        return addressIndices[_poolId].length;
    }

    function getPoolContribution(uint256 _poolId, address _contributor) public view returns (uint256) {
        return poolContributions[_poolId][_contributor];
    }
}
