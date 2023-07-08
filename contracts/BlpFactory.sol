// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./BlpToken.sol";

contract BlpFactory {

    function createBlpToken(
        address _owner,
        bytes32 _salt,
        IERC20 _joyToken,
        uint256 _initialBlpPrice,
        uint256 _initialJoyReserve,
        uint256 _initialBlpMint,
        address _master,
        address _blpReward
    ) public returns (address) {
        bytes memory bytecode = type(BlpToken).creationCode;
        address blpTokenAddress = Create2.deploy(0, _salt, bytecode);

        BlpToken(blpTokenAddress).initialize(address(_joyToken), _initialBlpPrice, _initialJoyReserve, _initialBlpMint, _master, _blpReward);
        BlpToken(blpTokenAddress).transferOwnership(_owner);

        return blpTokenAddress;
    }
}
