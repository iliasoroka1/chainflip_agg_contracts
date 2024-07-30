import axios, { AxiosError, AxiosResponse } from 'axios';
let one: number = 100000000, tenThousand: number = 10000, daysInYear: number = 365 / 7, secondsInWeek: number = 7 * 24 * 60 * 60;
let uniqueSavers: number = 0, totalRuneValue: number = 0, rune_USD: number = 0, synthCap: number = 0;
let USD: string = `BNB.BUSD-BD1`;
let baseEndpoint: string = "https://thornode.ninerealms.com/";
let baseEndpoint2: string = "https://midgard.ninerealms.com/v2";
let PoolStub: string = "/pools/";
let StatStub: string = "/stats";
let blocksStub: string = "blocks/latest";
let balancesStub: string = "history/depths/";
let poolsStub: string = "thorchain/pools";
let poolStub: string = "thorchain/pool/";
let saversStub: string = "/savers";
let saversHistoryStub: string = "/history/savers/";
let mimirStub: string = "thorchain/mimir";
let synthCapMimir: string = "MAXSYNTHPERPOOLDEPTH";
const userAgentString: string = "MyCustomUserAgent/1.0";
let uniqueSaversLastwWeek: number = 0;
let totalRuneValueLastWeek: number = 0;
let rune_USDLastWeek: number = 0;
export interface Pool {
    asset: string;
    balance_asset: number;
    balance_rune: number;
    savers_depth: number;
    apy: number;
    ticker?: string;
    saverReturn?: number;
    saverCount?: number;
    saverCap?: number;
    filled?: number;
    earnings?: number;
    synth_supply?: number;
    savers_units?: number;
    pool_tvl?: number;
    total_savers_value?: number;
    total_savers_value_last_week?: number;
    saverCountLastWeek?: number; 
    saversDepthLastWeek?: number;
    saversRuneBalanceLastWeek?: number;
    saversBalanceAssetLastWeek?: number;
  }

const axiosConfig = {
  headers: {
    "User-Agent": userAgentString,
  },
};

const handleAxiosError = (error: AxiosError) => {
  if (error.response) {
    console.error("Error Response:", error.response.data);
    console.error("Status Code:", error.response.status);
  } else if (error.request) {
    console.error("No response received:", error.request);
  } else {
    console.error("Error setting up request:", error.message);
  }
};
// Get Synth Cap
const getMimir = async (): Promise<void> => {
  try {
    const response: AxiosResponse = await axios.get(
      `${baseEndpoint}${mimirStub}`
    );
    synthCap = (2 * response.data[synthCapMimir]) / tenThousand;
  } catch (error) {
    handleAxiosError(error as AxiosError<unknown, any>);
  }
};

// Get all pools
const getPools = async (): Promise<Array<Pool>> => {
    try {
      const response: AxiosResponse = await axios.get(`${baseEndpoint}${poolsStub}`);
      return response.data.filter((x: any) => x.status == "Available");
    } catch (error) {
      handleAxiosError(error as AxiosError<unknown, any>);
      return []; // Return an empty array in case of error
    }
};


// const printFooter = (): void => {
//     console.log(`\n\t\t${uniqueSavers} unique savers with $ ${Number(totalRuneValue * rune_USD).toLocaleString()} USD saved \n`)
//   }
  
  // Compute the APR based on 7-day lookback
