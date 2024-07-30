// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./SafeTransferLib.sol";

interface iERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface iUNISWAP {
    function WETH() external view returns (address);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract THOROutETH {
    using SafeTransferLib for address;

    address private constant ETH = address(0);
    address public immutable WETH;
    iUNISWAP public immutable swapRouter;
    address public owner;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

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

    constructor(address _weth, address _swapRouter) {
        WETH = _weth;
        swapRouter = iUNISWAP(_swapRouter);
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }

    receive() external payable {}

function swapOut(
    address token,
    address to,
    uint256 amountOutMin
) public payable nonReentrant {
    uint256 amount = msg.value;
    require(amount > 0, "Must send ETH");

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = token;

    // Perform the swap for both ETH and non-ETH cases
    uint[] memory amounts = swapRouter.swapExactETHForTokens{value: amount}(
        amountOutMin,
        path,
        to,
        type(uint).max
    );

    // Check if the swap met the minimum output requirement
    require(amounts[1] >= amountOutMin, "Insufficient output amount");

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