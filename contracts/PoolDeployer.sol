// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BlpToken.sol"; // Import the BLPToken contract interface
import "./BlpReward.sol"; // Import the BlpReward contract interface
import "./PoolCompletionDetailsLib.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract PoolDeployer {

    using Create2 for bytes32;

    function deployContracts(PoolCompletionDetailsLib.PoolCompletionDetails memory details) external returns (address blpReward, address blpToken) {
        bytes32 salt1 = keccak256(abi.encodePacked(details.poolId, "blpReward"));
        blpReward = address(
            Create2.deploy(0, salt1, type(BlpReward).creationCode)
        );

        bytes32 salt2 = keccak256(abi.encodePacked(details.poolId, "blpToken"));
        blpToken = address(
            Create2.deploy(0, salt2, type(BlpToken).creationCode)
        );

        return (blpReward, blpToken);
    }
}
