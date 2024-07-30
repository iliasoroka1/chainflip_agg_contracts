export interface EncodingParams {
  swapType: number;
  router: string;
  chain?: string;
  inputToken?: string;
  inputAmount?: string;
  tokenName?: string;
  destinationAddress?: string;
  outputToken?: string;
  minOutputAmount?: string;
  nodeID?: string;
  finalToken?: string;
  swapSteps?: EncodedSwapStep[];
}

export  interface SwapStep {
  dex: number;
  tokenIn: string;
  tokenOut: string;
  amountIn: string;
  minAmountOut: string;
}

export  interface OdosAssemble {
  OdosRouter?: string;
  swapData?: string;
}


export  interface ChainflipCCMParams {
  dstChain: number;
  dstAddress: string;
  dstToken: number;
  srcToken: string;
  amount: string;
  message?: string;
  gasBudget: string;
  cfParameters  : string;
}

export  interface EVMin {
  inputToken?: string;
  inputAmount?: string;
  finalToken?: string;
}

export  interface OdosInputs {
  odosRouter?: string;
  SwapData?: string;
  inputToken?: string;
  outputToken?: string;
  inputAmount?: string;
  minOutputAmount?: string;
}

export  interface EncodedSwapStep {
  dex: number; // 0 for Uniswap, 1 for Sushiswap
  percentage: number;
  tokenOut: string;
}

export interface ThorchainParams {
  vault: string;
  router: string;
  asset: string;
  memo: string;
}