const getPoolAPR = async (pool: Pool): Promise<number> => {
    try {
        // Fetching the pool data for the last 10 days
        const height10DaysAgo: string = `?interval=day&count=7`;
        const poolResponse = await axios.get(`${baseEndpoint2}${saversHistoryStub}${pool.asset}${height10DaysAgo}`, axiosConfig);
        const intervals = poolResponse.data.intervals;
        let totalGrowth = 0;
        let validIntervals = 0;
        let oldPool: any = poolResponse.data.meta;
        let oldSaverValue: number = oldPool.startSaversDepth / oldPool.startUnits;
        let newSaverValue: number = oldPool.endSaversDepth / oldPool.endUnits;
        let saver7DayGrowth: number = (newSaverValue - oldSaverValue) / oldSaverValue;
        let annual =  saver7DayGrowth * (52);
        // Loop through the intervals, starting from the second-to-last one
        for (let i = 0; i < intervals.length - 1 ; i++) {
          const newDepth = parseFloat(intervals[i + 1].saversDepth) / parseInt(intervals[i + 1].saversUnits);
          const oldDepth = parseFloat(intervals[i].saversDepth) / parseInt(intervals[i].saversUnits);
            // Check for valid oldDepth to avoid division by zero
            if (oldDepth > 0) {
                const intervalGrowth = (newDepth - oldDepth) / oldDepth;
                // Sum up the growth if it's a valid number
                if (!isNaN(intervalGrowth)) {
                    totalGrowth += intervalGrowth;
                    validIntervals++;
                }
            }
        }
        if (validIntervals === 0) {
            return 0; // Return 0 if no valid intervals were found
        }

        // Calculate the average growth
        const averageGrowth = totalGrowth / validIntervals;
        // Annualize the average growth
        return averageGrowth * 365 ; // Convert to annual rate

    } catch (error) {
        handleAxiosError(error as AxiosError<unknown, any>);
        return 0; // Return default APR in case of error
    
  } 
};
function sleep(ms: number | undefined) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
const scanPools = async (pools: Pool[]) => {
    let sortedPools = [];
    for (let pool of pools) {
    if (pool.asset == USD) { rune_USD = pool.balance_asset / pool.balance_rune }
    if (pool.asset == USD) { rune_USDLastWeek = await getRunePriceLastWeek(pool.asset)}
    if (pool.savers_depth == 0) { continue }
    pool.ticker = pool.asset.substr(0, pool.asset.search(/\./));
    await sleep(3000);
    pool.saverReturn = await getPoolAPR(pool) * 100;
    pool.apy = (Math.exp(pool.saverReturn/100) - 1) * 100;
    pool.saverCount = await getSaversCount(pool.asset);
    await sleep(3000);
    pool.saverCountLastWeek = await getSaversCountLastWeek(pool.asset);
    uniqueSavers += pool.saverCount;
    uniqueSaversLastwWeek += pool.saverCountLastWeek;
    pool.saversDepthLastWeek = await getSaversDepthLastWeek(pool.asset);
    await sleep(3000);
    pool.saversRuneBalanceLastWeek = await getSaversRuneBalanceLastWeek(pool.asset);
    await sleep(3000);
    pool.saversBalanceAssetLastWeek = await getSaversBalanceAssetLastWeek(pool.asset);
    totalRuneValue += ((pool.savers_depth * pool.balance_rune) / pool.balance_asset) / one;
    totalRuneValueLastWeek += ((pool.saversDepthLastWeek * pool.saversRuneBalanceLastWeek) / pool.saversBalanceAssetLastWeek) / one;
    if (pool.asset == USD) { pool.pool_tvl = pool.balance_asset / one }
    pool.total_savers_value = (((pool.savers_depth * pool.balance_rune) / pool.balance_asset) / one);
    pool.total_savers_value_last_week = (((pool.saversDepthLastWeek * pool.saversRuneBalanceLastWeek) / pool.saversBalanceAssetLastWeek) / one);
    pool.saverCap = synthCap * pool.balance_asset;
    pool.filled = ((pool.synth_supply ?? 0) / pool.saverCap) * 100;
    pool.earnings = (pool.savers_depth - (pool.savers_units ?? 0)) / one;
    pool.savers_depth = pool.savers_depth / one;
    sortedPools.push(pool);
    }
    sortedPools = sortedPools.sort((a, b) => ((a.saverCount ?? 0) > (b.saverCount ?? 0)) ? -1 : (((b.saverCount ?? 0) > (a.saverCount ?? 0)) ? 1 : 0));
    //writePools(sortedPools);
    return sortedPools;
  };

// Find the number of savers in a pool
const getSaversCount = async (pool: string): Promise<number> => {
        try {
                const response = await axios.get(`${baseEndpoint}${poolStub}${pool}${saversStub}`, axiosConfig);
                return response.data.length;
        } catch (error) {
            handleAxiosError(error as AxiosError<unknown, any>);
            return 0; // Return default savers count in case of error
        }
};

const getSaversCountLastWeek = async (pool: string): Promise<number> => {
        try { 
          // Get the current timestamp in seconds
          const now = Math.floor(Date.now() / 1000);
          const sevenDaysAgo = now - (7 * 86400);
          const height7DaysAgo = `?from=${sevenDaysAgo}&to=${now}`;
          const response = await axios.get(`${baseEndpoint2}${saversHistoryStub}${pool}${height7DaysAgo}`, axiosConfig);
          return parseFloat(response.data.meta.startSaversCount);
  } catch (error) {
      handleAxiosError(error as AxiosError<unknown, any>);
      return 0; // Return default savers count in case of error
  }
};

