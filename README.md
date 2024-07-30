# 1_ChainflipCCMAggregatorSU Smart Contract

This smart contract serves as an aggregator for cross-chain swaps, primarily focusing on EVM-compatible DEXes (Uniswap and Sushiswap) and Chainflip Cross-Chain Messaging (CCM).

## Main Features

1. Swap tokens on EVM-compatible DEXes (Uniswap and Sushiswap)
2. Execute cross-chain swaps using Chainflip CCM
3. Combine EVM swaps with Chainflip CCM swaps

## Contract Functions

### 1. swapViaChainflipCCM

Executes a swap directly through Chainflip CCM.

Inputs:
- `ChainflipCCMParams`: A struct containing:
  - `dstChain`: Destination chain ID
  - `dstAddress`: Destination address
  - `dstToken`: Destination token ID
  - `srcToken`: Source token address
  - `amount`: Amount to swap
  - `message`: Additional message data
  - `gasBudget`: Gas budget for the transaction
  - `cfParameters`: Chainflip-specific parameters

### 2. EVMThenChainflipCCM

Executes swaps on EVM-compatible DEXes (Uniswap/Sushiswap) before performing a Chainflip CCM swap.

Inputs:
- `inputToken`: Address of the input token
- `inputAmount`: Amount of input token to swap
- `steps`: Array of `EncodedSwapStep` structs defining the swap path
- `chainflipParams`: `ChainflipCCMParams` struct for the final Chainflip CCM swap

### 3. approveRouter

Approves a router address for swaps (owner-only function).

Input:
- `router`: Address of the router to approve

### 4. revokeRouterApproval

Revokes approval for a router address (owner-only function).

Input:
- `router`: Address of the router to revoke approval from

### 5. rescueFunds

Allows the owner to rescue funds from the contract (owner-only function).

Inputs:
- `asset`: Address of the asset to rescue
- `amount`: Amount to rescue
- `destination`: Address to send the rescued funds to

## Main Logic

1. The contract supports swapping between ETH and ERC20 tokens.
2. It can execute swaps on Uniswap and Sushiswap, splitting the input amount between them if needed.
3. For Chainflip CCM swaps, it supports both native (ETH) and token transfers.
4. The contract uses a reentrancy guard to prevent reentrancy attacks.
5. It implements approval mechanisms for DEX routers to ensure smooth token transfers.

## Key Structs

1. `ChainflipCCMParams`: Contains parameters for Chainflip CCM swaps.
2. `EncodedSwapStep`: Defines a single step in a multi-step swap, including the DEX, percentage of input to use, and output token.
3. `SwapStep`: Used internally to represent a swap step with additional details like minimum output amount.

## Enums

1. `SwapType`: Defines types of swaps (ETH_TO_TOKEN, TOKEN_TO_TOKEN, TOKEN_TO_ETH).
2. `DEX`: Enumerates supported DEXes (UNISWAP, SUSHISWAP, THORCHAIN, MAYA, CHAINFLIP).

## Events

1. `SwapFailed`: Emitted when a swap fails, providing details about the failure.
2. `SwapExecuted`: Emitted when a swap is successfully executed, providing swap details.

# ChainflipCCMAggregatorOdos Smart Contract

This smart contract serves as an aggregator for cross-chain swaps, primarily focusing on Odos router, Chainflip Cross-Chain Messaging (CCM), THORChain, and Maya.

## Main Features

1. Execute swaps using Odos router
2. Perform cross-chain swaps using Chainflip CCM
3. Swap tokens on THORChain and Maya
4. Combine Odos swaps with Chainflip CCM or THORChain/Maya swaps

## Contract Functions

### 1. odosSwapThenChainflip

Executes a swap using Odos router and then performs a Chainflip CCM swap.

Inputs:
- `odosRouter`: Address of the Odos router
- `swapData`: Encoded swap data for Odos router
- `inputToken`: Address of the input token
- `outputToken`: Address of the output token
- `inputAmount`: Amount of input token to swap
- `minOutputAmount`: Minimum expected output amount
- `chainflipParams`: `ChainflipCCMParams` struct for the Chainflip CCM swap

### 2. OdosThor

Executes a swap using Odos router and then performs a THORChain or Maya swap.

