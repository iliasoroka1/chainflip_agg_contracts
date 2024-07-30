import { Network } from '@xchainjs/xchain-client'

export const atomClientUrls = {
  [Network.Stagenet]: 'https://lcd-cosmos.cosmostation.io',
  [Network.Mainnet]:
    'https://cosmoshub-4--lcd--full.datahub.figment.io/apikey/29997079b2fe2b93e103930a7d24f03d',
  [Network.Testnet]: 'https://rest.sentry-01.theta-testnet.polypore.xyz',
}

export const ltcNodeUrls = {
  [Network.Mainnet]: 'https://litecoin.ninerealms.com',
  [Network.Stagenet]: 'https://litecoin.ninerealms.com',
  [Network.Testnet]: 'https://testnet.ltc.thorchain.info',
}

export const thorChainIds = {
  [Network.Mainnet]: 'thorchain-mainnet-v1',
  [Network.Stagenet]: 'thorchain-stagenet-v1',
  [Network.Testnet]: 'thorchain-testnet-v2',
}
