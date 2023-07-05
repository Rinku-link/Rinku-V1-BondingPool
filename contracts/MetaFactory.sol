// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./CrowdContribution.sol";

contract MetaFactory is Ownable {
    using Create2 for bytes32;

    struct Pool {
        string name;
        bytes32 salt;
        address poolAddress;
    }

    Pool[] public pools;

    function createPool(string calldata _name, bytes32 _salt) external onlyOwner {
        address poolAddress = Create2.deploy(0, _salt, type(CrowdContribution).creationCode);
        pools.push(Pool({name: _name, salt: _salt, poolAddress: poolAddress}));
    }

    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }

    function getPoolsCount() external view returns (uint256) {
        return pools.length;
    }
}
