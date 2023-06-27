// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolManagement.sol";
import "./UserContribution.sol";
import "./PoolContributions.sol";
import "./PoolDeployer.sol";
import "./PoolCompletionDetailsLib.sol";

contract PoolCompletion is Ownable {
    PoolManagement public poolManagement;
    UserContribution public userContribution;
    PoolContributions public poolContributions;
    PoolDeployer public poolDeployer;

    constructor(PoolManagement _poolManagement, UserContribution _userContribution, PoolContributions _poolContributions, PoolDeployer _poolDeployer) {
        poolManagement = _poolManagement;
        userContribution = _userContribution;
        poolContributions = _poolContributions;
        poolDeployer = _poolDeployer;
    }

    function completePool(PoolCompletionDetailsLib.PoolCompletionDetails memory details) external onlyOwner {
        require(details.poolId < poolManagement.poolsCount(), "Invalid pool ID");
        // Fetch status from poolManagement
        PoolManagement.PoolStatus status;
        (, status, , ) = poolManagement.getPool(details.poolId);
        require(status == PoolManagement.PoolStatus.FUNDING, "Pool is not in funding status");
        uint256 joyPerParticipant = details.initialJoyReserve / userContribution.getAddressIndicesLength(details.poolId);
        poolContributions.updateContributions(details, userContribution, joyPerParticipant);
        poolManagement.setPoolStatus(details.poolId, "COMPLETED");
        (address blpReward, address blpToken) = poolDeployer.deployContracts(details);
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
