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


// Function to perform a swap via Chainflip CCM (Cross-Chain Messaging)
function swapViaChainflipCCM(ChainflipCCMParams memory params) public payable nonReentrant {
    // Check and request the appropriate tokens/ETH for the swap
    checkAdnRequest(params.srcToken, params.amount, msg.value, msg.sender);
    // Execute the Chainflip CCM swap
    _executeChainflipCCMSwap(params.srcToken, params.amount, params.gasBudget, params);
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

// Function to execute swaps on EVM-compatible DEXes, then Chainflip CCM
function EVMThenChainflipCCM(
    address inputToken,
    uint256 inputAmount,
    EncodedSwapStep[] memory steps,
    ChainflipCCMParams memory chainflipParams
) public payable nonReentrant {
    require(steps.length > 0, "No swap steps provided");
    require(steps[0].dex == DEX.UNISWAP || steps[0].dex == DEX.SUSHISWAP, "First step must be Uniswap or Sushiswap");

    // Check and request appropriate tokens/ETH for the swap
    checkAdnRequest(inputToken, inputAmount, msg.value, msg.sender);
    address outputToken = steps[steps.length - 1].tokenOut;

    // Execute the EVM-compatible DEX swaps
    uint256 outputAmount = _executeAdvancedSwap(inputToken, inputAmount, steps);

    // Handle Chainflip CCM swap with the output
    _executeChainflipCCMSwap(outputToken, outputAmount, chainflipParams.gasBudget, chainflipParams);

    emit SwapExecuted("UniSushiThenThorChainflipCCM", inputToken, inputAmount, "");
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
function executeSwapSteps(
    SwapStep[] memory steps,
    address initialToken,
    uint256 initialAmount
) internal returns (uint256) {
    uint256 currentAmount = initialAmount;
    address currentToken = initialToken;

    for (uint i = 0; i < steps.length; i++) {
        SwapStep memory step = steps[i];
        uint256 stepAmount = currentAmount;
        
        // Approve the current token for the respective DEX
        if (step.dex == DEX.UNISWAP) {
            _approveUniswap(currentToken, stepAmount);
        } else if (step.dex == DEX.SUSHISWAP) {
            _approveSushiswap(currentToken, stepAmount);
        }
        
        uint256 stepOutput;
        if (step.dex == DEX.UNISWAP) {
            stepOutput = _swapOnUniswap(
                determineSwapType(currentToken, step.tokenOut),
                currentToken,
                stepAmount,
                step.tokenOut,
                step.minAmountOut,
                address(this), 
                true
            );
        } else if (step.dex == DEX.SUSHISWAP) {
            stepOutput = _swapOnSushiswap(
                determineSwapType(currentToken, step.tokenOut),
                currentToken,
                stepAmount,
                step.tokenOut,
                step.minAmountOut,
                address(this),
                true
            );
        } else {
            revert("Unsupported DEX for this step");
        }
        
        currentAmount = stepOutput;
        currentToken = step.tokenOut;
    }
    return currentAmount;
}

function _approveUniswap(address token, uint256 amount) internal {
    if (!isETH(token)) {
        token.safeApprove(address(uniRouter), amount);
    }
}


    function executeMultiDexSwap(
        SwapStep[] memory steps,
        address inputToken,
        uint256 inputAmount,
        uint256 minTotalOutputAmount
    ) internal returns (uint256) {
        uint256 totalOutput = executeSwapSteps(steps, inputToken, inputAmount);
        require(totalOutput >= minTotalOutputAmount, "Slippage too high");
        return totalOutput;
}
    

    function _approveSushiswap(address token, uint256 amount) internal {
        if (!isETH(token)) {
            token.safeApprove(address(sushiRouter), amount);
        }
    }


    function _executeAdvancedSwap(
        address token,
        uint256 amount,
        EncodedSwapStep[] memory encodedSteps
    ) internal returns (uint256) {
        SwapStep[] memory stepsUni = new SwapStep[](encodedSteps.length);
        SwapStep[] memory stepsSushi = new SwapStep[](encodedSteps.length);
        uint256 amountSushi = (encodedSteps[0].percentage * amount) / 100;
        uint256 amountUni = amount - amountSushi;

        uint256 uniCount = 0;
        uint256 sushiCount = 0;

        for (uint i = 0; i < encodedSteps.length; i++) {
            if (encodedSteps[i].dex == DEX.UNISWAP) {
                stepsUni[uniCount++] = SwapStep({
                    dex: encodedSteps[i].dex,
                    tokenIn: uniCount == 0 ? token : stepsUni[uniCount - 1].tokenOut,
                    tokenOut: encodedSteps[i].tokenOut,
                    minAmountOut: 0
                });

            } else if (encodedSteps[i].dex == DEX.SUSHISWAP) {
                stepsSushi[sushiCount++] = SwapStep({
                dex: encodedSteps[i].dex,
                tokenIn: sushiCount == 0 ? token : stepsSushi[sushiCount - 1].tokenOut,
                tokenOut: encodedSteps[i].tokenOut,
                minAmountOut: 0
                });
            }
        }

        if (!isETH(token)) {
            if (uniCount > 0) {
            _approveUniswap(token, amountUni);
            } 
            if (sushiCount > 0) {
            _approveSushiswap(token, amountSushi);
            }
        }

        uint256 outputAmountU = 0;
        uint256 outputAmountS = 0;

        if (uniCount > 0) {
            SwapStep[] memory validStepsUni = new SwapStep[](uniCount);
            for (uint i = 0; i < uniCount; i++) {
                validStepsUni[i] = stepsUni[i];
            }
            outputAmountU = executeSwapSteps(validStepsUni, token, amountUni);
        }

        if (sushiCount > 0) {
            SwapStep[] memory validStepsSushi = new SwapStep[](sushiCount);
            for (uint i = 0; i < sushiCount; i++) {
                validStepsSushi[i] = stepsSushi[i];
            }
            outputAmountS = executeSwapSteps(validStepsSushi, token, amountSushi);
        }

        return outputAmountU + outputAmountS;
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
