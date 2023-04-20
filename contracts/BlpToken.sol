pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlpToken is ERC20, Ownable {
    IERC20 public joyToken;
    uint256 public initialBlpPrice;
    uint256 private k_inverse;
    uint256 public initialReserve;
    bool public transferEnabled;
    address private master;
    bool private emergencyPaused;
    bool public initialized;

    constructor() ERC20("BlpToken", "BLP") {
        initialized = false;
    }

    function initialize(
        uint256 _initialBlpPrice,
        uint256 _initialJoyReserve,
        uint256 _initialBlpMint,
        address _master
    ) public {
        require(!initialized, "Already initialized");
        require(joyToken.transferFrom(msg.sender, address(this), _initialJoyReserve), "Initial JoyToken transfer failed");
        initialized = true;
        
        k_inverse = 3   ; // initial k is 1/3
        initialBlpPrice = _initialBlpPrice;
        transferEnabled = false;
        master = _master;
        emergencyPaused = false;
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
        // reduce platformfee first
        uint256 R0 = this.getJoyTokenBalance();
        uint256 S0 = this.getTotalSupply();
        uint256 platformFee = joyAmount / 100;
        joyAmount = joyAmount - platformFee;
        uint256 blpAmount = S0 * ((1 + joyAmount / R0)**(1/k_inverse) - 1);
        uint256 userAmount = blpAmount;
        joyToken.transferFrom(msg.sender, address(this), joyAmount);
        _mint(msg.sender, userAmount);
    }

    function burnBlp(uint256 blpAmount) public {
        require(balanceOf(msg.sender) >= blpAmount, "Insufficient BLP balance");
        require(!emergencyPaused, "Burning is paused due to emergency");
        uint256 R0 = this.getJoyTokenBalance();
        uint256 S0 = this.getTotalSupply();
        uint256 joyAmount = R0 * ((1 + blpAmount / S0)**(k_inverse) - 1);
        uint256 platformFee = joyAmount / 100;
        uint256 userAmount = joyAmount - platformFee;
        _burn(msg.sender, blpAmount);
        joyToken.transfer(msg.sender, userAmount);
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

    function pauseEmergency() public onlyOwner {
        emergencyPaused = true;
    }

    function resumeFromEmergency() public onlyOwner {
        emergencyPaused = false;
    }
}
