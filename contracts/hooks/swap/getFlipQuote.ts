// import { constructOption } from "./fetchQuote";
// import { iRawQuote } from "@/types/quote";
// import { iSwapTypeData } from "@/types/swap";
// import { iToken } from "@/types/token";
// import {
//   SwapSDK,
//   Chains as MyChains,
//   Assets,
// } from "@chainflip/sdk/swap";
// import { useEffect, useMemo, useState } from "react";

// const assetMapping: { [key: string]: (typeof Assets)[keyof typeof Assets] } = {
//   BTC: Assets.BTC,
//   ETH: Assets.ETH,
//   USDT: Assets.USDT,
//   USDC: Assets.USDC,
//   DOT: Assets.DOT,
//   FLIP: Assets.FLIP,
// };

// const chainMapping: {
//   [key: string]: (typeof MyChains)[keyof typeof MyChains];
// } = {
//   BTC: MyChains.Bitcoin,
//   ETH: MyChains.Ethereum,
//   Polkadot: MyChains.Polkadot,
//   ARB: MyChains.Arbitrum,
// };
// const chainShortMapping: {
//   [key: string]: string;
// } = {
//   BTC: "btc",
//   ETH: "eth",
//   Polkadot: "dot",
//   ARB: "arb",
// };

// const getChainData = (chain: string) => {
//   const chains = [
//     {
//       chain: "Ethereum",
//       evmChainId: 1,
//       isMainnet: true,
//       name: "Ethereum",
//       requiredBlockConfirmations: 7,
//     },
//     {
//       chain: "Polkadot",
//       evmChainId: undefined,
//       isMainnet: true,
//       name: "Polkadot",
//       requiredBlockConfirmations: undefined,
//     },
//     {
//       chain: "Bitcoin",
//       evmChainId: undefined,
//       isMainnet: true,
//       name: "Bitcoin",
//       requiredBlockConfirmations: 3,
//     },
//   ];

//   return chains.find((c) => c.chain === chain);
// };

// const getAssetData = (chainData: any, asset: string) => {
//   const assets = [
//     {
//       asset: "ETH",
//       chain: "Ethereum",
//       chainflipId: "Eth",
//       contractAddress: undefined,
//       decimals: 18,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "1",
//       minimumSwapAmount: "10000000000000000",
//       name: "Ether",
//       symbol: "ETH",
//     },
//     {
//       asset: "ETH",
//       chain: "Arbitrum",
//       chainflipId: "Eth",
//       contractAddress: undefined,
//       decimals: 18,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "1",
//       minimumSwapAmount: "10000000000000000",
//       name: "Ether",
//       symbol: "ETH",
//     },
//     {
//       asset: "USDC",
//       chain: "Ethereum",
//       chainflipId: "Usdc",
//       contractAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
//       decimals: 6,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "1",
//       minimumSwapAmount: "20000000",
//       name: "USDC",
//       symbol: "USDC",
//     },
//     {
//       asset: "USDC",
//       chain: "Arbitrum",
//       chainflipId: "Usdc",
//       contractAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
//       decimals: 6,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "1",
//       minimumSwapAmount: "20000000",
//       name: "USDC",
//       symbol: "USDC",
//     },
//     {
//       asset: "FLIP",
//       chain: "Ethereum",
//       chainflipId: "Flip",
//       contractAddress: "0x826180541412D574cf1336d22c0C0a287822678A",
//       decimals: 18,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "1",
//       minimumSwapAmount: "4000000000000000000",
//       name: "FLIP",
//       symbol: "FLIP",
//     },
//     {
//       asset: "BTC",
//       chain: "Bitcoin",
//       chainflipId: "Btc",
//       contractAddress: undefined,
//       decimals: 8,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "600",
//       minimumSwapAmount: "70000",
//       name: "Bitcoin",
//       symbol: "BTC",
//     },
//     {
//       asset: "DOT",
//       chain: "Polkadot",
//       chainflipId: "Dot",
//       contractAddress: undefined,
//       decimals: 10,
//       isMainnet: true,
//       maximumSwapAmount: null,
//       minimumEgressAmount: "1",
//       minimumSwapAmount: "40000000000",
//       name: "Polkadot",
//       symbol: "DOT",
//     },
//   ];

//   return assets.find((a) => a.asset === asset && a.chain === chainData?.chain);
// };
// const convertToNormalAmount = (
//   chain: string,
//   asset: string,
//   formattedAmount: string
// ): string => {
//   const assetData = getAssetData(getChainData(chain), asset);

//   if (!assetData) {
//     console.error(`Asset ${asset} not found for chain ${chain}`);
//     return formattedAmount;
//   }

//   const { decimals } = assetData;
//   const normalAmount = (Number(formattedAmount) / 10 ** decimals).toString();
//   return normalAmount;
// };

// const getflipQuote = (to: iToken, from: iToken, amount: string) => {
//   const swapSDK = new SwapSDK({ network: "mainnet" });
//   const [flipQuotes, setFlipQuotes] = useState<iRawQuote[]>([]);

