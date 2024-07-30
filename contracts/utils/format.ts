import { mainnetTokens } from "@/services/tokens/tokens";
import { iToken } from "@/types/token";
import BigNumber from "bignumber.js";

export const getFullAssetFromName = (fullAsset: string): iToken | undefined => {
  for (let i = 0; i < mainnetTokens.length; i++) {
    if (mainnetTokens[i]?.fullAsset?.toUpperCase() === fullAsset) {
      return mainnetTokens[i];
    }
  }

  return undefined;
};

export const getAllErc20Tokens = (chain: string) => {
  let allErc20Tokens = [];
  for (let i = 0; i < mainnetTokens.length; i++) {
    if (
      (mainnetTokens[i].chain === chain.toUpperCase() ||
        mainnetTokens[i].chain === chain.toLowerCase()) &&
      mainnetTokens[i].type !== "NATIVE"
    ) {
      allErc20Tokens.push(mainnetTokens[i]);
    }
  }
  return allErc20Tokens;
};



export const getContractAddressFromToken = (tokenName: string | undefined) => {
  if (!tokenName) return undefined;
  try {
    return tokenName.split("-")[1]?.toLowerCase();
  } catch (_) {
    return undefined;
  }
};

export const formatAddress = (address: string, slice = 4) =>
  `${address.toLowerCase().slice(0, slice)}...${address
    .toLowerCase()
    .slice(address.length - slice, address.length)}`;

export const synthAssetName = (asset: string) =>
  asset.includes("/") ? asset.split(".")[1] : asset;

export const trailingComma = (num: number, decimals: number = 2) => {
  try {
    if (decimals < 0) {
      throw new Error("Decimals must be non-negative");
    }

    const formattedNumber = num.toFixed(decimals);
    const [integerPart, decimalPart] = formattedNumber.split(".");

    const integerWithCommas = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return decimalPart
      ? `${integerWithCommas}.${decimalPart}`
      : integerWithCommas;
  } catch (_) {
    return "";
  }
};

export const formatTime = (seconds: number) => {
  if (!seconds) return "Instantly";
  if (seconds < 60) return `${seconds}s`;

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  const formattedHours =
    hours > 0 ? `${hours.toString().padStart(2, "0")}h` : "";
  const formattedMinutes =
    minutes > 0 ? `${minutes.toString().padStart(2, "0")}m` : "";

  if (formattedHours && formattedMinutes) {
    return `${formattedHours} ${formattedMinutes}`;
  } else {
    return formattedHours + formattedMinutes;
  }
};

// format time to minutes
export const formatTimeToMinutes = (seconds: number) => {
  if (!seconds) return "Instantly";
  if (seconds < 60) return `${seconds}s`;

  const minutes = Math.floor(seconds / 60);

  const formattedMinutes =
    minutes > 0 ? `${minutes.toString().padStart(2, "0")}m` : "";

  return formattedMinutes;
};

export const truncateDecimals = (number: number) => {
  const stringNumber = number.toString();
  const [integerPart, fractionalPart] = stringNumber.split(".");
  const truncatedFractionalPart = fractionalPart
    ? fractionalPart.slice(0, 8)
    : "";
  return `${integerPart}.${truncatedFractionalPart}`;
};

export const formatTo = (amount: string | number, decimals = 8) =>
  BigNumber(amount).times(10 ** decimals).toFixed(0);

export const formatFrom = (amount: string | number = 0, decimals = 8) =>
  BigNumber(amount).dividedBy(10 ** decimals).toNumber();

export function formatNumber(number: number | string | undefined, decimals?: number): string {
  if (number === undefined) return "0.00";
  if (number == 0) return "0.00";

  if (typeof number === "string") number = parseFloat(number);
  if (decimals !== undefined) return number.toFixed(decimals);

  if (number >= 0 && number <= 0.00000001) return number.toFixed(12);
  if (number > 0.00000001 && number <= 0.0001) return number.toFixed(8);
  if (number > 0.0001 && number <= 0.01) return number.toFixed(4);
  if (number > 0.01 && number <= 1) return number.toFixed(6);
  if (number > 1 && number <= 100) return number.toFixed(4);
  return number.toFixed(2);
}
