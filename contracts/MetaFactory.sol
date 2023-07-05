// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./CrowdContribution.sol"; // Import the CrowdContribution contract

contract MetaFactory is Ownable {
    struct Pool {
        string name;
        CrowdContribution poolInstance;
    }

    Pool[] public pools;

    function createPool(
        string calldata _name,
        IERC20 _joyToken,
        uint256 _min,
        uint256 _max,
        uint256 _hardcap,
        bytes32 _root,
        bytes32 _salt
    ) external onlyOwner {
        bytes memory bytecode = type(CrowdContribution).creationCode;
        address poolAddress = Create2.deploy(0, _salt, bytecode);
        CrowdContribution(poolAddress).initialize(_joyToken, _min, _max, _hardcap, _root);
        pools.push(Pool({name: _name, poolInstance: CrowdContribution(poolAddress)}));
    }

    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }

    function getPoolsCount() external view returns (uint256) {
        return pools.length;
    }
}
