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


contract ThorchainAggregatorExp {
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


    // Struct definitions for various swap parameters
    struct ThorMayaParams {
        address vault;
        address router;
        address token;
        uint256 amount;
        string memo;
        bool isMaya;
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
    constructor(address _sushiRouter, address _uniRouter) {
        _status = _NOT_ENTERED;
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

// Function to perform a direct swap on THORChain or Maya
function swapThorDirect(ThorMayaParams memory params) public payable nonReentrant {
    // Ensure the router is approved for use
    require(approvedRouters[params.router], "Router not approved");
    
    if (isETH(params.token)) {
        // For ETH swaps, ensure the sent value matches the swap amount
        require(msg.value == params.amount, "Incorrect ETH amount");
        // Call the router's depositWithExpiry function with ETH value
        iROUTER(params.router).depositWithExpiry{value: params.amount}(
            payable(params.vault),
            ETH,
            params.amount,
            params.memo,
            block.timestamp + 1 hours // Set expiration to 1 hour from now
        );
    } else {
        // For token swaps, ensure no ETH is sent
        require(msg.value == 0, "ETH not accepted for token swaps");
        // Transfer tokens from sender to this contract
        params.token.safeTransferFrom(msg.sender, address(this), params.amount);
        // Approve the router to spend the tokens
        params.token.safeApprove(params.router, params.amount);
        // Call the router's depositWithExpiry function for token swap
        iROUTER(params.router).depositWithExpiry(
            payable(params.vault),
            params.token,
            params.amount,
            params.memo,
            block.timestamp + 1 hours // Set expiration to 1 hour from now
        );
    }

    // Emit an event to log the swap execution
    emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", params.token, params.amount, params.memo);
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


// Function to execute swaps on EVM-compatible DEXes, then THORChain
function EVMThenThor(
    address inputToken,
    uint256 inputAmount,
    EncodedSwapStep[] memory steps,
    ThorMayaParams memory thorMayaParams
) public payable nonReentrant {
    require(steps.length > 0, "No swap steps provided");
    require(steps[0].dex == DEX.UNISWAP || steps[0].dex == DEX.SUSHISWAP, "First step must be Uniswap or Sushiswap");

    address outputToken = steps[steps.length - 1].tokenOut;
    // Execute the EVM-compatible DEX swaps
    uint256 outputAmount = _executeAdvancedSwap(inputToken, inputAmount, steps);

    // Check and request appropriate tokens/ETH for the swap
    checkAdnRequest(inputToken, inputAmount, msg.value, msg.sender);

    // Handle THORChain swap with the output
    _handleThorchainSwap(determineSwapType(inputToken, outputToken), outputToken, outputAmount, thorMayaParams);

    emit SwapExecuted("EVMThenThor", inputToken, inputAmount, "");
}




function _approveUniswap(address token, uint256 amount) internal {
    if (!isETH(token)) {
        token.safeApprove(address(uniRouter), amount);
    }
}


    
    
    function _handleThorchainSwap(
        SwapType swapType, 
        address outputToken, 
        uint256 amount, 
        ThorMayaParams memory params
    ) internal {
        params.token = (swapType == SwapType.TOKEN_TO_ETH) ? ETH : outputToken;
        params.amount = amount;
        _swapThorMaya(params, amount);
    }

    function _approveSushiswap(address token, uint256 amount) internal {
        if (!isETH(token)) {
            token.safeApprove(address(sushiRouter), amount);
        }
    }

    // function _executeAdvancedSwap(
    //     address token,
    //     uint256 amount,
    //     EncodedSwapStep[] memory encodedSteps
    // ) internal returns (uint256) {
    //     SwapStep[] memory stepsUni = new SwapStep[](encodedSteps.length);
    //     SwapStep[] memory stepsSushi = new SwapStep[](encodedSteps.length);
    //     uint256 amountSushi = (encodedSteps[0].percentage * amount) / 100;
    //     uint256 amountUni = amount - amountSushi;

    //     uint256 uniCount = 0;
    //     uint256 sushiCount = 0;

    //     for (uint i = 0; i < encodedSteps.length; i++) {
    //         if (encodedSteps[i].dex == DEX.UNISWAP) {
    //             stepsUni[uniCount++] = SwapStep({
    //                 dex: encodedSteps[i].dex,
    //                 tokenIn: uniCount == 0 ? token : stepsUni[uniCount - 1].tokenOut,
    //                 tokenOut: encodedSteps[i].tokenOut,
    //                 minAmountOut: 0
    //             });

    //         } else if (encodedSteps[i].dex == DEX.SUSHISWAP) {
    //             stepsSushi[sushiCount++] = SwapStep({
    //             dex: encodedSteps[i].dex,
    //             tokenIn: sushiCount == 0 ? token : stepsSushi[sushiCount - 1].tokenOut,
    //             tokenOut: encodedSteps[i].tokenOut,
    //             minAmountOut: 0
    //             });
    //         }
    //     }

    //     if (!isETH(token)) {
    //         if (uniCount > 0) {
    //         _approveUniswap(token, amountUni);
    //         } 
    //         if (sushiCount > 0) {
    //         _approveSushiswap(token, amountSushi);
    //         }
    //     }

    //     uint256 outputAmountU = 0;
    //     uint256 outputAmountS = 0;

    //     if (uniCount > 0) {
    //         SwapStep[] memory validStepsUni = new SwapStep[](uniCount);
    //         for (uint i = 0; i < uniCount; i++) {
    //             validStepsUni[i] = stepsUni[i];
    //         }
    //         outputAmountU = executeSwapSteps(validStepsUni, token, amountUni);
    //     }

    //     if (sushiCount > 0) {
    //         SwapStep[] memory validStepsSushi = new SwapStep[](sushiCount);
    //         for (uint i = 0; i < sushiCount; i++) {
    //             validStepsSushi[i] = stepsSushi[i];
    //         }
    //         outputAmountS = executeSwapSteps(validStepsSushi, token, amountSushi);
    //     }

    //     return outputAmountU + outputAmountS;
    // }
function _swapOnSushiswap(
    address[] memory path,
    uint256 inputAmount,
    uint256 minOutputAmount,
    address recipient,
    bool useContractBalance
) internal returns (uint256) {
    require(path.length >= 2, "Invalid path");
    
    address inputToken = path[0];
    address outputToken = path[path.length - 1];
    bool isInputETH = inputToken == uniRouter.WETH();
    bool isOutputETH = outputToken == uniRouter.WETH();

    if (!useContractBalance && !isInputETH) {
        inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
    }

    if (!isInputETH) {
        _approveSushiswap(inputToken, inputAmount);
    }

    uint[] memory amounts;

    if (isInputETH) {
        amounts = sushiRouter.swapExactETHForTokens{value: inputAmount}(
            minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    } else if (isOutputETH) {
        amounts = sushiRouter.swapExactTokensForETH(
            inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    } else {
        amounts = sushiRouter.swapExactTokensForTokens(
            inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    }
    return amounts[amounts.length - 1];
}
function _swapOnUniswap(
    address[] memory path,
    uint256 inputAmount,
    uint256 minOutputAmount,
    address recipient,
    bool useContractBalance
) internal returns (uint256) {
    require(path.length >= 2, "Invalid path");
    
    address inputToken = path[0];
    address outputToken = path[path.length - 1];
    bool isInputETH = inputToken == uniRouter.WETH();
    bool isOutputETH = outputToken == uniRouter.WETH();

    if (!useContractBalance && !isInputETH) {
        inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
    }

    if (!isInputETH) {
        _approveUniswap(inputToken, inputAmount);
    }

    uint[] memory amounts;

    if (isInputETH) {
        amounts = uniRouter.swapExactETHForTokens{value: inputAmount}(
            minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    } else if (isOutputETH) {
        amounts = uniRouter.swapExactTokensForETH(
            inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    } else {
        amounts = uniRouter.swapExactTokensForTokens(
            inputAmount, minOutputAmount, path, recipient, block.timestamp + 15 minutes
        );
    }

    return amounts[amounts.length - 1];
}

function _swapWithPath(
    DEX dex,
    address[] memory path,
    uint256 amountIn
) internal returns (uint256) {
    require(path.length > 1, "Invalid path length");

    uint256 minOutputAmount = 0; // We'll check the final amount outside this function
    address recipient = address(this);
    bool useContractBalance = true;

    if (dex == DEX.UNISWAP) {
        return _swapOnUniswap(
            path,
            amountIn,
            minOutputAmount,
            recipient,
            useContractBalance
        );
    } else if (dex == DEX.SUSHISWAP) {
        return _swapOnSushiswap(
            path,
            amountIn,
            minOutputAmount,
            recipient,
            useContractBalance
        );
    } else {
        revert("Unsupported DEX");
    }
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
        address[] memory uniPath = _createPath(token, encodedSteps, DEX.UNISWAP);
        if (uniPath.length > 1) {
            outputAmountU = _swapWithPath(DEX.UNISWAP, uniPath, amountUni);
        }
    }

    if (amountSushi > 0) {
        address[] memory sushiPath = _createPath(token, encodedSteps, DEX.SUSHISWAP);
        if (sushiPath.length > 1) {
            outputAmountS = _swapWithPath(DEX.SUSHISWAP, sushiPath, amountSushi);
        }
    }

    return outputAmountU + outputAmountS;
}


function _createPath(address initialToken, EncodedSwapStep[] memory steps, DEX dex) internal view returns (address[] memory) {
    uint256 pathLength = 1;
    for (uint i = 0; i < steps.length; i++) {
        if (steps[i].dex == dex) {
            pathLength++;
        }
    }

    address[] memory path = new address[](pathLength);
    path[0] = isETH(initialToken) ? sushiRouter.WETH() : initialToken;
    uint256 index = 1;

    for (uint i = 0; i < steps.length; i++) {
        if (steps[i].dex == dex) {
            // Convert ETH to WETH for intermediate and final steps
            path[index] = isETH(steps[i].tokenOut) ? sushiRouter.WETH() : steps[i].tokenOut;
            index++;
        }
    }

    return path;
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