import { iPool } from '@/types/api'
import { iPrices } from '@/types/token'

export const getPrices = (pools: iPool[]) => {
  const prices: iPrices = {}

  pools.forEach((token) => {
    prices[token.asset.toLowerCase()] = Number(token.assetPriceUSD)

    // SYNTH ASSET
    prices[
      `thor.${token.asset.toLowerCase().split('.')[0]}/${
        token.asset.toLowerCase().split('.')[1]
      }`
    ] = Number(token.assetPriceUSD)
  })

  prices['thor.rune'] = Number(
    (parseFloat(pools[0].assetDepth) * parseFloat(pools[0].assetPriceUSD)) /
      parseFloat(pools[0].runeDepth)
  )

  return prices
}
