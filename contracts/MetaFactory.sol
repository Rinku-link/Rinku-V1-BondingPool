// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./CrowdContribution.sol"; // Import the CrowdContribution contract interface

contract MetaFactory is Ownable {
    using Create2 for bytes32;

    IERC20 public joyToken;
    address[] public pools;

    constructor(IERC20 _joyToken) {
        joyToken = _joyToken;
    }

    function createPool(
        string calldata _name,
        uint256 _min,
        uint256 _max,
        uint256 _hardcap,
        bytes32 _root // The root of the Merkle Tree
    ) external onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(_name));
        address poolAddress = Create2.deploy(0, salt, type(CrowdContribution).creationCode);
        CrowdContribution(poolAddress).initialize(joyToken, _min, _max, _hardcap, _root); // Initialize the CrowdContribution contract

        pools.push(poolAddress);
    }

    function getPoolsCount() external view returns (uint256) {
        return pools.length;
    }

    function getPool(uint256 _index) external view returns (address) {
        return pools[_index];
    }
}
