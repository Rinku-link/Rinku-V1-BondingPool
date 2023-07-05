// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Import the MerkleProof library

contract CrowdContribution is Ownable {
    enum PoolStatus { FUNDING, COMPLETED, CANCELLED }

    struct Contribution {
        address contributor;
        uint256 amount;
    }

    bool public initialized = false;
    PoolStatus public status;
    IERC20 public joyToken;
    uint256 public min;
    uint256 public max;
    uint256 public hardcap;
    bytes32 public root; // The root of the Merkle Tree
    uint256 public totalContribution;
    Contribution[] public contributions;

    function initialize(
        IERC20 _joyToken,
        uint256 _min,
        uint256 _max,
        uint256 _hardcap,
        bytes32 _root // Add the root of the Merkle Tree as a parameter
    ) public {
        require(!initialized, "Contract has already been initialized");
        initialized = true;

        joyToken = _joyToken;
        min = _min;
        max = _max;
        hardcap = _hardcap;
        root = _root; // Initialize the root of the Merkle Tree
        totalContribution = 0;
        status = PoolStatus.FUNDING;
    }

    function contribute(uint256 _amount, bytes32[] calldata _merkleProof) external {
        require(status == PoolStatus.FUNDING, "Pool is not in funding status");
        require(_amount >= min && _amount <= max, "Contribution amount is out of range");
        require(joyToken.balanceOf(msg.sender) >= _amount, "Insufficient Joy balance");

        // Verify the Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Not in the whitelist");

        totalContribution += _amount;
        contributions.push(Contribution({contributor: msg.sender, amount: _amount}));

        joyToken.transferFrom(msg.sender, address(this), _amount);

        if (totalContribution >= hardcap) {
            status = PoolStatus.COMPLETED;
        }
    }

    function setPoolStatus(PoolStatus _status) external onlyOwner {
        status = _status;
    }

    function getContributionsCount() external view returns (uint256) {
        return contributions.length;
    }

    function getContribution(uint256 _index) external view returns (Contribution memory) {
        return contributions[_index];
    }
}