//   useEffect(() => {
//     if (!from || !to) {
//       setFlipQuotes([]);
//       return;
//     }
//     const selectedAsset = from.fullAsset
//       ? from.fullAsset?.split(".")[1].split("-")[0]
//       : from.coinKey;
//     const selectedChain = from.chain ? from.chain : "Ethereum";
//     const toAsset = to.fullAsset
//       ? to.fullAsset?.split(".")[1].split("-")[0]
//       : to.coinKey;
//     const toChain = to.chain ? to.chain : "Ethereum";
//     console.log("edewfewf ", toChain,  selectedChain)
//     console.log("ISITRUEEEEEE ",
//      ((selectedChain  ?? "") in chainMapping) )
//     if (
//       !amount ||
//       !selectedAsset ||
//       !selectedChain ||
//       !toAsset ||
//       !toChain ||
//       !(selectedAsset in assetMapping) ||
//       !(selectedChain in chainMapping) ||
//       !(toAsset in assetMapping) ||
//       !(toChain in chainMapping) ||
//       Number(amount) <= 0
//     ) {
//       setFlipQuotes([]);
//       return;
//     }
//     function sumAmountsByAsset(fees: any[]): { [asset: string]: number } {
//       const assetSums: { [asset: string]: number } = {};

//       for (const fee of fees) {
//         if (fee.asset) {
//           if (!assetSums[fee.asset]) {
//             assetSums[fee.asset] = 0;
//           }
//           assetSums[fee.asset] += fee.amount;
//         }
//       }

//       return assetSums;
//     }

//     function mapToUSD(allFees: any[], from: any, to: any): number {
//       const assetSums = sumAmountsByAsset(allFees);
//       let totalUSD = 0;

//       for (const asset in assetSums) {
//         if (asset === "usd.usd") {
//           totalUSD += assetSums[asset];
//         } else if (from.fullAsset.toLowerCase() === asset) {
//           totalUSD += assetSums[asset] * parseFloat(from.priceUSD);
//         } else if (to.fullAsset.toLowerCase() === asset) {
//           totalUSD += assetSums[asset] * parseFloat(to.priceUSD);
//         }
//       }

//       return totalUSD;
//     }

//     const fetchDataForAssets = async () => {
//       try {
//         const response = await fetch(
//           `https://chainflip-broker.io/quote?apiKey=64b58b30-13bd-4656-9a05-15560bc688cb&sourceAsset=${assetMapping[
//             selectedAsset
//           ].toLowerCase()}.${chainShortMapping[selectedChain]}&destinationAsset=${assetMapping[
//             toAsset
//           ].toLowerCase()}.${chainShortMapping[toChain]}&amount=${amount}`
//         );
//         const quoteChainFlip = await response.json();
//         console.log("quoteChainFlip", quoteChainFlip)
//         const transformQuote = (quote: any): iRawQuote => {
//           const transformedQuote: iRawQuote = {
//             tag: "chainflip",
//             fees: {
//               outbound:
//                 quote.includedFees.find((fee: any) => fee.type === "egress")
//                   ?.amount || "0",
//               liquidity:
//                 quote.includedFees.find((fee: any) => fee.type === "LIQUIDITY")
//                   ?.amount || "0",
//               affiliate: "0",
//               asset: to.fullAsset || "",
//               total: quote.includedFees.reduce((total: number, fee: any) => total + parseFloat(fee.amount), 0).toString(),
//             },
//             slippage_bps: 0,
//             all_fees: sumAmountsByAsset(quote.includedFees),
//             fees_usd: mapToUSD(quote.includedFees, from, to),
//             streaming_slippage_bps: 0, 
//             warning: quote.lowLiquidityWarning ? "Low liquidity warning" : "",
//             notes: "",
//             dust_threshold: "0", 
//             recommended_min_amount_in: quote.amount,
//             expected_amount_out: quote.egressAmount,
//             from: from,
//             to: to,
//             amount: quote.egressAmount,
//             expected_amount_out_streaming: quote.egressAmount,
//             max_streaming_quantity: 0, 
//             streaming_swap_blocks: 0,
//             streaming_swap_seconds: 0, 
//             total_swap_seconds: quote.estimatedDurationSeconds,
//             outbound_delay_blocks: 0, 
//             outbound_delay_seconds: 0,
//             expiry: 0,
//           };
//           return transformedQuote;
//         };
//         setFlipQuotes([transformQuote(quoteChainFlip)]);
//       } catch (error) {
//         console.error("Error fetching market data:", error);
//       }
//     };
//     const timeoutId = setTimeout(fetchDataForAssets, 500);
//     return () => clearTimeout(timeoutId);
//   }, [amount, from, to]);

//   const flipOptions = useMemo(() => {
//     if (!flipQuotes || flipQuotes.length === 0) {
//       return [] as iSwapTypeData[];
//     }
//     try {
//       return flipQuotes
//         .map((quote, index) => {
//           if (!quote || quote.error) return;
//           return constructOption(quote, amount, from, to, index);
//         })
//         .filter((option) => option !== undefined);
//     } catch (error) {
//       console.error(error);
//       return [];
//     }
//   }, [flipQuotes, amount, from, to]);

//   return { flipQuotes, flipOptions };
// };

// export default getflipQuote;
