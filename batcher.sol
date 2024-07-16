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

    function xSwapToken(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        address srcToken,
        uint256 amount,
        bytes calldata cfParameters
    ) external;
}

contract ThorchainMayaChainflipAggregator {
    using SafeTransferLib for address;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address private constant ETH = address(0);
    address public owner;
    address public cfVault; 
    enum SwapType { ETH_TO_TOKEN, TOKEN_TO_TOKEN, TOKEN_TO_ETH }

    mapping(address => bool) public approvedRouters;
    iSUSHISWAP public sushiRouter;


    event SwapExecuted(string protocol, address token, uint256 amount, string memo);
    event CFReceive(
        uint32 srcChain,
        bytes srcAddress,
        address token,
        uint256 amount,
        address router,
        string memo
    );

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

    constructor(address _cfVault, address _sushiRouter) {
        _status = _NOT_ENTERED;
        cfVault = _cfVault;
        sushiRouter = iSUSHISWAP(_sushiRouter);
        owner = msg.sender;
    }

    receive() external payable {}

    function approveRouter(address router) public onlyOwner {
        approvedRouters[router] = true;
    }

    function revokeRouterApproval(address router) public onlyOwner {
        approvedRouters[router] = false;
    }

    function swapThorDirect(
        address vault,
        address router,
        address token,
        uint256 amount,
        string memory memo,
        bool isMaya
    ) public payable nonReentrant {
        require(approvedRouters[router], "Router not approved");
        
        if (token == ETH) {
            require(msg.value == amount, "Incorrect ETH amount");
            iROUTER(router).depositWithExpiry{value: amount}(
                payable(vault),
                ETH,
                amount,
                memo,
                block.timestamp + 1 hours
            );
        } else {
            require(msg.value == 0, "ETH not accepted for token swaps");
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(router, amount);
            iROUTER(router).depositWithExpiry(
                payable(vault),
                token,
                amount,
                memo,
                block.timestamp + 1 hours
            );
        }

        emit SwapExecuted(isMaya ? "Maya" : "THORChain", token, amount, memo);
    }

    function swapViaChainflip(
        uint32 dstChain,
        bytes calldata dstAddress,
        uint32 dstToken,
        address srcToken,
        uint256 amount,
        bytes calldata cfParameters 
    ) public payable nonReentrant {
        require(cfVault != address(0), "Chainflip vault address not set");
        
        if (srcToken == ETH) {
            require(msg.value == amount, "Incorrect ETH amount");
            iCHAINFLIP_VAULT(cfVault).xSwapNative{value: amount}(
                dstChain,
                dstAddress,
                dstToken,
                cfParameters
            );
        } else {
            require(msg.value == 0, "ETH not accepted for token swaps");
            srcToken.safeTransferFrom(msg.sender, address(this), amount);
            srcToken.safeApprove(cfVault, amount);
            iCHAINFLIP_VAULT(cfVault).xSwapToken(
                dstChain,
                dstAddress,
                dstToken,
                srcToken,
                amount,
                cfParameters
            );
        }

        emit SwapExecuted("Chainflip", srcToken, amount, string(cfParameters));
    }

    struct ThorMayaParams {
        address vault;
        address router;
        address token;
        uint256 amount;
        string memo;
        bool isMaya;
    }

    struct ChainflipParams {
        uint32 dstChain;
        bytes dstAddress;
        uint32 dstToken;
        address srcToken;
        uint256 amount;
        bytes cfParameters;
    }

    function swapBoth(
        ThorMayaParams memory thorMayaParams,
        ChainflipParams memory chainflipParams,
        uint256 thorMayaPercentage
    ) public payable nonReentrant {
        require(approvedRouters[thorMayaParams.router], "Router not approved");
        require(thorMayaPercentage <= 100, "Invalid percentage");

        uint256 thorMayaAmount = (thorMayaParams.amount * thorMayaPercentage) / 100;
        uint256 chainflipAmount = thorMayaParams.amount - thorMayaAmount;

        if (thorMayaParams.token == ETH) {
            require(msg.value == thorMayaParams.amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "ETH not accepted for token swaps");
            thorMayaParams.token.safeTransferFrom(msg.sender, address(this), thorMayaParams.amount);
        }

        _swapThorMaya(thorMayaParams, thorMayaAmount);
        _swapChainflip(chainflipParams, chainflipAmount);
    }

    function _swapThorMaya(ThorMayaParams memory params, uint256 amount) internal {
        if (amount > 0) {
            if (params.token == ETH) {
                iROUTER(params.router).depositWithExpiry{value: amount}(
                    payable(params.vault),
                    ETH,
                    amount,
                    params.memo,
                    block.timestamp + 1 hours
                );
            } else {
                params.token.safeApprove(params.router, amount);
                iROUTER(params.router).depositWithExpiry(
                    payable(params.vault),
                    params.token,
                    amount,
                    params.memo,
                    block.timestamp + 1 minutes
                );
            }
            emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", params.token, amount, params.memo);
        }
    }

    function _swapChainflip(ChainflipParams memory params, uint256 amount) internal {
        if (amount > 0) {
            if (params.srcToken == ETH) {
                iCHAINFLIP_VAULT(cfVault).xSwapNative{value: amount}(
                    params.dstChain,
                    params.dstAddress,
                    params.dstToken,
                    params.cfParameters
                );
            } else {
                params.srcToken.safeApprove(cfVault, amount);
                iCHAINFLIP_VAULT(cfVault).xSwapToken(
                    params.dstChain,
                    params.dstAddress,
                    params.dstToken,
                    params.srcToken,
                    amount,
                    params.cfParameters
                );
            }
            emit SwapExecuted("Chainflip", params.srcToken, amount, string(params.cfParameters));
        }
    }


    function swapSushiThenThorChainflip(
        SwapType swapType,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minOutputAmount,
        bool useChainflip,
        bool useThorchain,
        uint256 thorchainPercentage,
        ThorMayaParams memory thorMayaParams,
        ChainflipParams memory chainflipParams
    ) public payable nonReentrant {
        require(swapType == SwapType.ETH_TO_TOKEN || msg.value == 0, "ETH not accepted for token swaps");
        require(swapType != SwapType.ETH_TO_TOKEN || msg.value == inputAmount, "Incorrect ETH amount");

        uint256 outputAmount;

        // Step 1: Swap on Sushiswap
        if (swapType == SwapType.ETH_TO_TOKEN) {
            // ETH to Token swap
            address[] memory path = new address[](2);
            path[0] = sushiRouter.WETH();
            path[1] = outputToken;
            
            uint[] memory amounts = sushiRouter.swapExactETHForTokens{value: inputAmount}(
                minOutputAmount,
                path,
                address(this),
                block.timestamp + 15 minutes
            );
            outputAmount = amounts[1];
        } else if (swapType == SwapType.TOKEN_TO_TOKEN) {
            // Token to Token swap
            inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
            inputToken.safeApprove(address(sushiRouter), inputAmount);

            address[] memory path = new address[](2);
            path[0] = inputToken;
            path[1] = outputToken;

            uint[] memory amounts = sushiRouter.swapExactTokensForTokens(
                inputAmount,
                minOutputAmount,
                path,
                address(this),
                block.timestamp + 15 minutes
            );
            outputAmount = amounts[1];
        } else {
            // Token to ETH swap
            inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
            inputToken.safeApprove(address(sushiRouter), inputAmount);

            address[] memory path = new address[](2);
            path[0] = inputToken;
            path[1] = sushiRouter.WETH();

            uint[] memory amounts = sushiRouter.swapExactTokensForETH(
                inputAmount,
                minOutputAmount,
                path,
                address(this),
                block.timestamp + 15 minutes
            );
            outputAmount = amounts[1];
        }

        // Check actual balance after swap
        uint256 actualBalance;
        if (swapType == SwapType.TOKEN_TO_ETH) {
            actualBalance = address(this).balance;
        } else {
            actualBalance = iERC20(outputToken).balanceOf(address(this));
        }
        require(actualBalance >= minOutputAmount, "Insufficient output amount");
        outputAmount = actualBalance;

        // Step 2: Swap on Thorchain or Chainflip
        if (useChainflip && !useThorchain) {
        _handleChainflipSwap(swapType, outputToken, outputAmount, chainflipParams);
    } else if (!useChainflip && useThorchain) {
        _handleThorchainSwap(swapType, outputToken, outputAmount, thorMayaParams);
    } else if (useChainflip && useThorchain) {
        uint256 thorchainAmount = (outputAmount * thorchainPercentage) / 100;
        uint256 chainflipAmount = outputAmount - thorchainAmount;

        _handleThorchainSwap(swapType, outputToken, thorchainAmount, thorMayaParams);
        _handleChainflipSwap(swapType, outputToken, chainflipAmount, chainflipParams);
    } else {
        revert("Invalid swap configuration");
    }

    emit SwapExecuted("SushiThenThorChainflip", inputToken, inputAmount, "");
}

    function _handleChainflipSwap(
        SwapType swapType, 
        address outputToken, 
        uint256 amount, 
        ChainflipParams memory params
    ) internal {
        if (swapType == SwapType.TOKEN_TO_ETH) {
            params.srcToken = ETH;
        } else {
            outputToken.safeApprove(cfVault, amount);
            params.srcToken = outputToken;
        }
        params.amount = amount;
        _swapChainflip(params, amount);
    }

    function _handleThorchainSwap(
        SwapType swapType, 
        address outputToken, 
        uint256 amount, 
        ThorMayaParams memory params
    ) internal {
        if (swapType == SwapType.TOKEN_TO_ETH) {
            params.token = ETH;
        } else {
            outputToken.safeApprove(params.router, amount);
            params.token = outputToken;
        }
        params.amount = amount;
        _swapThorMaya(params, amount);
    }

    function cfReceive(
        uint32 srcChain,
        bytes calldata srcAddress,
        bytes calldata message,
        address token,
        uint256 amount
    ) public payable nonReentrant {
        (uint8 swapType, address router, string memory memo) = abi.decode(
            message,
            (uint8, address, string)
        );
        
        require(approvedRouters[router], "Router not approved");

        if (swapType == 0) {
            // Swap to THORChain/Maya
            if (token == ETH) {
                require(msg.value == amount, "Incorrect ETH amount");
                iROUTER(router).depositWithExpiry{value: amount}(
                    payable(cfVault),
                    ETH,
                    amount,
                    memo,
                    block.timestamp + 15 minutes
                );
            } else {
                token.safeApprove(router, amount);
                iROUTER(router).depositWithExpiry(
                    payable(cfVault),
                    token,
                    amount,
                    memo,
                    block.timestamp + 15 minutes
                );
            }
            emit CFReceive(srcChain, srcAddress, token, amount, router, memo);
        } else if (swapType == 1) {
            // Swap on Sushiswap
            address outputToken = abi.decode(bytes(memo), (address)); // Decode output token from memo
            if (token == ETH) {
                address[] memory path = new address[](2);
                path[0] = sushiRouter.WETH();
                path[1] = outputToken;
                
                sushiRouter.swapExactETHForTokens{value: amount}(
                    0, // We're not setting a minimum output amount here
                    path,
                    msg.sender, // Send directly to the original sender
                    block.timestamp + 15 minutes
                );
            } else {
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = outputToken;

                token.safeApprove(address(sushiRouter), amount);
                sushiRouter.swapExactTokensForTokens(
                    amount,
                    0, // We're not setting a minimum output amount here
                    path,
                    msg.sender, // Send directly to the original sender
                    block.timestamp + 15 minutes
                );
            }
            emit CFReceive(srcChain, srcAddress, token, amount, address(sushiRouter), memo);
        } else {
            revert("Invalid swap type");
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