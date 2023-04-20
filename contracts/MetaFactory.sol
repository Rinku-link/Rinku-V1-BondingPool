// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./BlpToken.sol"; // Import the BLPToken contract interface

contract MetaFactory is Ownable {
    using Create2 for bytes32;
    enum PoolStatus { FUNDING, COMPLETED, CANCELLED }

    struct Pool {
        string name;
        PoolStatus status;
        uint256 balance;
    }

    struct Contribution {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    IERC20 public joyToken;
    Pool[] public pools;
    mapping(uint256 => Contribution[]) public poolContributions;

    constructor(IERC20 _joyToken) {
        joyToken = _joyToken;
    }

    function createPool(string calldata _name) external onlyOwner {
        pools.push(Pool({name: _name, status: PoolStatus.FUNDING, balance: 0}));
    }

    function contributeToPool(uint256 _poolId, uint256 _amount) external {
        require(_poolId < pools.length, "Invalid pool ID");
        require(pools[_poolId].status == PoolStatus.FUNDING, "Pool is not in funding status");

        joyToken.transferFrom(msg.sender, address(this), _amount);

        pools[_poolId].balance += _amount;
        poolContributions[_poolId].push(Contribution(msg.sender, _amount, block.timestamp));
    }

    function setPoolStatus(uint256 _poolId, PoolStatus _status) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        pools[_poolId].status = _status;
    }

    function refundPoolContributions(uint256 _poolId) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        require(pools[_poolId].status == PoolStatus.CANCELLED, "Pool is not cancelled");

        Contribution[] storage contributions = poolContributions[_poolId];
        for (uint256 i = 0; i < contributions.length; i++) {
            joyToken.transfer(contributions[i].user, contributions[i].amount);
        }

        delete poolContributions[_poolId];
        pools[_poolId].balance = 0;
    }

    function completePool(
        uint256 _poolId,
        uint256 _initialBlpPrice,
        uint256 _initialJoyReserve,
        uint256 _initialBlpMint,
        address _master_address
    ) external onlyOwner {
        require(_poolId < pools.length, "Invalid pool ID");
        require(pools[_poolId].status == PoolStatus.FUNDING, "Pool is not in funding status");

        pools[_poolId].status = PoolStatus.COMPLETED;

        bytes32 salt = keccak256(abi.encodePacked(_poolId, pools[_poolId].name));
        address blpToken = address(
            Create2.deploy(0, salt, type(BlpToken).creationCode)
        );

        BlpToken(blpToken).initialize(
            _initialBlpPrice,
            _initialJoyReserve,
            _initialBlpMint,
            _master_address
        );
    }
}
