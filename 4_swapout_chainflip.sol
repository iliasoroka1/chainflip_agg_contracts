// SPDX-License-Identifier: GPL-3.0
//    . .::                        -++=-.-   
//   :-:=+#*+                   :*#=*+-.*.   
//   -#%*%@@@@*=.            .**%@@@#+#+#=   
//   =@@@*#@@@@@%=:        -**%@@@@#+%%##*   
//   -*@@@%@@@@@@@@+-    =*=@@@@@@*=%@@@*    
//    *@@@@%=+#@@@@@%+*++*%@@@@%+-+@@@@%+    
//    .#@@@@+   #@@@@@@+@@@@@%=   %@@@@%.    
//     =%@@@@    %@@@@@@@@@@@-   *@@@@%-     
//      +@@@@@.  =@@@@@@@@@@#   *@@@@#+      
//      .=%@@@@%%#@@@@@@@@%@+:-*@@@@%+       
//       .+@@@@@@%%@@@@@@@%+=*#%%@@#*        
//        .=+@%%%##*%@@@@@#=##*%@%*+         
//         .-*#@%@%*%#%@##+*####=+:          
//            .-++#+-==#*:-=++---.           
//              :    ..-:-::-=-:    
// .______        ___      .______   ____    ____  __        ______   .__   __.
// |   _  \      /   \     |   _  \  \   \  /   / |  |      /  __  \  |  \ |  |
// |  |_)  |    /  ^  \    |  |_)  |  \   \/   /  |  |     |  |  |  | |   \|  |
// |   _  <    /  /_\  \   |   _  <    \_    _/   |  |     |  |  |  | |  . `  |
// |  |_)  |  /  _____  \  |  |_)  |     |  |     |  `----.|  `--'  | |  |\   |
// |______/  /__/     \__\ |______/      |__|     |_______| \______/  |__| \__|  

pragma solidity >=0.8.2 <0.9.0;

import "./SafeTransferLib.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface iERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface iSUSHISWAP {
    function WETH() external view returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
}

interface iUNISWAP {
    function WETH() external view returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
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

interface ICHAINFLIP_LP{
    function fundStateChainAccount(
        bytes32 nodeID, 
        uint256 amount
        ) external;

    function executeRedemption(
        bytes32 nodeID) 
        external returns (address, uint256);
}

interface iCHAINFLIP_VAULT {
    function xCallNative(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata message,
        uint256 gasBudget,
        bytes calldata cfParameters
    ) external payable;

