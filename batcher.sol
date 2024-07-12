// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

// ERC20 Interface
interface iERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface iROUTER {
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string memory memo,
        uint expiration
    ) external payable;
}

interface iCHAINFLIP_VAULT {
    function xSwapNative(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata cfParameters
    ) external payable;
}

contract ThorchainMayaChainflipAggregator {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address private constant ETH = address(0);
    address public owner;
    address public cfVault; 

    mapping(address => bool) public approvedRouters;

    event SwapExecuted(string protocol, uint256 amount, string memo);

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

    constructor(address _cfVault) {
        _status = _NOT_ENTERED;
        cfVault = _cfVault;
        owner = msg.sender;
    }

    receive() external payable {}

    function approveRouter(address router) public onlyOwner {
        approvedRouters[router] = true;
    }

    function revokeRouterApproval(address router) public onlyOwner {
        approvedRouters[router] = false;
    }

    // function swapEthDirect(
    //     address vault,
    //     address router,
    //     string memory memo,
    //     bool isMaya
    // ) public payable nonReentrant {
    //     require(approvedRouters[router], "Router not approved");
    //     require(msg.value > 0, "No ETH sent");

    //     iROUTER(router).depositWithExpiry{value: msg.value}(
    //         payable(vault),
    //         ETH,
    //         msg.value,
    //         memo,
    //         block.timestamp + 1 hours
    //     );

    //     emit SwapExecuted(isMaya ? "Maya" : "THORChain", msg.value, memo);
    // }

    // function swapViaChainflip(
    //     uint32 dstChain,
    //     bytes calldata dstAddress,
    //     uint32 dstToken
    // ) public payable nonReentrant {
    //     require(msg.value > 0, "No ETH sent");

    //     iCHAINFLIP_VAULT(cfVault).xSwapNative{value: msg.value}(
    //         dstChain,
    //         dstAddress,
    //         dstToken
    //     );
    // }
//     function swapViaChainflip(
//     uint32 dstChain,
//     bytes calldata dstAddress,
//     uint32 dstToken,
//      bytes calldata cfParameters
// ) public payable nonReentrant {
//     require(msg.value > 0, "No ETH sent");
//     require(cfVault != address(0), "Chainflip vault address not set");
    
//     // Add a try-catch block to get more information about the revert reason
//     try iCHAINFLIP_VAULT(cfVault).xSwapNative{value: msg.value}(
//         dstChain,
//         dstAddress,
//         dstToken,
//         cfParameters
//     ) {
//         // Swap successful
//         emit SwapExecuted("Chainflip", msg.value, "");
//     } catch Error(string memory reason) {
//         // Revert with the reason string
//         revert(string(abi.encodePacked("Chainflip swap failed: ", reason)));
//     } catch (bytes memory lowLevelData) {
//         // Revert with a generic message for low-level errors
//         revert("Chainflip swap failed due to low-level error");
//     }
// }

     struct ThorMayaParams {
        address vault;
        address router;
        string memo;
        bool isMaya;
    }

    struct ChainflipParams {
        uint32 dstChain;
        bytes dstAddress;
        uint32 dstToken;
        bytes cfParameters;
    }

    function swapEthBoth(
        ThorMayaParams memory thorMayaParams,
        ChainflipParams memory chainflipParams,
        uint256 thorMayaPercentage
    ) public payable nonReentrant {
        require(approvedRouters[thorMayaParams.router], "Router not approved");
        require(msg.value > 0, "No ETH sent");
        require(thorMayaPercentage <= 100, "Invalid percentage");

        uint256 thorMayaAmount = (msg.value * thorMayaPercentage) / 100;
        uint256 chainflipAmount = msg.value - thorMayaAmount;

        _swapThorMaya(thorMayaParams, thorMayaAmount);
        _swapChainflip(chainflipParams, chainflipAmount);
    }
        function _swapThorMaya(ThorMayaParams memory params, uint256 amount) internal {
        if (amount > 0) {
            iROUTER(params.router).depositWithExpiry{value: amount}(
                payable(params.vault),
                ETH,
                amount,
                params.memo,
                block.timestamp + 10 minutes
            );
            emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", amount, params.memo);
        }
    }

    function _swapChainflip(ChainflipParams memory params, uint256 amount) internal {
        if (amount > 0) {
            iCHAINFLIP_VAULT(cfVault).xSwapNative{value: amount}(
                params.dstChain,
                params.dstAddress,
                params.dstToken,
                params.cfParameters
            );
            emit SwapExecuted("Chainflip", amount, string(params.cfParameters));
        }
    }

    //     function swapEth(
    //     address thorVault,
    //     address thorRouter,
    //     address mayaVault,
    //     address mayaRouter,
    //     string memory thorMemo,
    //     string memory mayaMemo,
    //     uint256 thorPercentage
    // ) public payable nonReentrant {
    //     require(approvedRouters[thorRouter] && approvedRouters[mayaRouter], "One or both routers not approved");
    //     require(msg.value > 0, "No ETH sent");

    //     uint256 thorAmount = (msg.value * thorPercentage) / 100;
    //     uint256 mayaAmount = msg.value - thorAmount;

    //     iROUTER(thorRouter).depositWithExpiry{value: thorAmount}(
    //         payable(thorVault),
    //         ETH,
    //         thorAmount,
    //         thorMemo,
    //         block.timestamp + 5 minutes
    //     );
        
    //     iROUTER(mayaRouter).depositWithExpiry{value: mayaAmount}(
    //         payable(mayaVault),
    //         ETH,
    //         mayaAmount,
    //         mayaMemo,
    //         block.timestamp + 5 minutes
    //     );

    //     emit SwapExecuted("THORChain", thorAmount, thorMemo);
    //     emit SwapExecuted("Maya", mayaAmount, mayaMemo);
    // }

    // function swapEthSingle(
    //     address vault,
    //     address router,
    //     string memory memo,
    //     bool isMaya
    // ) public payable nonReentrant {
    //     require(approvedRouters[router], "Router not approved");
    //     require(msg.value > 0, "No ETH sent");

    //     iROUTER(router).depositWithExpiry{value: msg.value}(
    //         payable(vault),
    //         ETH,
    //         msg.value,
    //         memo,
    //         block.timestamp + 5 minutes
    //     );

    //     emit SwapExecuted(isMaya ? "Maya" : "THORChain", msg.value, memo);
    // }


    // function swapIn(SwapParams memory params) public nonReentrant {
    //     require(approvedRouters[params.thorRouter] && approvedRouters[params.mayaRouter], "One or both routers not approved");
    //     require(approvedRouters[params.swapRouter], "Swap router not approved");

    //     uint256 _safeAmount = safeTransferFrom(params.token, params.amount);
    //     safeApprove(params.token, params.swapRouter, _safeAmount);

    //     uint256 ethAmount = performSwap(params);
    //     splitAndDeposit(params, ethAmount);
    // }

    // function performSwap(SwapParams memory params) internal returns (uint256) {
    //     address[] memory path = new address[](2);
    //     path[0] = params.token;
    //     path[1] = params.weth;
    //     iSWAPROUTER(params.swapRouter).swapExactTokensForETH(
    //         params.amount,
    //         params.amountOutMin,
    //         path,
    //         address(this),
    //         params.deadline
    //     );
        
    //     return address(this).balance;
    // }

    // function splitAndDeposit(SwapParams memory params, uint256 totalEth) internal {
    //     uint256 thorAmount = (totalEth * params.thorPercentage) / 100;
    //     uint256 mayaAmount = totalEth - thorAmount;
        
    //     iROUTER(params.thorRouter).depositWithExpiry{value: thorAmount}(
    //         payable(params.thorVault),
    //         ETH,
    //         thorAmount,
    //         params.thorMemo,
    //         params.deadline
    //     );
        
    //     iROUTER(params.mayaRouter).depositWithExpiry{value: mayaAmount}(
    //         payable(params.mayaVault),
    //         ETH,
    //         mayaAmount,
    //         params.mayaMemo,
    //         params.deadline
    //     );
    // }

    function safeTransferFrom(address _asset, uint _amount) internal returns (uint amount) {
        uint _startBal = iERC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amount
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Token transfer failed");
        return (iERC20(_asset).balanceOf(address(this)) - _startBal);
    }

    function safeApprove(address _asset, address _address, uint _amount) internal {
        (bool success, ) = _asset.call(
            abi.encodeWithSignature("approve(address,uint256)", _address, 0)
        );
        require(success, "Approve reset failed");

        (success, ) = _asset.call(
            abi.encodeWithSignature("approve(address,uint256)", _address, _amount)
        );
        require(success, "Approve failed");
    }

    function rescueFunds(address asset, uint256 amount, address destination) public onlyOwner {
        if (asset == address(0)) {
            payable(destination).transfer(amount);
        } else {
            (bool success, ) = asset.call(
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    destination,
                    amount
                )
            );
            require(success, "Transfer failed");
        }
    }
}