Inputs:
- `inputToken`: Address of the input token
- `inputAmount`: Amount of input token to swap
- `odosRouter`: Address of the Odos router
- `swapData`: Encoded swap data for Odos router
- `outputToken`: Address of the output token
- `thorMayaParams`: `ThorMayaParams` struct for the THORChain or Maya swap

### 3. approveRouter

Approves a router address for swaps (owner-only function).

Input:
- `router`: Address of the router to approve

### 4. revokeRouterApproval

Revokes approval for a router address (owner-only function).

Input:
- `router`: Address of the router to revoke approval from

### 5. rescueFunds

Allows the owner to rescue funds from the contract (owner-only function).

Inputs:
- `asset`: Address of the asset to rescue
- `amount`: Amount to rescue
- `destination`: Address to send the rescued funds to

## Main Logic

1. The contract supports swapping between ETH and ERC20 tokens.
2. It can execute swaps using the Odos router for optimal routing.
3. For Chainflip CCM swaps, it supports both native (ETH) and token transfers.
4. THORChain and Maya swaps are supported through their respective protocols.
5. The contract uses a reentrancy guard to prevent reentrancy attacks.
6. It implements approval mechanisms for routers to ensure smooth token transfers.

# ThorchainAggregatorSU Smart Contract

This smart contract serves as an aggregator for cross-chain swaps, primarily focusing on Uniswap, Sushiswap, and THORChain/Maya.

## Main Features

1. Execute swaps on Uniswap and Sushiswap
2. Perform swaps on THORChain/Maya
3. Combine EVM-compatible DEX swaps (Uniswap/Sushiswap) with THORChain swaps

## Contract Functions

### 1. EVMThenThor

Executes swaps on EVM-compatible DEXes (Uniswap/Sushiswap) and then performs a THORChain swap.

Inputs:
- `inputToken`: Address of the input token
- `inputAmount`: Amount of input token to swap
- `steps`: Array of `EncodedSwapStep` structs defining the swap path
- `thorMayaParams`: `ThorMayaParams` struct for the THORChain swap

### 2. approveRouter

Approves a router address for swaps (owner-only function).

Input:
- `router`: Address of the router to approve

### 3. revokeRouterApproval

Revokes approval for a router address (owner-only function).

Input:
- `router`: Address of the router to revoke approval from

### 4. rescueFunds

Allows the owner to rescue funds from the contract (owner-only function).

Inputs:
- `asset`: Address of the asset to rescue
- `amount`: Amount to rescue
- `destination`: Address to send the rescued funds to

## Main Logic

1. The contract supports swapping between ETH and ERC20 tokens.
2. It can execute swaps on Uniswap and Sushiswap, with the ability to split the input amount between them.
3. THORChain/Maya swaps are supported through their respective protocols.
4. The contract uses a reentrancy guard to prevent reentrancy attacks.
5. It implements approval mechanisms for DEX routers to ensure smooth token transfers.

# ThorchainMayaChainflipCCMAggregatorOut Smart Contract

This smart contract serves as an aggregator for cross-chain swaps, integrating Uniswap, Sushiswap, THORChain, Maya, and Chainflip Cross-Chain Messaging (CCM).

## Main Features

1. Execute swaps on Uniswap and Sushiswap
2. Perform swaps on THORChain and Maya
3. Execute cross-chain swaps using Chainflip CCM
4. Handle incoming cross-chain transfers and execute subsequent swaps

## Key Functions

### 1. _swapThorMaya

Executes a swap on THORChain or Maya.

Inputs:
- `ThorMayaParams`: Struct containing swap parameters

### 2. _executeChainflipCCMSwap

Executes a cross-chain swap using Chainflip CCM.

Inputs:
- `srcToken`: Source token address
- `amount`: Amount to swap
- `gasBudget`: Gas budget for the transaction
- `ChainflipCCMParams`: Struct containing CCM parameters

### 3. _executeAdvancedSwap

Executes a multi-step swap across Uniswap and Sushiswap.

Inputs:
- `token`: Input token address
- `amount`: Amount to swap
- `encodedSteps`: Array of `EncodedSwapStep` structs defining the swap path

### 4. cfReceive

Handles incoming cross-chain transfers and executes subsequent actions.

Inputs:
- `srcChain`: Source chain ID
- `srcAddress`: Source address
- `message`: Encoded message containing swap instructions
- `token`: Received token address
- `amount`: Received amount

### 5. approveRouter

