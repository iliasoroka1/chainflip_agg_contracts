// import { iRawQuote } from "@/types/quote";
// import { iSwapQuoteParams, iSwapType, iSwapTypeData } from "@/types/swap";
// import { iToken } from "@/types/token";
// import { formatFrom } from "@/utils/format";
// import { generateError, throwNotification } from "@/utils/notification";
// import { GiSpeedBoat } from "react-icons/gi";

// export async function fetchQuote(
//   params: iSwapQuoteParams,
//   isStreaming: boolean,
//   quoteUrl: string,
//   tag: string,
//   streamInterval: number = 5
// ): Promise<iRawQuote | undefined> {
//   try {
//     const url = new URL(quoteUrl);
//     Object.entries(params).forEach(([key, value]) => {
//       if (value !== undefined) url.searchParams.append(key, value.toString());
//     });
//     if (isStreaming) url.searchParams.append("streaming_interval", streamInterval.toFixed(0));
//     const response = await fetch(url, {
//       method: "GET",
//       headers: { "Content-Type": "application/json" },
//     });
//     const ret = await response.json();
//     if (ret.error) {
//       throwNotification(generateError(ret.error + " " + quoteUrl));
//       return undefined;
//     }
//     ret.tag = tag;
//     return ret;
//   } catch (error) {
//     console.error(
//       `Failed to get ${isStreaming ? "streaming" : "normal"} quote`,
//       error
//     );
//   }
// };

// export const constructOption = (
//   quote: iRawQuote,
//   amount: string,
//   from: iToken,
//   to: iToken,
//   index: number
// ): iSwapTypeData => {
//   const type = quote.tag as iSwapType;
//   const fees = quote.fees;
//   if (type === "chainflip") {
//     fees.total = quote.fees_usd;
//   } else {
//     fees.total = (Number(fees.total) * Number(to.priceUSD)).toFixed(2);
//   }
//   const token = quote.fees.asset.split(".")[1].split("-")[0];
//   return {
//     title: `${type === "streaming" ? "Thorchain" : type === "normal" ? "Thorchain" : type === "chainflip" ? "Chainflip" : "Maya"}`,
//     time: quote.total_swap_seconds ?? 0,
//     isTimePositive: quote.isCheapest ?? false,
//     amount: quote?.amount ?? "0",
//     isAmountPositive: quote.isFastest ?? false,
//     index: index,
//     selected: type,
//     token,
//     fromAmount: amount,
//     feesUSD: quote.fees_usd,
//     fees,
//     from,
//     to,
//     swapper: type === "maya" ? "Maya" : type === "normal" ? "Thorchain" : type === "chainflip" ? "Chainflip" : "Thorchain",
//     isStreaming: type === "streaming",
//     isCheapest: quote.isCheapest,
//     isFastest: quote.isFastest,
//   };
// };