    function xCallToken(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        bytes calldata message,
        uint256 gasBudget,
        address srcToken,
        uint256 amount,
        bytes calldata cfParameters
    ) external;
}

contract ThorchainMayaChainflipCCMAggregator {
    iSUSHISWAP public sushiRouter;
    iUNISWAP public uniRouter;

    using SafeTransferLib for address;

    // Constants for reentrancy guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Constants for ETH addresses
    address private constant ETH = address(0);
    address private constant ETH_ALT = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public owner;
    address public cfVault; 

    // Enums for swap types and DEXes
    enum SwapType { ETH_TO_TOKEN, TOKEN_TO_TOKEN, TOKEN_TO_ETH }
    enum DEX { UNISWAP, SUSHISWAP, THORCHAIN, MAYA, CHAINFLIP }

    // Mapping to store approved routers
    mapping(address => bool) public approvedRouters;

    // Event declarations
    event SwapFailed(uint32 srcChain, bytes srcAddress, address token, uint256 amount, string reason);
    event SwapExecuted(string protocol, address token, uint256 amount, string memo);
    event CFReceive(
        uint32 srcChain,
        bytes srcAddress,
        address token,
        uint256 amount,
        address router,
        string memo
    );

    // Struct definitions for various swap parameters
    struct ThorMayaParams {
        address vault;
        address router;
        address token;
        uint256 amount;
        string memo;
        bool isMaya;
    }

    struct ChainflipCCMParams {
        uint32 dstChain;
        bytes dstAddress;
        uint32 dstToken;
        address srcToken;
        uint256 amount;
        bytes message;
        uint256 gasBudget;
        bytes cfParameters;
    }

    struct EncodedSwapStep {
        DEX dex;
        uint256 percentage;
        address tokenOut;
    }

    struct SwapStep {
        DEX dex;
        address tokenIn;
        address tokenOut;
        uint256 minAmountOut; 
    }

    // Modifier to prevent reentrancy attacks
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Constructor to initialize the contract
    constructor(address _cfVault, address _sushiRouter, address _uniRouter) {
        _status = _NOT_ENTERED;
        cfVault = _cfVault;
        sushiRouter = iSUSHISWAP(_sushiRouter);
        uniRouter = iUNISWAP(_uniRouter);
        owner = msg.sender;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Function to approve a router
    function approveRouter(address router) public onlyOwner {
        approvedRouters[router] = true;
    }

    // Function to check if a token is ETH
    function isETH(address token) internal pure returns (bool) {
        return token == ETH || token == ETH_ALT;
    }

    // Function to revoke router approval
    function revokeRouterApproval(address router) public onlyOwner {
        approvedRouters[router] = false;
    }

    // Function to determine the type of swap
    function determineSwapType(address tokenIn, address tokenOut) internal pure returns (SwapType) {
        if (isETH(tokenIn)) {
            return SwapType.ETH_TO_TOKEN;
        } else if (isETH(tokenOut)) {
            return SwapType.TOKEN_TO_ETH;
        } else {
            return SwapType.TOKEN_TO_TOKEN;
        }
    }

    // Function to check and request tokens for a swap
    function checkAdnRequest(address TokenIn, uint256 amount, uint256 valueSent, address sender) internal {
        if (isETH(TokenIn)) {
            require(valueSent == amount, "Incorrect ETH amount");
        } else {
            require(valueSent == 0, "ETH not accepted for token swaps");
            TokenIn.safeTransferFrom(sender, address(this), amount);
        }
    }


// Internal function to execute the THORChain/Maya portion of a swap
function _swapThorMaya(ThorMayaParams memory params, uint256 amount) internal {
    if (amount > 0) {
        if (isETH(params.token)) {
            // For ETH swaps, call depositWithExpiry with ETH value
            iROUTER(params.router).depositWithExpiry{value: amount}(
                payable(params.vault),
                ETH,
                amount,
                params.memo,
                block.timestamp + 1 hours
            );
        } else {
            // For token swaps, approve and call depositWithExpiry
            params.token.safeApprove(params.router, amount);
            iROUTER(params.router).depositWithExpiry(
                payable(params.vault),
                params.token,
                amount,
                params.memo,
                block.timestamp + 1 hours
            );
        }
        // Emit an event to log the swap execution
        emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", params.token, amount, params.memo);
    }
}

// Internal function to execute the Chainflip CCM portion of a swap
function _executeChainflipCCMSwap(
    address srcToken,
    uint256 amount,
    uint256 gasBudget,
    ChainflipCCMParams memory params
) internal {
    if (isETH(srcToken)) {
        // For ETH swaps, call xCallNative on the Chainflip vault
        iCHAINFLIP_VAULT(cfVault).xCallNative{value: amount}(
            params.dstChain,
            params.dstAddress,
            params.dstToken,
            params.message,
            gasBudget,
            params.cfParameters
        );
    } else {
        // For token swaps, approve and call xCallToken on the Chainflip vault
        srcToken.safeApprove(cfVault, amount);
        iCHAINFLIP_VAULT(cfVault).xCallToken(
            params.dstChain,
            params.dstAddress,
            params.dstToken,
            params.message,
            gasBudget,
            srcToken,
            amount,
            params.cfParameters
        );
    }
    // Emit an event to log the Chainflip CCM swap execution
    emit SwapExecuted("Chainflip CCM", srcToken, amount, string(params.message));
}

function _swapOnSushiswap(
    SwapType swapType,
    address inputToken,
    uint256 inputAmount,
    address outputToken,
    uint256 minOutputAmount,
    address recipient,
    bool useContractBalance
) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = (swapType == SwapType.ETH_TO_TOKEN) ? sushiRouter.WETH() : inputToken;
    path[1] = (swapType == SwapType.TOKEN_TO_ETH) ? sushiRouter.WETH() : outputToken;

    if (!useContractBalance && swapType != SwapType.ETH_TO_TOKEN) {
        inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
    }

    if (!isETH(inputToken)) {
        _approveSushiswap(inputToken, inputAmount);
    }

    uint[] memory amounts;

    if (swapType == SwapType.ETH_TO_TOKEN) {
        amounts = sushiRouter.swapExactETHForTokens{value: inputAmount}(
            minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    } else if (swapType == SwapType.TOKEN_TO_TOKEN) {
        amounts = sushiRouter.swapExactTokensForTokens(
            inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    } else {
        amounts = sushiRouter.swapExactTokensForETH(
            inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    }
    return amounts[1];
}
    function _swapOnUniswap(
        SwapType swapType,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minOutputAmount,
        address recipient,
        bool useContractBalance
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = (swapType == SwapType.ETH_TO_TOKEN) ? uniRouter.WETH() : inputToken;
        path[1] = (swapType == SwapType.TOKEN_TO_ETH) ? uniRouter.WETH() : outputToken;

        if (!useContractBalance && swapType != SwapType.ETH_TO_TOKEN) {
            inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
        }

        if (!isETH(inputToken)) {
            _approveUniswap(inputToken, inputAmount);
        }

        uint[] memory amounts;

        if (swapType == SwapType.ETH_TO_TOKEN) {
            amounts = uniRouter.swapExactETHForTokens{value: inputAmount}(
                minOutputAmount, path, recipient, block.timestamp + 15 minutes
            );
        } else if (swapType == SwapType.TOKEN_TO_TOKEN) {
            amounts = uniRouter.swapExactTokensForTokens(
                inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
            );
        } else {
            amounts = uniRouter.swapExactTokensForETH(
                inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
            );
        }
        return amounts[1];
}

function _executeAdvancedSwap(
    address token,
    uint256 amount,
    EncodedSwapStep[] memory encodedSteps
) internal returns (uint256) {
    require(encodedSteps.length > 0, "No swap steps provided");

    uint256 amountSushi = (encodedSteps[0].percentage * amount) / 100;
    uint256 amountUni = amount - amountSushi;
    uint256 outputAmountU = 0;
    uint256 outputAmountS = 0;

    if (amountUni > 0) {
        address[] memory uniPath = new address[](encodedSteps.length + 1);
        uniPath[0] = token;
        uint256 uniPathLength = 1;
        for (uint i = 0; i < encodedSteps.length; i++) {
            if (encodedSteps[i].dex == DEX.UNISWAP) {
                uniPath[uniPathLength++] = encodedSteps[i].tokenOut;
            }
        }
        if (uniPathLength > 1) {
            outputAmountU = _swapWithPath(DEX.UNISWAP, uniPath, amountUni, uniPathLength);
        }
    }

    if (amountSushi > 0) {
        address[] memory sushiPath = new address[](encodedSteps.length + 1);
        sushiPath[0] = token;
        uint256 sushiPathLength = 1;
        for (uint i = 0; i < encodedSteps.length; i++) {
            if (encodedSteps[i].dex == DEX.SUSHISWAP) {
                sushiPath[sushiPathLength++] = encodedSteps[i].tokenOut;
            }
        }
        if (sushiPathLength > 1) {
            outputAmountS = _swapWithPath(DEX.SUSHISWAP, sushiPath, amountSushi, sushiPathLength);
        }
    }

    return outputAmountU + outputAmountS;
}

function _swapWithPath(
    DEX dex,
    address[] memory path,
    uint256 amountIn,
    uint256 pathLength
) internal returns (uint256) {
    require(pathLength > 1, "Invalid path length");
    
    address inputToken = path[0];
    address outputToken = path[pathLength - 1];
    SwapType swapType;
    
    if (isETH(inputToken)) {
        swapType = SwapType.ETH_TO_TOKEN;
    } else if (isETH(outputToken)) {
        swapType = SwapType.TOKEN_TO_ETH;
    } else {
        swapType = SwapType.TOKEN_TO_TOKEN;
    }

    uint256 minOutputAmount = 0; // We'll check the final amount outside this function
    address recipient = address(this);
    bool useContractBalance = true;

    if (dex == DEX.UNISWAP) {
        return _swapOnUniswap(
            swapType,
            inputToken,
            amountIn,
            outputToken,
            minOutputAmount,
            recipient,
            useContractBalance
        );
    } else if (dex == DEX.SUSHISWAP) {
        return _swapOnSushiswap(
            swapType,
            inputToken,
            amountIn,
            outputToken,
            minOutputAmount,
            recipient,
            useContractBalance
        );
    } else {
        revert("Unsupported DEX");
    }
}

function _approveUniswap(address token, uint256 amount) internal {
    if (!isETH(token)) {
        token.safeApprove(address(uniRouter), amount);
    }
}


    
    function _handleChainflipCCMSwap(
        SwapType swapType, 
        address outputToken, 
        uint256 amount, 
        ChainflipCCMParams memory params
    ) internal {
        params.srcToken = (swapType == SwapType.TOKEN_TO_ETH) ? ETH : outputToken;
        params.amount = amount;
        _executeChainflipCCMSwap(params.srcToken, amount, params.gasBudget, params);
    }


    function _approveSushiswap(address token, uint256 amount) internal {
        if (!isETH(token)) {
            token.safeApprove(address(sushiRouter), amount);
        }
    }


    function cfReceive(
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message,
        address token,
        uint256 amount
    ) public payable nonReentrant {
        try this.cfReceiveInternal(srcChain, srcAddress, message, token, amount) {
        } catch Error(string memory reason) {
            // (, address router,) = abi.decode(                message,
            //     (uint8, address, bytes)
            // );
            // if (isETH(token)) {
            //     router.safeTransferETH(amount);
            // } else {
            //     token.safeTransfer(router, amount);
            // }
            emit SwapFailed(srcChain, srcAddress, token, amount, reason);
        } catch (bytes memory reason) {
            // (, address router,) = abi.decode(                message,
            //     (uint8, address, bytes)
            // );
            // if (isETH(token)) {
            //     router.safeTransferETH(amount);
            // } else {
            //     token.safeTransfer(router, amount);
            // }
            emit SwapFailed(srcChain, srcAddress, token, amount, string(reason));
        }
    }

    function cfReceiveInternal(
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message,
        address token,
        uint256 amount
    ) external payable {
        require(msg.sender == address(this), "Only callable internally");
        (uint8 swapType, address router, bytes memory memoBytes) = abi.decode(
            message,
            (uint8, address, bytes)
        );

        if (swapType == 0) {
            // Swap to THORChain/Maya
            string memory memo = string(memoBytes);
            ThorMayaParams memory params = ThorMayaParams({
                vault: cfVault,
                router: router,
                token: token,
                amount: amount,
                memo: memo,
                isMaya: false // Assuming it's not Maya, adjust if needed
            });
            _swapThorMaya(params, amount);
            emit CFReceive(srcChain, srcAddress, token, amount, router, memo);

        } else if (swapType == 1) {
            // Advanced swap on Uniswap and/or Sushiswap
            _handleAdvancedSwap(srcChain, srcAddress, token, amount, router, memoBytes);
            emit CFReceive(srcChain, srcAddress, token, amount, router, "success advanced swap");

        } else if (swapType == 2) {
            // deposit ICHAINFLIP_LP
            bytes32 nodeID = abi.decode(memoBytes, (bytes32));
            token.safeApprove(router, amount);
            ICHAINFLIP_LP(router).fundStateChainAccount(nodeID, amount);
        } else {
            emit SwapFailed(srcChain, srcAddress, token, amount, "Invalid swap type");
            return;
        }
    }
    function _handleAdvancedSwap(
        uint32 srcChain,
        bytes memory srcAddress,
        address token,
        uint256 amount,
        address router,
        bytes memory memoBytes
    ) internal {
        (address finalOutputToken, uint256 minTotalOutputAmount, EncodedSwapStep[] memory encodedSteps) = abi.decode(memoBytes, (address, uint256, EncodedSwapStep[]));
        
        uint256 outputAmount = _executeAdvancedSwap(token, amount, encodedSteps);
        require(outputAmount >= minTotalOutputAmount, "Slippage too high");
        
        _transferOutput(finalOutputToken, outputAmount, router);
        emit CFReceive(srcChain, srcAddress, token, amount, router, "success advanced swap");
    }


    function _transferOutput(address finalOutputToken, uint256 outputAmount, address router) internal {
        if (isETH(finalOutputToken)) {
            router.safeTransferETH(outputAmount);
        } else {
            finalOutputToken.safeTransfer(router, outputAmount);
        }
    }


    function rescueFunds(address asset, uint256 amount, address destination) public onlyOwner {
            if (asset == ETH) {
                destination.safeTransferETH(amount);
            } else {
                asset.safeTransfer(destination, amount);
            }
        }
    }