Approves a router address for swaps (owner-only function).

### 6. revokeRouterApproval

Revokes approval for a router address (owner-only function).

### 7. rescueFunds

Allows the owner to rescue funds from the contract (owner-only function).

## Key Structs

1. `ThorMayaParams`: Parameters for THORChain and Maya swaps
2. `ChainflipCCMParams`: Parameters for Chainflip CCM swaps
3. `EncodedSwapStep`: Defines a single step in a multi-step swap
4. `SwapStep`: Used internally to represent a swap step with additional details

## Enums

1. `SwapType`: ETH_TO_TOKEN, TOKEN_TO_TOKEN, TOKEN_TO_ETH
2. `DEX`: UNISWAP, SUSHISWAP, THORCHAIN, MAYA, CHAINFLIP

## Events

1. `SwapFailed`: Emitted when a swap fails
2. `SwapExecuted`: Emitted when a swap is successfully executed
3. `CFReceive`: Emitted when funds are received through Chainflip CCM

## Main Logic Flow

1. The contract can receive cross-chain transfers through the `cfReceive` function.
2. Based on the encoded message in the transfer, it can:
   a. Execute a THORChain/Maya swap
   b. Perform an advanced swap on Uniswap and/or Sushiswap
   c. Deposit funds into a Chainflip LP
3. For advanced swaps, it can split the input amount between Uniswap and Sushiswap for potentially better rates.
4. The contract handles ETH and ERC20 token swaps.
5. It implements security measures like reentrancy guards and owner-only functions.
# ChainflipAggregator Smart Contract

This smart contract serves as an aggregator for cross-chain swaps, integrating Uniswap, Sushiswap, and Chainflip for efficient token exchanges across different blockchains.

## Main Features

1. Execute swaps on Uniswap and Sushiswap
2. Perform cross-chain swaps using Chainflip
3. Combine EVM-compatible DEX swaps with Chainflip swaps
4. Support for Odos router integration

## Key Functions

### 1. swapViaChainflip

Executes a direct swap using Chainflip.

Inputs:
- `ChainflipParams`: Struct containing swap parameters

### 2. odosSwapThenChainflip

Executes a swap using Odos router and then performs a Chainflip swap.

Inputs:
- `odosRouter`: Address of the Odos router
- `swapData`: Encoded swap data for Odos router
- `inputToken`: Address of the input token
- `outputToken`: Address of the output token
- `inputAmount`: Amount of input token to swap
- `minOutputAmount`: Minimum expected output amount
- `chainflipParams`: `ChainflipParams` struct for the Chainflip swap

### 3. EVMThenChainflip

Executes swaps on EVM-compatible DEXes (Uniswap/Sushiswap) and then performs a Chainflip swap.

Inputs:
- `inputToken`: Address of the input token
- `inputAmount`: Amount of input token to swap
- `steps`: Array of `EncodedSwapStep` structs defining the swap path
- `chainflipParams`: `ChainflipParams` struct for the Chainflip swap


## Core Logic
Direct Chainflip Swaps:
The swapViaChainflip function allows users to perform cross-chain swaps directly using Chainflip. This is useful for simple, single-step cross-chain transfers. The function checks the input, processes the swap, and emits a SwapExecuted event.
Odos Router Integration:
The odosSwapThenChainflip function combines the efficiency of the Odos router with Chainflip's cross-chain capabilities. It first executes a swap using the Odos router (which can potentially route through multiple DEXes for optimal rates) and then performs a Chainflip swap with the output. This function is particularly useful for complex swaps that require optimized routing before cross-chain transfer.
EVM-DEX and Chainflip Combination:
The EVMThenChainflip function allows for multi-step swaps on Uniswap and/or Sushiswap before executing a Chainflip swap. This function uses the _executeAdvancedSwap internal function, which can split the input amount between Uniswap and Sushiswap for potentially better rates. The swap path is defined using EncodedSwapStep structs, allowing for flexible and customizable swap routes.

Key Internal Functions:

_executeChainflipSwap: Handles the actual Chainflip swap execution, supporting both native (ETH) and token swaps.
_executeAdvancedSwap: Manages the complex logic for splitting swaps between Uniswap and Sushiswap.
_swapOnUniswap and _swapOnSushiswap: Execute swaps on their respective DEXes.
_createPath: Builds the token path for Uniswap or Sushiswap swaps based on the provided steps.

