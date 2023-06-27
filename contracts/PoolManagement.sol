// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolManagement is Ownable {
    enum PoolStatus { FUNDING, COMPLETED, CANCELLED }

    struct Pool {
        string name;
        PoolStatus status;
        uint256 balance;
        uint256 minContribution;
        uint256 maxContribution;
        bytes32 merkleRoot;
    }

    IERC20 public joyToken;
    Pool[] public pools;

    constructor(IERC20 _joyToken) {
        joyToken = _joyToken;
    }

    function createPool(string calldata _name, uint256 _minContribution, uint256 _maxContribution, bytes32 _merkleRoot) external onlyOwner {
        pools.push(Pool({
            name: _name, 
            status: PoolStatus.FUNDING, 
            balance: 0, 
            minContribution: _minContribution, 
            maxContribution: _maxContribution, 
            merkleRoot: _merkleRoot
        }));
    }

    function setMerkleRoot(uint256 _poolId, bytes32 _newMerkleRoot) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        pools[_poolId].merkleRoot = _newMerkleRoot;
    }

    function setPoolStatus(uint256 _poolId, string memory _status) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");

        PoolStatus status;
        if (compareStrings(_status, "FUNDING")) {
            status = PoolStatus.FUNDING;
        } else if (compareStrings(_status, "COMPLETED")) {
            status = PoolStatus.COMPLETED;
        } else if (compareStrings(_status, "CANCELLED")) {
            status = PoolStatus.CANCELLED;
        } else {
            revert("Invalid pool status");
        }

        pools[_poolId].status = status;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // New getter functions
    function getPool(uint256 _poolId) external view returns (string memory, PoolStatus, uint256, bytes32) {
        require(_poolId < pools.length, "Invalid pool ID");
        Pool memory pool = pools[_poolId];
        return (pool.name, pool.status, pool.balance, pool.merkleRoot);
    }

    function poolsCount() external view returns (uint256) {
        return pools.length;
    }

    function updatePoolBalance(uint256 _poolId, int256 _delta) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        if (_delta < 0) {
            require(pools[_poolId].balance >= uint256(-_delta), "Insufficient pool balance");
        }
        pools[_poolId].balance += uint256(_delta);
    }
}
