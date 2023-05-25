// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBlpReward.sol";

contract BlpToken is ERC20, Ownable {
    IERC20 public joyToken;
    uint256 public initialBlpPrice;
    uint256 private k_inverse;
    uint256 public initialReserve;
    bool public transferEnabled;
    address private master;
    IBlpReward private blpReward;
    bool private emergencyPaused;
    bool private finished;
    bool public initialized;
    uint256 public platformFeeIncentiveRatio;

    constructor() ERC20("BlpToken", "BLP") {
        initialized = false;
    }

    function initialize(
        address _joyToken,
        uint256 _initialBlpPrice,
        uint256 _initialJoyReserve,
        uint256 _initialBlpMint,
        address _master,
        address _blpReward
    ) public {
        require(!initialized, "Already initialized");
        require(joyToken.transferFrom(msg.sender, address(this), _initialJoyReserve), "Initial JoyToken transfer failed");
        
        initialized = true;
        joyToken = IERC20(_joyToken);
        
        k_inverse = 3   ; // initial k is 1/3
        initialBlpPrice = _initialBlpPrice;
        transferEnabled = false;
        master = _master;
        blpReward = IBlpReward(_blpReward);
        emergencyPaused = false;
        finished = false;
        platformFeeIncentiveRatio = 100; // ten percent in terms of 1000 scale: 100/1000

        // Transfer the initial JoyToken reserve from the creator to the contract
        _mint(msg.sender, _initialBlpMint);
    }

    modifier onlyOwnerOrMaster() {
        require(msg.sender == owner() || msg.sender == master, "Caller is not the owner or master");
        _;
    }

    function enableTransfer() public onlyOwnerOrMaster {
        transferEnabled = true;
    }
    // mintBlp need to be executed in the next block
    function mintBlp(uint256 joyAmount) public {
        require(joyToken.balanceOf(msg.sender) >= joyAmount, "Insufficient Joy balance");
        require(!emergencyPaused, "Minting is paused due to emergency");
        require(!finished, "Minting is paused due to it's already finished");
        // reduce platformfee first
        uint256 R0 = this.getJoyTokenBalance();
        uint256 S0 = this.getTotalSupply();
        uint256 platformFee = joyAmount / 100;
        joyAmount = joyAmount - platformFee;
        uint256 blpAmount = S0 * ((1 + joyAmount / R0)**(1/k_inverse) - 1);
        uint256 userAmount = blpAmount;
        joyToken.transferFrom(msg.sender, address(this), joyAmount);
        _mint(msg.sender, userAmount);

        // platformFee handling logic
        uint256 platformFeeParticipant = platformFee * (platformFeeIncentiveRatio/1000);
        uint256 platformFeeMaster = platformFee - platformFeeParticipant;
        joyToken.transferFrom(address(this), master, platformFeeMaster);
        blpReward.depositPlatformFees(platformFeeParticipant);
    }

    //master address mint without joy consumed

    function burnBlp(uint256 blpAmount) public {
        require(balanceOf(msg.sender) >= blpAmount, "Insufficient BLP balance");
        require(!emergencyPaused, "Burning is paused due to emergency");
        require(!finished, "Burning is paused due to it's already finished");
        uint256 R0 = this.getJoyTokenBalance();
        uint256 S0 = this.getTotalSupply();
        uint256 joyAmount = R0 * ((1 + blpAmount / S0)**(k_inverse) - 1);
        uint256 platformFee = joyAmount / 100;
        uint256 userAmount = joyAmount - platformFee;
        _burn(msg.sender, blpAmount);
        joyToken.transfer(msg.sender, userAmount);

        // platformFee handling logic
        uint256 platformFeeParticipant = platformFee * (platformFeeIncentiveRatio/1000);
        uint256 platformFeeMaster = platformFee - platformFeeParticipant;
        joyToken.transferFrom(address(this), master, platformFeeMaster);
        blpReward.depositPlatformFees(platformFeeParticipant);
    }

    function add_reserve(uint256 joyAmount) public onlyOwnerOrMaster {
        uint256 R0 = this.getJoyTokenBalance();
        uint256 S0 = this.getTotalSupply();
        // Transfer JoyToken from the user to the contract
        require(joyToken.transferFrom(msg.sender, address(this), joyAmount), "JoyToken transfer failed");
        uint256 R1 = this.getJoyTokenBalance();
        // Update the reserve ratio K
        uint256 price = (R0 * k_inverse) / (S0);
        k_inverse = (price * S0) / R1;
    }

    function withdrawJoyTokens(uint256 amount) external onlyOwnerOrMaster {
        uint256 contractBalance = joyToken.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient joy token balance");

        joyToken.transfer(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(transferEnabled || from == address(0) || to == address(0), "Transfers disabled");
    }

    function getJoyTokenBalance() public view returns (uint256) {
        return joyToken.balanceOf(address(this));
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function pauseEmergency() public onlyOwnerOrMaster {
        emergencyPaused = true;
    }

    function resumeFromEmergency() public onlyOwnerOrMaster {
        emergencyPaused = false;
    }

    function finishBlp() public onlyOwnerOrMaster {
        finished = true;
    }

    function resumeBlp() public onlyOwnerOrMaster {
        finished = false;
    }

    function setPlatformFeeIncentiveRatio(uint256 _platformFeeIncentiveRatio) public onlyOwnerOrMaster {
        platformFeeIncentiveRatio = _platformFeeIncentiveRatio;
    }
}
