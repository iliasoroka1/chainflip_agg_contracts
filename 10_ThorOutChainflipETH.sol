// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./SafeTransferLib.sol";

interface iERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface iCHAINFLIP_VAULT {
    function xSwapNative(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata cfParameters
    ) external payable;
}

contract THORChainOutARB {
    using SafeTransferLib for address;

    address private constant ETH = address(0);
    address public immutable WETH;
    iCHAINFLIP_VAULT public immutable chainflipVault;
    address public owner;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Chainflip Asset Mapping
    mapping(address => uint32) public assetToChainflipID;

    // Chainflip Chain Mapping 
    mapping(uint32 => uint32) public assetToChainID;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _weth, address _chainflipVault) {
        WETH = _weth;
        chainflipVault = iCHAINFLIP_VAULT(_chainflipVault);
        owner = msg.sender;
        _status = _NOT_ENTERED;

        // Initialize asset mappings
        assetToChainflipID[address(0x2222222222222222222222222222222222222222)] = 4; // DOT (placeholder address)
        assetToChainflipID[address(0x3333333333333333333333333333333333333333)] = 5; // BTC (placeholder address)
        assetToChainflipID[address(0x912CE59144191C1204E64559FE8253a0e49E6548)] = 6; // arbETH
        assetToChainflipID[address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8)] = 7; // arbUSDC
        assetToChainflipID[address(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = 8; // USDT

        // Initialize chain mappings based on asset ID
        assetToChainID[4] = 2; // DOT -> Polkadot
        assetToChainID[5] = 3; // BTC -> Bitcoin
        assetToChainID[6] = 4; // arbETH -> Arbitrum
        assetToChainID[7] = 4; // arbUSDC -> Arbitrum
        assetToChainID[8] = 4; // USDT -> Arbitrum (assuming USDT is on Arbitrum in this case)
    }

    receive() external payable {}

    function swapOut(
        address token,
        address to,
        uint256 amountOutMin
    ) public payable nonReentrant {
        uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");

            uint32 dstToken = assetToChainflipID[token];
            require(dstToken != 0, "Unsupported token");

            uint32 dstChain = assetToChainID[dstToken];
            require(dstChain != 0, "Unsupported destination chain");

            chainflipVault.xSwapNative{value: amount}(
                dstChain,
                abi.encodePacked(to),
                dstToken,
                "" 
            );

        emit SwapOut(token, to, amount, amountOutMin);
    }

    function rescueFunds(
        address asset,
        uint256 amount,
        address destination
    ) public onlyOwner {
        if (asset == ETH) {
            (bool success, ) = payable(destination).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            asset.safeTransfer(destination, amount);
        }
    }

    event SwapOut(address indexed token, address indexed to, uint256 amount, uint256 amountOutMin);
}