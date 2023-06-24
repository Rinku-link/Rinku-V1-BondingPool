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
        bytes32 merkleRoot;
    }

    IERC20 public joyToken;
    Pool[] public pools;

    constructor(IERC20 _joyToken) {
        joyToken = _joyToken;
    }

    function createPool(string calldata _name, bytes32 _merkleRoot) external onlyOwner {
        pools.push(Pool({name: _name, status: PoolStatus.FUNDING, balance: 0, merkleRoot: _merkleRoot}));
    }

    function setMerkleRoot(uint256 _poolId, bytes32 _newMerkleRoot) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        pools[_poolId].merkleRoot = _newMerkleRoot;
    }

    function setPoolStatus(uint256 _poolId, PoolStatus _status) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        pools[_poolId].status = _status;
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

    function joyToken() external view returns (IERC20) {
        return joyToken;
    }

    function updatePoolBalance(uint256 _poolId, int256 _delta) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        if (_delta < 0) {
            require(pools[_poolId].balance >= uint256(-_delta), "Insufficient pool balance");
        }
        pools[_poolId].balance += uint256(_delta);
    }
}
