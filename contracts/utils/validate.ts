import { CombChainKey } from "@/types/token";
var WAValidator = require("multicoin-address-validator");

export const validateAddress = (chain: CombChainKey | "" | string, address: string): boolean => {
  let regex: RegExp;

  switch (chain) {
    case "eth":
      return WAValidator.validate(address, "eth");
    case "ava":
      return WAValidator.validate(address, "avax");
    case "bsc":
      return WAValidator.validate(address, "eth");
    case "btc":
      return WAValidator.validate(address, "btc");
    case "ltc":
      return WAValidator.validate(address, "ltc");
    case "doge":
      return WAValidator.validate(address, "doge");
    case "gaia":
      regex = /^cosmos1[a-z0-9]{38}$/;
      break;
    case "thor":
      regex = /^thor1[a-z0-9]{38}$/;
      break;
    case "bch":
      return WAValidator.validate(address, "bch");
    case "kuji":
      return true; // TODO: Add regex for kuji
    case "maya":
      return true; // TODO: Add regex for maya
    default:
      return WAValidator.validate(address, "eth");
  }   
  return regex.test(address);
};