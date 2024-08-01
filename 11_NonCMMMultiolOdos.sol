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

contract ThorchainMayaChainflipCCMAggregator {

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
    address public odosRouter;

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
        string memo;
    }

    struct ChainflipParams {
        uint32 dstChain;
        bytes dstAddress;
        uint32 dstToken;
        address srcToken;
        uint256 amount;
        bytes cfParameters;
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
    constructor(address _cfVault, address _odosRouter) {
        _status = _NOT_ENTERED;
        cfVault = _cfVault; 
        odosRouter = _odosRouter;
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
        emit SwapExecuted("THORChain", params.token, amount, params.memo);
    }
}

function _executeChainflipSwap(ChainflipParams memory params, uint256 amount) internal {
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

function odosSwapThenChainflipMayaThor(
    bytes calldata swapData,
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 thorchainPercentage,
    uint256 mayaPercentage,
    ThorMayaParams memory thorMayaParams,
    ThorMayaParams memory MayaParams,
    ChainflipParams memory chainflipParams
) external payable {
    bool isInputEth = isETH(inputToken);

    if (isInputEth) {
        require(msg.value == inputAmount, "Incorrect ETH amount");
    } else {
        require(msg.value == 0, "ETH not accepted for token swaps");
        inputToken.safeTransferFrom(msg.sender, address(this), inputAmount);
        inputToken.safeApprove(odosRouter, inputAmount);
    }

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

    uint256 thorchainAmount = (outputAmount * thorchainPercentage) / 100;
    uint256 MayaAmount = (outputAmount * mayaPercentage) / 100;
    uint256 chainflipAmount = outputAmount - (thorchainAmount + MayaAmount);

    // Handle THORChain swap
    if (thorchainPercentage > 0) {
    _handleThorchainSwap(thorMayaParams.token, thorchainAmount, thorMayaParams);
    } 
    if (mayaPercentage > 0 ){
    _handleThorchainSwap(MayaParams.token, MayaAmount, MayaParams);
    }
     if (chainflipAmount > 0){
    _executeChainflipSwap(chainflipParams, chainflipAmount);
    }

    emit SwapExecuted("OdosThenChainflip", inputToken, inputAmount, "");


    }
function _handleThorchainSwap(
        address outputToken, 
        uint256 amount, 
        ThorMayaParams memory params
    ) internal {
        params.token = outputToken;
        _swapThorMaya(params, amount);
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
