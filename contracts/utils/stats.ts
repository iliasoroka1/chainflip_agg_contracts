import { iInboundAddresses, iInboundGasRates } from '@/types/api'

export const gasRates = (inbound: iInboundAddresses[]) => {
  const gasRate: iInboundGasRates[] = []

  for (let i = 0; i < inbound.length; i++) {
    gasRate.push({
      chain: inbound[i].chain,
      gas:
        inbound[i].chain === 'BNB' || inbound[i].chain === 'GAIA'
          ? parseFloat(inbound[i].gas_rate) / 10 ** 8
          : inbound[i].chain === 'ETH'
          ? (parseFloat(inbound[i].gas_rate) * 35) / 10 ** 6
          : (parseFloat(inbound[i].gas_rate) * 250) / 10 ** 8,
    })
  }
  gasRate.push({ chain: 'THOR', gas: 0.02 })

  // console.log(gasRate)
  return gasRate
}
