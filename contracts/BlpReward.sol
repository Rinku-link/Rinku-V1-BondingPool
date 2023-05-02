// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BlpReward {
    bool public initialized;
    IERC20 public blpToken;
    uint256 public constant EPOCH_LENGTH = 28 days;
    uint256 public lastDistributionTime;
    uint256 public totalPlatformFees;

    address[] public participantAddresses;
    mapping(address => uint256) public participantBalances;
    mapping(address => uint256) public pendingPlatformFees;

    constructor() {
        initialized = false;
    }

    function initialize(
        address _blpToken,
        address[] memory _participantAddresses,
        uint256[] memory _participantBalances
    ) external {
        require(!initialized, "Already initialized");
        require(_participantAddresses.length == _participantBalances.length, "Mismatched input lengths");
        initialized = true;
        blpToken = IERC20(_blpToken);
        for (uint256 i = 0; i < _participantAddresses.length; i++) {
            participantAddresses.push(_participantAddresses[i]);
            participantBalances[_participantAddresses[i]] = _participantBalances[i];
        }
        lastDistributionTime = block.timestamp;
    }

    function depositPlatformFees(uint256 _amount) external {
        blpToken.transferFrom(msg.sender, address(this), _amount);
        totalPlatformFees += _amount;
    }

    function distributePlatformFees() public {
        require(block.timestamp >= lastDistributionTime + EPOCH_LENGTH, "Not time to distribute yet");
        uint256 totalParticipantBalances;

        for (uint256 i = 0; i < participantAddresses.length; i++) {
            totalParticipantBalances += participantBalances[participantAddresses[i]];
        }

        for (uint256 i = 0; i < participantAddresses.length; i++) {
            uint256 participantShare = (participantBalances[participantAddresses[i]] * totalPlatformFees) / totalParticipantBalances;
            pendingPlatformFees[participantAddresses[i]] += participantShare;
        }

        lastDistributionTime = block.timestamp;
    }

    function claimPlatformFees() public {
        uint256 feesToClaim = pendingPlatformFees[msg.sender];
        require(feesToClaim > 0, "No platform fees to claim");

        pendingPlatformFees[msg.sender] = 0;
        blpToken.transfer(msg.sender, feesToClaim);
    }
}
