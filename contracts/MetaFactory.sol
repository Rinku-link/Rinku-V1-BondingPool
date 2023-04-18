// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BlpToken.sol"; // Import the BLPToken contract interface

contract MetaFactory is Ownable {
    enum PoolStatus { FUNDING, COMPLETED, CANCELLED }

    struct Pool {
        string name;
        PoolStatus status;
        uint256 balance;
        address blpToken; // Add the BLP token contract address to the Pool struct
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
        pools.push(Pool({name: _name, status: PoolStatus.FUNDING, balance: 0, blpToken: address(0)}));
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
        // Create a new BLP token contract and save its address in the Pool struct
        BlpToken newBlp = new BlpToken(_initialBlpPrice, _initialJoyReserve, _initialBlpMint, _master_address);
        pools[_poolId].blpToken = address(newBlp);
    }

    function getBlpAddressByPoolId(uint256 _poolId) external view returns (address) {
        require(_poolId < pools.length, "Invalid pool ID");
        return pools[_poolId].blpToken;
    }

    function getPoolNameById(uint256 _poolId) external view returns (string memory) {
        require(_poolId < pools.length, "Invalid pool ID");
        return pools[_poolId].name;
    }

    function getPoolBalanceById(uint256 _poolId) external view returns (uint256) {
        require(_poolId < pools.length, "Invalid pool ID");
        return pools[_poolId].balance;
    }

    function getPoolStatusById(uint256 _poolId) external view returns (PoolStatus) {
        require(_poolId < pools.length, "Invalid pool ID");
        return pools[_poolId].status;
    }
}
