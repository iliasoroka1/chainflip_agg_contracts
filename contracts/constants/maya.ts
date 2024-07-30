// COINGECKO STATS ENDPOINT
// export const COINGECKO_STATS_ENDPOINT =
//   'https://api.coingecko.com/api/v3/coins/thorchain'

// EVM CHAIN RPCS
export const ETH_RPC = "https://rpc.ankr.com/eth";
export const AVAX_RPC = "https://rpc.ankr.com/avalanche";
export const BSC_RPC = "https://rpc.ankr.com/bsc";

// COSMOS NODE RPC URL
export const COSMOS_NODE_RPC_URL =
  "https://go.getblock.io/831d7c056cec4df1890d0ef4e5585c1d";

// EVM CHAIN IDS
export const CHAIN_IDS = {
  ETH: 1,
  AVAX: 43114,
  BSC: 56,
};

// THORNODE BASE URL
export const MAYA_BASE_URL = "https://mayanode.mayachain.info/mayachain/";

// MIDGARD BASE URL
export const MAYA_MIDGARD_BASE_URL = "https://midgard.mayachain.info/v2/";

// NETWORK
export const MAYA_INBOUND_ADDRESSES = MAYA_BASE_URL + "inbound_addresses";

export const MAYA_MIDGARD_POOLS = MAYA_MIDGARD_BASE_URL + "pools?period=1h";

// QUOTES
export const MAYA_SWAP_QUOTE = MAYA_BASE_URL + "quote/swap";
export const MAYA_ADD_SAVER_QUOTE = MAYA_BASE_URL + "quote/saver/deposit";
export const MAYA_WITHDRAW_SAVER_QUOTE = MAYA_BASE_URL + "quote/saver/withdraw";

export const MAYANODE_TRANSACTION_ENDPOINT = MAYA_BASE_URL + "tx/";
// https://midgard.ninerealms.com/v2/actions?offset=0&limit=10&txid=7EA78EB424283552569AD7B4889132A7B1042E81F0A2C0EFE0E7C8CF23585D44
