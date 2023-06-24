// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Define the PoolCompletionDetails struct in a separate contract or library
contract PoolCompletionDetailsLib {
    struct PoolCompletionDetails {
        uint256 poolId;
        uint256 initialBlpPrice;
        uint256 initialJoyReserve;
        uint256 initialBlpMint;
        address master_address;
    }
}