const getSaversDepthLastWeek = async (pool: string): Promise<number> => {
  try { 
    // Get the current timestamp in seconds
    const now = Math.floor(Date.now() / 1000);
    const sevenDaysAgo = now - (7 * 86400);
    const height7DaysAgo = `?from=${sevenDaysAgo}&to=${now}`;
    const response = await axios.get(`${baseEndpoint2}${saversHistoryStub}${pool}${height7DaysAgo}`, axiosConfig);
    return parseFloat(response.data.meta.startSaversDepth);
} catch (error) {
handleAxiosError(error as AxiosError<unknown, any>);
return 0; // Return default savers count in case of error
}
};

const getRunePriceLastWeek = async (pool: string): Promise<number> => {
  try { 
    // Get the current timestamp in seconds
    const now = Math.floor(Date.now() / 1000);
    const sevenDaysAgo = now - (7 * 86400);
    const height10DaysAgo: string = `?interval=day&count=7`;
    const response = await axios.get(`${baseEndpoint2}/${balancesStub}${pool}${height10DaysAgo}`, axiosConfig);
    const price = parseFloat(response.data.meta.startAssetDepth) / parseFloat(response.data.meta.startRuneDepth);
    return price;
} catch (error) {
handleAxiosError(error as AxiosError<unknown, any>);
return 0; // Return default savers count in case of error
}
};

const getSaversRuneBalanceLastWeek = async (pool: string): Promise<number> => {
  try { 
    // Get the current timestamp in seconds
    const now = Math.floor(Date.now() / 1000);
    const sevenDaysAgo = now - (7 * 86400);
    const height10DaysAgo: string = `?interval=day&count=7`;
    const response = await axios.get(`${baseEndpoint2}/${balancesStub}${pool}${height10DaysAgo}`, axiosConfig);
    return parseFloat(response.data.meta.startRuneDepth);
} catch (error) {
handleAxiosError(error as AxiosError<unknown, any>);
return 0; // Return default savers count in case of error
}
};

const getSaversBalanceAssetLastWeek = async (pool: string): Promise<number> => {
  try { 
    // Get the current timestamp in seconds
    const now = Math.floor(Date.now() / 1000);
    const sevenDaysAgo = now - (7 * 86400);
    const height10DaysAgo: string = `?interval=day&count=7`;
    const response = await axios.get(`${baseEndpoint2}/${balancesStub}${pool}${height10DaysAgo}`, axiosConfig);
    return parseFloat(response.data.meta.startAssetDepth);
} catch (error) {
handleAxiosError(error as AxiosError<unknown, any>);
return 0; // Return default savers count in case of error
}
};

// // Print Pools object
// const printPools = (sortedPools: Pool[]): void => {
//     for (let pool of sortedPools) {
//       console.log(
//         `\t\t${pool.ticker}: ${Number(
//           pool.savers_depth).toLocaleString()
//         }, ${pool.saverCount} savers, ${Number(pool.filled ?? 0).toLocaleString()}% filled, ${Number(pool.apy ?? 0).toLocaleString()}% APR, ${Number(pool.earnings ?? 0).toLocaleString()} earned`
//       )
//     }
// };



export const triggerProcess = async () => {
  await getMimir(); // Ensure this completes before proceeding
  // console.log("Mimir retrieved");
  const pools = await getPools(); // Wait for pools to be fetched
  // console.log("Pools retrieved");
  const processedPools = await scanPools(pools); // Process the pools
  const finishedPools = processedPools.map(pool => {
    return { ...pool, uniqueSavers: uniqueSavers, totalRuneValue: totalRuneValue * rune_USD, rune_USD: rune_USD, uniqueSaversLastwWeek: uniqueSaversLastwWeek, totalRuneValueLastWeek: totalRuneValueLastWeek , rune_USDLastWeek: rune_USDLastWeek  };
  });
  uniqueSavers = 0
  totalRuneValue = 0
  uniqueSaversLastwWeek = 0
  totalRuneValueLastWeek = 0;
  return finishedPools;
};
