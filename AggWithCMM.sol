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
    using SafeTransferLib for address;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address private constant ETH = address(0);
    address private constant ETH_ALT = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public owner;
    address public cfVault; 
    enum SwapType { ETH_TO_TOKEN, TOKEN_TO_TOKEN, TOKEN_TO_ETH }

    mapping(address => bool) public approvedRouters;
    iSUSHISWAP public sushiRouter;


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

    function isETH(address token) internal pure returns (bool) {
    return token == ETH || token == ETH_ALT;
    }

    function revokeRouterApproval(address router) public onlyOwner {
        approvedRouters[router] = false;
    }

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

    function swapThorDirect(ThorMayaParams memory params) public payable nonReentrant {
        require(approvedRouters[params.router], "Router not approved");
        
        if (isETH(params.token)) {
            require(msg.value == params.amount, "Incorrect ETH amount");
            iROUTER(params.router).depositWithExpiry{value: params.amount}(
                payable(params.vault),
                ETH,
                params.amount,
                params.memo,
                block.timestamp + 1 hours
            );
        } else {
            require(msg.value == 0, "ETH not accepted for token swaps");
            params.token.safeTransferFrom(msg.sender, address(this), params.amount);
            params.token.safeApprove(params.router, params.amount);
            iROUTER(params.router).depositWithExpiry(
                payable(params.vault),
                params.token,
                params.amount,
                params.memo,
                block.timestamp + 1 hours
            );
        }

        emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", params.token, params.amount, params.memo);
    }

    function swapViaChainflipCCM(ChainflipCCMParams memory params) public payable nonReentrant {
        
        if (isETH(params.srcToken)) {
            require(msg.value == params.amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "ETH not accepted for token swaps");
            params.srcToken.safeTransferFrom(msg.sender, address(this), params.amount);
        }

        _executeChainflipCCMSwap(params.srcToken, params.amount, params.gasBudget, params);
    }

    function swapBothCCM(
        ThorMayaParams memory thorMayaParams,
        ChainflipCCMParams memory chainflipParams,
        uint256 thorMayaPercentage
    ) public payable nonReentrant {
        require(approvedRouters[thorMayaParams.router], "Router not approved");
        require(thorMayaPercentage <= 100, "Invalid percentage");
        require(chainflipParams.gasBudget < chainflipParams.amount, "Gas budget exceeds Chainflip swap amount");

        uint256 thorMayaAmount = (thorMayaParams.amount * thorMayaPercentage) / 100;
        uint256 chainflipAmount = thorMayaParams.amount - thorMayaAmount;

        if (isETH(thorMayaParams.token)) {
            require(msg.value == thorMayaParams.amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "ETH not accepted for token swaps");
            thorMayaParams.token.safeTransferFrom(msg.sender, address(this), thorMayaParams.amount);
        }

        _swapThorMaya(thorMayaParams, thorMayaAmount);
        _executeChainflipCCMSwap(chainflipParams.srcToken, chainflipAmount, chainflipParams.gasBudget, chainflipParams);
    }

    function swapSushiThenThorChainflipCCM(
        SwapType swapType,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minOutputAmount,
        uint256 thorchainPercentage,
        ThorMayaParams memory thorMayaParams,
        ChainflipCCMParams memory chainflipParams
    ) public payable nonReentrant {
        require(swapType == SwapType.ETH_TO_TOKEN || msg.value == 0, "ETH not accepted for token swaps");
        require(swapType != SwapType.ETH_TO_TOKEN || msg.value == inputAmount, "Incorrect ETH amount");

        uint256 outputAmount = _swapOnSushiswap(swapType, inputToken, inputAmount, outputToken, minOutputAmount);
        uint256 thorchainAmount = (outputAmount * thorchainPercentage) / 100;
        uint256 chainflipAmount = outputAmount - thorchainAmount;

        _handleThorchainSwap(swapType, outputToken, thorchainAmount, thorMayaParams);
        _handleChainflipCCMSwap(swapType, outputToken, chainflipAmount, chainflipParams);
        emit SwapExecuted("SushiThenThorChainflipCCM", inputToken, inputAmount, "");
    }
    
    function swapSushiThenThorChain(
        SwapType swapType,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minOutputAmount,
        ThorMayaParams memory thorMayaParams
    ) public payable nonReentrant {
        require(swapType == SwapType.ETH_TO_TOKEN || msg.value == 0, "ETH not accepted for token swaps");
        require(swapType != SwapType.ETH_TO_TOKEN || msg.value == inputAmount, "Incorrect ETH amount");

        uint256 outputAmount = _swapOnSushiswap(swapType, inputToken, inputAmount, outputToken, minOutputAmount);
        _handleThorchainSwap(swapType, outputToken, outputAmount, thorMayaParams);

        emit SwapExecuted("SushiThenThorChainflipCCM", inputToken, inputAmount, "");
    }
    function swapSushiThenThorChainflip(
        SwapType swapType,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minOutputAmount,
        ChainflipCCMParams memory chainflipParams
    ) public payable nonReentrant {
        require(swapType == SwapType.ETH_TO_TOKEN || msg.value == 0, "ETH not accepted for token swaps");
        require(swapType != SwapType.ETH_TO_TOKEN || msg.value == inputAmount, "Incorrect ETH amount");

        uint256 outputAmount = _swapOnSushiswap(swapType, inputToken, inputAmount, outputToken, minOutputAmount);
        _handleChainflipCCMSwap(swapType, outputToken, outputAmount, chainflipParams);
        emit SwapExecuted("SushiThenThorChainflipCCM", inputToken, inputAmount, "");
    }


    function _swapThorMaya(ThorMayaParams memory params, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(params.token)) {
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
                    block.timestamp + 1 hours
                );
            }
            emit SwapExecuted(params.isMaya ? "Maya" : "THORChain", params.token, amount, params.memo);
        }
    }

    function _executeChainflipCCMSwap(
        address srcToken,
        uint256 amount,
        uint256 gasBudget,
        ChainflipCCMParams memory params
    ) internal {
        if (isETH(srcToken)) {
            iCHAINFLIP_VAULT(cfVault).xCallNative{value: amount}(
                params.dstChain,
                params.dstAddress,
                params.dstToken,
                params.message,
                gasBudget,
                params.cfParameters
            );
        } else {
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
        emit SwapExecuted("Chainflip CCM", srcToken, amount, string(params.message));
    }

 function _swapOnSushiswap(
    SwapType swapType,
    address inputToken,
    uint256 inputAmount,
    address outputToken,
    uint256 minOutputAmount
) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = (swapType == SwapType.ETH_TO_TOKEN) ? sushiRouter.WETH() : inputToken;
    path[1] = (swapType == SwapType.TOKEN_TO_ETH) ? sushiRouter.WETH() : outputToken;

    if (swapType != SwapType.ETH_TO_TOKEN && msg.sender != address(this)) {
        inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveSushiswap(inputToken, inputAmount);
    }

    uint[] memory amounts;
    address recipient = address(this);

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
function _swapOnSushiswapOut(
    SwapType swapType,
    address inputToken,
    uint256 inputAmount,
    address outputToken,
    uint256 minOutputAmount,
    address outputAddress
) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = (swapType == SwapType.ETH_TO_TOKEN) ? sushiRouter.WETH() : inputToken;
    path[1] = (swapType == SwapType.TOKEN_TO_ETH) ? sushiRouter.WETH() : outputToken;

    // Remove the safeTransferFrom call as the contract already has the tokens
    if (!isETH(inputToken)) {
        _approveSushiswap(inputToken, inputAmount);
    }
    uint[] memory amounts;

    if (swapType == SwapType.ETH_TO_TOKEN) {
        amounts = sushiRouter.swapExactETHForTokens{value: inputAmount}(
            minOutputAmount, path, outputAddress, block.timestamp + 15 minutes
        );
    } else if (swapType == SwapType.TOKEN_TO_TOKEN) {
        amounts = sushiRouter.swapExactTokensForTokens(
            inputAmount, minOutputAmount, path, outputAddress, block.timestamp + 15 minutes
        );
    } else {
        amounts = sushiRouter.swapExactTokensForETH(
            inputAmount, minOutputAmount, path, outputAddress, block.timestamp + 15 minutes
        );
    }
    return amounts[1];
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
        emit SwapFailed(srcChain, srcAddress, token, amount, reason);
    } catch (bytes memory reason) {
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
        // Swap on Sushiswap
        (address outputToken, uint256 minOutputAmount) = abi.decode(memoBytes, (address, uint256));        
        SwapType sushiSwapType;
        if (isETH(token)) {
            sushiSwapType = SwapType.ETH_TO_TOKEN;
        } else if (outputToken == sushiRouter.WETH()) {
            sushiSwapType = SwapType.TOKEN_TO_ETH;
        } else {
            sushiSwapType = SwapType.TOKEN_TO_TOKEN;
        }
        _swapOnSushiswapOut(
            sushiSwapType,
            token,
            amount,
            outputToken,
            minOutputAmount,
            router
        );
        emit CFReceive(srcChain, srcAddress, token, amount, router, "success sushi");
     } else if (swapType == 2) {
        // deposit ICHAINFLIP_LP
        bytes32 nodeID = abi.decode(memoBytes, (bytes32));
        token.safeApprove(router, amount);
        token.safeApprove(router, amount);
        ICHAINFLIP_LP(router).fundStateChainAccount(nodeID, amount);
    } else {
        emit SwapFailed(srcChain, srcAddress, token, amount, "Invalid swap type");
        return;
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
