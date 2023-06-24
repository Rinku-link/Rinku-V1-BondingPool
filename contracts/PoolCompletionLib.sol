// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PoolManagement.sol";
import "./UserContribution.sol";
import "./BlpToken.sol"; // Import the BLPToken contract interface
import "./BlpReward.sol"; // Import the BlpReward contract interface
import "@openzeppelin/contracts/utils/Create2.sol";

library PoolCompletionLib {

    using Create2 for bytes32;

    // Define a new struct to bundle parameters for the completePool function
    struct PoolCompletionDetails {
        uint256 poolId;
        uint256 initialBlpPrice;
        uint256 initialJoyReserve;
        uint256 initialBlpMint;
        address master_address;
    }

    function updateContributions(PoolCompletionDetails memory details, UserContribution userContribution, uint256 joyPerParticipant) internal {
        uint256 numParticipants = userContribution.getAddressIndicesLength(details.poolId);
        for (uint256 i = 0; i < numParticipants; i++) {
            address participantAddress = userContribution.getAddressIndex(details.poolId, i);
            uint256 participantContribution = userContribution.getPoolContribution(details.poolId, participantAddress);
            require(participantContribution >= joyPerParticipant, "Insufficient joy in pool contribution");
            if (participantContribution >= joyPerParticipant) {
                userContribution.updatePoolContribution(details.poolId, participantAddress, participantContribution - joyPerParticipant);
            } else {
                userContribution.updatePoolContribution(details.poolId, participantAddress, 0);
            }
        }
    }

    function deployContracts(PoolCompletionDetails memory details) internal returns (address blpReward, address blpToken) {
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