# THOROutETH Smart Contract

## Overview

THOROutETH is a specialized smart contract designed to facilitate ETH to token swaps using Uniswap. It's particularly useful for scenarios where users need to swap incoming ETH for specific tokens, such as in cross-chain operations or decentralized applications requiring token conversions.

## Key Features

1. ETH to Token swaps using Uniswap
2. Minimum output amount protection
3. Reentrancy protection
4. Owner-only fund rescue functionality

## Contract Structure

### Main Function

`swapOut`: Executes an ETH to token swap

### Modifiers

1. `nonReentrant`: Prevents reentrancy attacks
2. `onlyOwner`: Restricts access to owner-only functions

### Events

`SwapOut`: Emitted when a successful swap occurs

## Core Logic

The core functionality of THOROutETH revolves around the `swapOut` function:

1. Input Validation:
   - The function requires a positive ETH amount to be sent with the transaction.
   - It takes parameters for the desired output token, recipient address, and minimum output amount.

2. Swap Path Creation:
   - A swap path is created from WETH (Wrapped ETH) to the desired output token.

3. Uniswap Interaction:
   - The contract calls Uniswap's `swapExactETHForTokens` function, passing along the received ETH.
   - It sets a maximum deadline (type(uint).max) to ensure the transaction doesn't fail due to time constraints.

4. Output Verification:
   - After the swap, the contract verifies that the received token amount meets or exceeds the specified minimum output amount.

5. Event Emission:
   - A `SwapOut` event is emitted with details of the swap for off-chain tracking and verification.

## Security Measures

1. Reentrancy Guard:
   - The `nonReentrant` modifier prevents potential reentrancy attacks during the swap process.

2. Safe Transfers:
   - The contract uses SafeTransferLib for secure token transfers in the `rescueFunds` function.

3. Owner-only Access:
   - Critical functions like `rescueFunds` are restricted to the contract owner.

## Additional Functionality

`rescueFunds`: Allows the owner to recover any tokens or ETH mistakenly sent to the contract, ensuring no funds are permanently locked.

## Usage Considerations

- This contract is designed for unidirectional swaps from ETH to tokens.
- Users should be aware of the minimum output amount they're willing to accept to protect against slippage.
- The contract doesn't handle token approvals, so it's suitable for direct ETH input scenarios.

## Potential Use Cases

1. Cross-chain bridges where incoming ETH needs to be swapped to specific tokens.
2. DApps requiring automatic conversion of user-provided ETH to project-specific tokens.
3. Aggregators or routers that need a simple ETH-to-token swap component.

The THOROutETH contract provides a straightforward and secure way to perform ETH to token swaps, making it a valuable component in various DeFi and cross-chain applications.

# THOROutETH Smart Contract

## Overview

THORChainChainflipAggregator is a specialized smart contract designed to facilitate cross-chain swaps using the Chainflip protocol. It allows users to swap ETH for various tokens across different blockchain networks.

## Key Features

1. Cross-chain ETH to token swaps using Chainflip
2. Support for multiple destination chains and tokens
3. Reentrancy protection
4. Owner-only fund rescue functionality

## Contract Structure

### Main Function

`swapOut`: Executes an ETH to token swap across chains

### State Variables

1. `assetToChainflipID`: Mapping of token addresses to Chainflip asset IDs
2. `assetToChainID`: Mapping of Chainflip asset IDs to destination chain IDs

### Modifiers

1. `nonReentrant`: Prevents reentrancy attacks
2. `onlyOwner`: Restricts access to owner-only functions

### Events

`SwapOut`: Emitted when a successful swap occurs

## Core Logic

The core functionality of THORChainChainflipAggregator revolves around the `swapOut` function:

1. Input Validation:
   - The function requires a positive ETH amount to be sent with the transaction.
   - It takes parameters for the desired output token, recipient address, and minimum output amount (note: minimum output amount is not currently used in the swap logic).

2. Token and Chain Identification:
   - The contract uses the `assetToChainflipID` mapping to identify the Chainflip asset ID for the requested token.
   - It then uses the `assetToChainID` mapping to determine the destination chain ID based on the asset ID.

3. Chainflip Interaction:
   - The contract calls Chainflip's `xSwapNative` function, passing along the received ETH, destination chain ID, recipient address, and destination token ID.

