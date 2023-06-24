// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolCompletionLib.sol";

contract PoolCompletion is Ownable {
    PoolManagement public poolManagement;
    UserContribution public userContribution;

    constructor(PoolManagement _poolManagement, UserContribution _userContribution) {
        poolManagement = _poolManagement;
        userContribution = _userContribution;
    }

    function completePool(PoolCompletionLib.PoolCompletionDetails memory details) external onlyOwner {
        require(details.poolId < poolManagement.poolsCount(), "Invalid pool ID");
        // Fetch status from poolManagement
        PoolManagement.PoolStatus status;
        (, status, , ) = poolManagement.getPool(details.poolId);
        require(status == PoolManagement.PoolStatus.FUNDING, "Pool is not in funding status");
        uint256 joyPerParticipant = details.initialJoyReserve / userContribution.getAddressIndicesLength(details.poolId);
        PoolCompletionLib.updateContributions(details, userContribution, joyPerParticipant);
        poolManagement.setPoolStatus(details.poolId, PoolManagement.PoolStatus.COMPLETED);
        (address blpReward, address blpToken) = PoolCompletionLib.deployContracts(details);
        IERC20 joyToken = poolManagement.joyToken();
        BlpToken(blpToken).initialize(
            address(joyToken),
            details.initialBlpPrice,
            details.initialJoyReserve,
            details.initialBlpMint,
            details.master_address,
            blpReward
        );
    }
}
