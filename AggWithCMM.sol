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

// // Function to perform a direct swap on THORChain or Maya
// function swapThorDirect(ThorMayaParams memory params) public payable nonReentrant {
//     // Ensure the router is approved for use
//     require(approvedRouters[params.router], "Router not approved");
    
//     if (isETH(params.token)) {
//         // For ETH swaps, ensure the sent value matches the swap amount
//         require(msg.value == params.amount, "Incorrect ETH amount");
//         // Call the router's depositWithExpiry function with ETH value
//         iROUTER(params.router).depositWithExpiry{value: params.amount}(
//             payable(params.vault),
//             ETH,
//             params.amount,
//             params.memo,
//             block.timestamp + 1 hours // Set expiration to 1 hour from now
//         );
//     } else {
//         // For token swaps, ensure no ETH is sent
//         require(msg.value == 0, "ETH not accepted for token swaps");
//         // Transfer tokens from sender to this contract
//         params.token.safeTransferFrom(msg.sender, address(this), params.amount);
//         // Approve the router to spend the tokens
//         params.token.safeApprove(params.router, params.amount);
//         // Call the router's depositWithExpiry function for token swap
//         iROUTER(params.router).depositWithExpiry(
//             payable(params.vault),
//             params.token,
//             params.amount,
//             params.memo,
//             block.timestamp + 1 hours // Set expiration to 1 hour from now
//         );
//     }

//     // Emit an event to log the swap execution
//     emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", params.token, params.amount, params.memo);
// }

// Function to perform a swap via Chainflip CCM (Cross-Chain Messaging)
function swapViaChainflipCCM(ChainflipCCMParams memory params) public payable nonReentrant {
    // Check and request the appropriate tokens/ETH for the swap
    checkAdnRequest(params.srcToken, params.amount, msg.value, msg.sender);
    // Execute the Chainflip CCM swap
    _executeChainflipCCMSwap(params.srcToken, params.amount, params.gasBudget, params);
}

// Function to perform a split swap between THORChain/Maya and Chainflip CCM
function swapBothCCM(
    ThorMayaParams memory thorMayaParams,
    ChainflipCCMParams memory chainflipParams,
    uint256 thorMayaPercentage
) public payable nonReentrant {
    // Ensure the THORChain/Maya router is approved
    require(approvedRouters[thorMayaParams.router], "Router not approved");
    // Validate the percentage for THORChain/Maya swap
    require(thorMayaPercentage <= 100, "Invalid percentage");

    // Calculate amounts for each protocol based on the percentage
    uint256 thorMayaAmount = (thorMayaParams.amount * thorMayaPercentage) / 100;
    uint256 chainflipAmount = thorMayaParams.amount - thorMayaAmount;

    // Check and request the appropriate tokens/ETH for the swap
    checkAdnRequest(thorMayaParams.token, thorMayaParams.amount, msg.value, msg.sender);

    // Execute the THORChain/Maya portion of the swap
    _swapThorMaya(thorMayaParams, thorMayaAmount);
    // Execute the Chainflip CCM portion of the swap
    _executeChainflipCCMSwap(chainflipParams.srcToken, chainflipAmount, chainflipParams.gasBudget, chainflipParams);
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
// Function to execute a swap using Odos router, then Chainflip CCM
function odosSwapThenChainflip(
    address odosRouter,
    bytes calldata swapData,
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 minOutputAmount,
    ChainflipCCMParams memory chainflipParams
) external payable {
    // Check if the input is ETH or a token
    bool isInputEth = isETH(inputToken);

    // Ensure the correct amount is sent
    if (isInputEth) {
        require(msg.value == inputAmount, "Incorrect ETH amount");
    } else {
        require(msg.value == 0, "ETH not accepted for token swaps");
        // Transfer tokens from the sender to this contract
        inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
        // Approve Odos router to spend the input tokens
        inputToken.safeApprove(odosRouter, inputAmount);
    }

    // Record the initial balance of the output token/ETH
    uint256 initialBalance;
    if (isETH(outputToken)) {
        initialBalance = address(this).balance;
    } else {
        initialBalance = iERC20(outputToken).balanceOf(address(this));
    }

    // Execute the swap using Odos router
    (bool success, ) = odosRouter.call{value: isInputEth ? inputAmount : 0}(swapData);
    require(success, "Odos swap failed");

    // Calculate the output amount
    uint256 outputAmount;
    if (isETH(outputToken)) {
        outputAmount = address(this).balance - initialBalance;
    } else {
        outputAmount = iERC20(outputToken).balanceOf(address(this)) - initialBalance;
    }
    require(outputAmount >= minOutputAmount, "Insufficient output amount");

    // Handle the Chainflip CCM swap with the output token/ETH
    _handleChainflipCCMSwap(
        determineSwapType(outputToken, chainflipParams.srcToken),
        outputToken,
        outputAmount,
        chainflipParams
    );

    // Emit an event for the swap execution
    emit SwapExecuted("OdosThenChainflip", inputToken, inputAmount, string(chainflipParams.message));
}

// Function to execute swaps on EVM-compatible DEXes, then split between THORChain and Chainflip CCM
function EVMThenThorChainflipCCM(
    address inputToken,
    uint256 inputAmount,
    address finalToken,
    EncodedSwapStep[] memory steps,
    uint256 thorchainPercentage,
    ThorMayaParams memory thorMayaParams,
    ChainflipCCMParams memory chainflipParams
) public payable nonReentrant {
    require(steps.length > 0, "No swap steps provided");
    require(steps[0].dex == DEX.UNISWAP || steps[0].dex == DEX.SUSHISWAP, "First step must be Uniswap or Sushiswap");

    address outputToken = steps[steps.length - 1].tokenOut;
    
    // Check and request appropriate tokens/ETH for the swap
    checkAdnRequest(inputToken, inputAmount, msg.value, msg.sender);

    // Execute the EVM-compatible DEX swaps
    uint256 outputAmount = _executeAdvancedSwap(inputToken, inputAmount, steps);

    // Calculate amounts for THORChain and Chainflip based on the percentage
    uint256 thorchainAmount = (outputAmount * thorchainPercentage) / 100;
    uint256 chainflipAmount = outputAmount - thorchainAmount;

    // Handle THORChain swap
    _handleThorchainSwap(determineSwapType(outputToken, finalToken), outputToken, thorchainAmount, thorMayaParams);
    // Handle Chainflip CCM swap
    _handleChainflipCCMSwap(determineSwapType(outputToken, finalToken), outputToken, chainflipAmount, chainflipParams);  

    emit SwapExecuted("UniSushiThenThorChainflipCCM", inputToken, inputAmount, "");
}

// Function to execute swaps on EVM-compatible DEXes, then Chainflip CCM
function EVMThenChainflipCCM(
    address inputToken,
    uint256 inputAmount,
    address finalToken,
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
    _handleChainflipCCMSwap(determineSwapType(outputToken, finalToken), outputToken, outputAmount, chainflipParams);

    emit SwapExecuted("UniSushiThenThorChainflipCCM", inputToken, inputAmount, "");
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