4. Event Emission:
   - A `SwapOut` event is emitted with details of the swap for off-chain tracking and verification.

## Security Measures

1. Reentrancy Guard:
   - The `nonReentrant` modifier prevents potential reentrancy attacks during the swap process.

2. Safe Transfers:
   - The contract uses SafeTransferLib for secure token transfers in the `rescueFunds` function.

3. Owner-only Access:
   - Critical functions like `rescueFunds` are restricted to the contract owner.

## Additional Functionality

`rescueFunds`: Allows the owner to recover any tokens or ETH mistakenly sent to the contract, ensuring no funds are permanently locked.

## Asset and Chain Mappings

The contract initializes mappings for supported assets and their corresponding chains:

- ETH, FLIP, and USDC are mapped to Ethereum
- DOT is mapped to Polkadot
- BTC is mapped to Bitcoin

These mappings are crucial for determining the correct destination chain and asset ID for each swap.

## Usage Considerations

- This contract is designed for unidirectional swaps from ETH to various tokens across different chains.
- The contract doesn't handle slippage protection on the Chainflip side, so users should be aware of potential price movements.
- Only predefined tokens and destination chains are supported.

## Potential Use Cases

1. Cross-chain DeFi applications requiring ETH to token swaps across different networks.
2. Integration with THORChain or other cross-chain protocols to expand swap options.
3. Simplified user interface for cross-chain swaps, abstracting away the complexities of multiple protocols.

The THORChainChainflipAggregator contract provides a streamlined way to perform cross-chain ETH to token swaps using the Chainflip protocol, making it a valuable component in cross-chain DeFi ecosystems.

# THORChainOutChainflipETH Smart Contract

## Overview

THORChainChainflipAggregator is a specialized smart contract designed to facilitate cross-chain swaps using the Chainflip protocol. It allows users to swap ETH for various tokens across different blockchain networks.

## Key Features

1. Cross-chain ETH to token swaps using Chainflip
2. Support for multiple destination chains and tokens
3. Reentrancy protection
4. Owner-only fund rescue functionality

## Contract Structure

### Main Function

`swapOut`: Executes an ETH to token swap across chains

### State Variables

1. `assetToChainflipID`: Mapping of token addresses to Chainflip asset IDs
2. `assetToChainID`: Mapping of Chainflip asset IDs to destination chain IDs

### Modifiers

1. `nonReentrant`: Prevents reentrancy attacks
2. `onlyOwner`: Restricts access to owner-only functions

### Events

`SwapOut`: Emitted when a successful swap occurs

## Core Logic

The core functionality of THORChainOutChainflipETH revolves around the `swapOut` function:

1. Input Validation:
   - The function requires a positive ETH amount to be sent with the transaction.
   - It takes parameters for the desired output token, recipient address, and minimum output amount (note: minimum output amount is not currently used in the swap logic).

2. Token and Chain Identification:
   - The contract uses the `assetToChainflipID` mapping to identify the Chainflip asset ID for the requested token.
   - It then uses the `assetToChainID` mapping to determine the destination chain ID based on the asset ID.

3. Chainflip Interaction:
   - The contract calls Chainflip's `xSwapNative` function, passing along the received ETH, destination chain ID, recipient address, and destination token ID.

4. Event Emission:
   - A `SwapOut` event is emitted with details of the swap for off-chain tracking and verification.

## Security Measures

1. Reentrancy Guard:
   - The `nonReentrant` modifier prevents potential reentrancy attacks during the swap process.

2. Safe Transfers:
   - The contract uses SafeTransferLib for secure token transfers in the `rescueFunds` function.

3. Owner-only Access:
   - Critical functions like `rescueFunds` are restricted to the contract owner.

## Additional Functionality

`rescueFunds`: Allows the owner to recover any tokens or ETH mistakenly sent to the contract, ensuring no funds are permanently locked.

## Asset and Chain Mappings

The contract initializes mappings for supported assets and their corresponding chains:

- ETH, FLIP, and USDC are mapped to Ethereum
- DOT is mapped to Polkadot
- BTC is mapped to Bitcoin

These mappings are crucial for determining the correct destination chain and asset ID for each swap.

## Usage Considerations

- This contract is designed for unidirectional swaps from ETH to various tokens across different chains.
- The contract doesn't handle slippage protection on the Chainflip side, so users should be aware of potential price movements.
- Only predefined tokens and destination chains are supported.

