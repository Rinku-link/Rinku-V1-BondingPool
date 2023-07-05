// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdContribution is Ownable {
    enum PoolStatus { FUNDING, COMPLETED, CANCELLED }

    struct Contribution {
        address contributor;
        uint256 amount;
    }

    PoolStatus public status;
    IERC20 public joyToken;
    uint256 public min;
    uint256 public max;
    uint256 public hardcap;
    bytes32 public root;
    uint256 public totalContribution;
    Contribution[] public contributions;

    constructor(
        IERC20 _joyToken,
        uint256 _min,
        uint256 _max,
        uint256 _hardcap,
        bytes32 _root
    ) {
        joyToken = _joyToken;
        min = _min;
        max = _max;
        hardcap = _hardcap;
        root = _root;
        status = PoolStatus.FUNDING;
        totalContribution = 0;
    }

    function contribute(uint256 _amount) external {
        require(status == PoolStatus.FUNDING, "Pool is not in funding status");
        require(_amount >= min && _amount <= max, "Contribution amount is out of range");
        require(joyToken.balanceOf(msg.sender) >= _amount, "Insufficient Joy balance");

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
