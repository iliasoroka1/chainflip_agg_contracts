// import { THORNODE_BASE_URL, THORNODE_SWAP_QUOTE } from "@/constants";
// import { iRawQuote } from "@/types/quote";
// import { iSwapQuoteParams, iSwapTypeData } from "@/types/swap";
// import { iToken } from "@/types/token";
// import { bn } from "@/utils/bn";
// import { formatFrom, formatTo } from "@/utils/format";
// import { useState, useEffect, useMemo } from "react";
// import { constructOption, fetchQuote } from "./fetchQuote";
// import { ThornodePoolResponse } from "@/lib/thorService";
// import axios from "axios";
// import { generateError, throwNotification } from "@/utils/notification";

// export default function getThorQuote(
//   from: iToken,
//   to: iToken,
//   amount: string,
//   recipient: string,
// ) {
//   const [thorQuotes, setThorQuotes] = useState<iRawQuote[]>([]);
//   const [pools, setPools] = useState<ThornodePoolResponse[]>([]); // pools cache
//   const [thorOptions, setThorOptions] = useState<iSwapTypeData[]>([]);
//   useEffect(() => {
//     const getPoolData = async () => {
//       const maybePoolsResponse = await axios.get<ThornodePoolResponse[]>(
//         `${THORNODE_BASE_URL}/pools`
//       );
//       const { data: poolsResponse } = maybePoolsResponse;
//       setPools(poolsResponse);
//       };
//       const timeoutId = setTimeout(getPoolData, 5000);
//       return () => clearTimeout(timeoutId);
//   }, []);

//   const sellAssetPool = useMemo(() => pools.find((pool) => pool.asset === from.fullAsset), [pools, from]);
//   const buyAssetPool = useMemo(() => pools.find((pool) => pool.asset === to.fullAsset), [pools, to]);

//   const streamingInterval = useMemo(() => {
//     if (!sellAssetPool || !buyAssetPool) return 5; // default to 5 if we don't have pool data, mb 10?
//     const sellAssetDepthBps = sellAssetPool?.derived_depth_bps;
//     const buyAssetDepthBps = buyAssetPool?.derived_depth_bps;
//     const swapDepthBps = bn(sellAssetDepthBps).plus(buyAssetDepthBps).div(2);
//     if (swapDepthBps.lt(5000)) return 10;
//     if (swapDepthBps.lt(9000) && swapDepthBps.gte(5000)) return 5;
//     return 1;
//   }, [sellAssetPool, buyAssetPool]);

//   useEffect(() => {
//     if (!from || !to || (!from.swapper?.includes("streaming") || !to.swapper?.includes("streaming"))) {
//       setThorQuotes([]);
//       setThorOptions([]);
//       console.error("Thorchain not supported for this pair", from, to);
//       return;
//     }
//     if (Number(amount) <= 0) {
//       setThorQuotes([]);
//       setThorOptions([]);
//       console.error("Amount must be greater than 0", amount);
//       return;
//     }

//     const fetchQuotes = async () => {
//       setThorOptions([
//         {
//           amount: "0",
//           title: "Streaming",
//           time: 0,
//           isTimePositive: true,
//           isAmountPositive: true,
//           selected: "streaming",
//           token: "",
//           fromAmount: "",
//           index: 0,
//           swapper: "Thorchain"
//         },
//         {
//           amount: "0",
//           title: "Normal",
//           time: 0,
//           isTimePositive: true,
//           isAmountPositive: true,
//           selected: "normal",
//           token: "",
//           fromAmount: "",
//           index: 1,
//           swapper: "Thorchain"
//         }
//       ]);

//       const decimals = 8;
//       const params = {
//         from_asset: from.fullAsset,
//         to_asset: to.fullAsset,
//         amount: formatTo(amount, decimals),
//         affiliate_bps: 0,
//         affiliate: "kf",
//       } as iSwapQuoteParams;
//       if (recipient) params.destination = recipient;

//       const quoteSources = [
//         { source: THORNODE_SWAP_QUOTE, streaming: true, tag: "streaming" },
//         { source: THORNODE_SWAP_QUOTE, streaming: false, tag: "normal" },
//       ];

//       const start = performance.now();
//       const quotePromises = quoteSources
//         .filter(
//           (source) =>
//             from?.swapper?.includes(source.tag) && to?.swapper?.includes(source.tag)
//         )
//         .map((source) =>
//           fetchQuote(params, source.streaming, source.source, source.tag, streamingInterval)
//         );
//       const quotes: iRawQuote[] = (await Promise.all(quotePromises))
//         .filter((quote): quote is iRawQuote => quote !== undefined && !quote.error)
//         .map((quote) => {
//           quote.amount = formatFrom(quote.expected_amount_out ?? "0").toString();
//           return quote;
//         });
//       setThorQuotes(quotes);
//       // options
//       if (!quotes || quotes.length === 0) {
//         console.error("No quote found", quotes);
//         setThorOptions([]);
//         return;
//       }
//       console.log("Thorchain quotes", quotes);
//       try {
//         const options = quotes
//           .map((quote, index) => {
//             if (!quote || quote.error) return;
//             return constructOption(quote, amount, from, to, index);
//           })
//           .filter((option) => option !== undefined);
//         setThorOptions(options as iSwapTypeData[]);
//       } catch (error) {
//         console.error(error);
//         setThorOptions([]);
//       }
//     };

//     const timeoutId = setTimeout(fetchQuotes, 500);
//     return () => clearTimeout(timeoutId);
//   }, [amount, from, to, recipient]);

//   // const thorOptions = useMemo(() => {
//   //   if (!thorQuotes || thorQuotes.length === 0) {
//   //     return [];
//   //   }
//   //   try {
//   //     return thorQuotes
//   //       .map((quote, index) => {
//   //         if (!quote || quote.error) return;
//   //         return constructOption(quote, amount, from, to, index);
//   //       })
//   //       .filter((option) => option !== undefined)
//   //   } catch (error) {
//   //     console.error(error);
//   //     return [];
//   //   }
//   // }, [thorQuotes, amount, from, to]);

//   return { thorQuotes, thorOptions };
// };