## Potential Use Cases

1. Cross-chain DeFi applications requiring ETH to token swaps across different networks.
2. Integration with THORChain or other cross-chain protocols to expand swap options.
3. Simplified user interface for cross-chain swaps, abstracting away the complexities of multiple protocols.

The THORChainOutChainflipETH contract provides a streamlined way to perform cross-chain ETH to token swaps using the Chainflip protocol, making it a valuable component in cross-chain DeFi ecosystems.
# THORChainOutARB Smart Contract

## Overview

THORChainOutARB is a specialized smart contract designed to facilitate cross-chain swaps from Ethereum to various networks, with a particular focus on Arbitrum. It leverages the Chainflip protocol to enable users to swap ETH for tokens on different blockchains, including Polkadot, Bitcoin, and Arbitrum.

## Key Features

1. Cross-chain ETH to token swaps using Chainflip
2. Support for multiple destination chains: Polkadot, Bitcoin, and Arbitrum
3. Support for various tokens including DOT, BTC, arbETH, arbUSDC, and USDT
4. Reentrancy protection
5. Owner-only fund rescue functionality

## Contract Structure

### Main Function

`swapOut`: Executes an ETH to token swap across chains

### State Variables

1. `assetToChainflipID`: Mapping of token addresses to Chainflip asset IDs
2. `assetToChainID`: Mapping of Chainflip asset IDs to destination chain IDs

### Modifiers

1. `nonReentrant`: Prevents reentrancy attacks
2. `onlyOwner`: Restricts access to owner-only functions

### Events

`SwapOut`: Emitted when a successful swap occurs

## Core Logic

The core functionality of THORChainOutARB revolves around the `swapOut` function:

1. Input Validation:
   - The function requires a positive ETH amount to be sent with the transaction.
   - It takes parameters for the desired output token, recipient address, and minimum output amount (note: minimum output amount is not currently used in the swap logic).

2. Token and Chain Identification:
   - The contract uses the `assetToChainflipID` mapping to identify the Chainflip asset ID for the requested token.
   - It then uses the `assetToChainID` mapping to determine the destination chain ID based on the asset ID.

3. Chainflip Interaction:
   - The contract calls Chainflip's `xSwapNative` function, passing along the received ETH, destination chain ID, recipient address, and destination token ID.

4. Event Emission:
   - A `SwapOut` event is emitted with details of the swap for off-chain tracking and verification.

## Asset and Chain Mappings

The contract initializes mappings for supported assets and their corresponding chains:

- DOT is mapped to Polkadot (Chain ID: 2)
- BTC is mapped to Bitcoin (Chain ID: 3)
- arbETH, arbUSDC, and USDT are mapped to Arbitrum (Chain ID: 4)

These mappings are crucial for determining the correct destination chain and asset ID for each swap.

## Security Measures

1. Reentrancy Guard:
   - The `nonReentrant` modifier prevents potential reentrancy attacks during the swap process.

2. Safe Transfers:
   - The contract uses SafeTransferLib for secure token transfers in the `rescueFunds` function.

3. Owner-only Access:
   - Critical functions like `rescueFunds` are restricted to the contract owner.

## Additional Functionality

`rescueFunds`: Allows the owner to recover any tokens or ETH mistakenly sent to the contract, ensuring no funds are permanently locked.

## Usage Considerations

- This contract is designed for unidirectional swaps from ETH to various tokens across different chains, with a focus on Arbitrum.
- The contract doesn't handle slippage protection on the Chainflip side, so users should be aware of potential price movements.
- Only predefined tokens and destination chains are supported.
- The contract is specifically tailored for swaps to Polkadot, Bitcoin, and Arbitrum networks.

## Potential Use Cases

1. Cross-chain DeFi applications requiring ETH to token swaps, especially those focusing on Arbitrum integration.
2. Bridging liquidity between Ethereum and Arbitrum ecosystems.
3. Enabling users to easily move assets from Ethereum to Polkadot, Bitcoin, or Arbitrum in a single transaction.
4. Integration with THORChain or other cross-chain protocols to expand swap options and reach.

The THORChainOutARB contract provides a streamlined way to perform cross-chain ETH to token swaps using the Chainflip protocol, with a particular emphasis on facilitating transfers to the Arbitrum network.
