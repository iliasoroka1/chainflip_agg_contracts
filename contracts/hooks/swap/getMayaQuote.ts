// import { MAYA_SWAP_QUOTE } from "@/constants/maya";
// import { iRawQuote } from "@/types/quote";
// import { iSwapQuoteParams, iSwapTypeData } from "@/types/swap";
// import { iToken } from "@/types/token";
// import { formatFrom, formatTo } from "@/utils/format";
// import { useState, useEffect, useMemo } from "react";
// import { constructOption, fetchQuote } from "./fetchQuote";

// export default function getMayaQuote(
//   from: iToken,
//   to: iToken,
//   amount: string,
//   recipient: string,
// ) {
//   const [mayaQuotes, setMayaQuotes] = useState<iRawQuote[]>([]);
//   const [mayaOptions, setMayaOptions] = useState<iSwapTypeData[]>([]);
//   useEffect(() => {
//     if (!from?.swapper?.includes("maya")  || !to?.swapper?.includes("maya")) {
//       setMayaQuotes([]);
//       setMayaOptions([]);
//       return;
//     }
//     if ((!from || !to) || (!from?.swapper?.includes("maya") || !to?.swapper?.includes("maya"))) {
//       setMayaQuotes([]);
//       setMayaOptions([]);
//       return;
//     }
//     if (Number(amount) <= 0) return;
//     const decimals = from.chain === "MAYA" ? 10 : 8;
//     const params = { from_asset: from.fullAsset, to_asset: to.fullAsset, amount: formatTo(amount, decimals), affiliate_bps: 0, affiliate: "kf",} as iSwapQuoteParams;
//     if (recipient) params.destination = recipient;
//     // set a optimistic quote
//     // setMayaQuotes([{ amount: "0", total_swap_seconds: 0, tag: "maya", outbound_delay_blocks: 0, outbound_delay_seconds: 0, fees: {asset: "", outbound: ""}}]);
//     setMayaOptions([{
//       amount: "0",
//       title: "Maya",
//       time: 0,
//       isTimePositive: true,
//       isAmountPositive: true,
//       selected: "streaming",
//       token: "",
//       fromAmount: "",
//       index: 0,
//       swapper: "Maya"
//     }]);
//     const fetchMayaQuote = async () => {
//       const start = performance.now();
//       const quote = await fetchQuote(params, false, MAYA_SWAP_QUOTE, "maya")
//       if (!quote) return;
//       const dec = to.chain === "MAYA" ? 10 : 8;
//       quote.amount = formatFrom(quote.expected_amount_out ?? "0", dec).toString();
//       quote.total_swap_seconds = quote.outbound_delay_seconds + (quote.inbound_confirmation_seconds ?? 0);
//       quote.fees.total = (Number(quote?.fees?.outbound ?? "0") + Number(quote?.fees?.liquidity ?? "0") + Number(quote?.fees?.affiliate ?? "0")).toString();
//       setMayaQuotes([quote]);
//       if (!quote) {
//         setMayaOptions([]);
//         return;
//       }
//       try {
//         const option = constructOption(quote, amount, from, to, 0);
//         if (!option) {
//           setMayaOptions([]);
//           return;
//         }
//         setMayaOptions([option]);
//       } catch (error) {
//         console.error(error);
//         setMayaOptions([]);
//       }
//     };
    
//     const timeoutId = setTimeout(fetchMayaQuote, 500);
//     return () => clearTimeout(timeoutId);
//   }, [amount, from, to, recipient, fetchQuote]);

//   return { mayaQuotes, mayaOptions };
// };