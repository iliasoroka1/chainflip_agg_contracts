import { Chain } from '@/types/wallet'

const networkSwitch = (network: string) => {
  switch (network) {
    case Chain.THORChain:
      return 'thorchain'
    case Chain.BNB:
      return 'binance'
    case Chain.Dogecoin:
      return 'dogecoin'
    case Chain.Bitcoin:
      return 'bitcoin'
    case Chain.Litecoin:
      return 'litecoin'
    case Chain.BitcoinCash:
      return 'bitcoincash'
    case Chain.kuji:
      return 'kujira'
    case Chain.Maya:
      return 'mayachain'
    default:
      return undefined
  }
}

export const getXdefiNetworkPrimitive = (network: string) =>
  networkSwitch(network)
