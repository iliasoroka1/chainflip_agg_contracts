import { iQuote, iRawQuote } from "@/types/quote";

export const parseSwapQuotes = (
  normalQuote: iRawQuote,
  streamingQuote: iRawQuote
) => {
  return {
    inbound_address: streamingQuote.inbound_address,
    router: streamingQuote.router,
    memo: streamingQuote.memo,
    fees_normal: normalQuote.fees,
    fees_streaming: streamingQuote.fees,
    slippage_bps_normal: (normalQuote?.slippage_bps ?? 0) / 100,
    slippage_bps_streaming: (streamingQuote?.streaming_slippage_bps ?? 0) / 100,
    expected_amount_out_normal: normalQuote.expected_amount_out,
    expected_amount_out_streaming: streamingQuote.expected_amount_out_streaming,
    expiry: streamingQuote.expiry,
    total_swap_seconds_normal: normalQuote.total_swap_seconds,
    total_swap_seconds_streaming: streamingQuote.total_swap_seconds,
    is_streaming_better:
      Number(normalQuote.expected_amount_out) <
      Number(streamingQuote.expected_amount_out_streaming),
    is_streaming_faster:
      (normalQuote?.total_swap_seconds ?? 0) <= (streamingQuote?.total_swap_seconds ?? 0 ),
  } as iQuote;
};
