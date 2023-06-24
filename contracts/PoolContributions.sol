// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PoolManagement.sol";
import "./UserContribution.sol";
import "./PoolCompletionDetailsLib.sol";

contract PoolContributions {

    function updateContributions(PoolCompletionDetailsLib.PoolCompletionDetails memory details, UserContribution userContribution, uint256 joyPerParticipant) external {
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
}
