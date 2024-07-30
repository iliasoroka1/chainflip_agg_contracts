declare global {
  interface Navigator {
    brave?: any
  }
  interface Window {
    ethereum?: any
    xfi: any
    keplr: any
    getOfflineSigner: any
    gtag: any
  }
}

export default global
