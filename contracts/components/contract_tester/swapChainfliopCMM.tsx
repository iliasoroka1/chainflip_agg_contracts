import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  FormControl,
  FormLabel,
  Input,
  VStack,
  Heading,
  Text,
  useToast,
  Select,
  Flex,
  Textarea,
  Checkbox,
  Divider,
} from '@chakra-ui/react';
import abi from "@/constants/abi/aggregator.json" assert { type: "json" };
import { ethers } from 'ethers';
import { assembleQuote, fetchQuote } from '@/hooks/swap/quoteOdos';
import { ChainflipCCMParams, EncodedSwapStep, EncodingParams, EVMin, OdosAssemble, OdosInputs, ThorchainParams } from './interfaces';

const ChainflipCCMSwap: React.FC = () => {
  // URL for fetching quotes
  const quoteUrl = "https://api.odos.xyz/sor/quote/v2";
  const assembleUrl = 'https://api.odos.xyz/sor/assemble';

  const [encodingParams, setEncodingParams] = useState<EncodingParams>({
    swapType: 0,
    router: '',
    chain: '',
    tokenName: '',
    destinationAddress: '',
    outputToken: '',
    minOutputAmount: '',
    inputToken: '',
    inputAmount: '',
    finalToken: '', 
  });
  const tag = "Odos";

  // const tokens = useSelector(selectTokens);


const [odosParams, setOdosParams] = useState({});
const [evmInputs, setEvmInputs] = useState<EVMin>();
const [odosInputs, setOdosInputs] = useState<OdosInputs>();
const [thorParams, setThorParams] = useState<ThorchainParams>({
  router: '',
  vault: '',
  asset: '',
  memo: '',
});
const [chainflipParams, setChainflipParams] = useState<ChainflipCCMParams>({
  dstChain: 0,
  dstAddress: '',
  dstToken: 0,
  srcToken: '',
  amount: '',
  message: '',
  gasBudget: '',
  cfParameters: ''
});
const [squidParams, setSquidParams] = useState({
  fromChain: '',
  toChain: '',
  fromToken: '',
  toToken: '',
  fromAmount: '',
  slippage: 1,
});

const [thorchainPercentage, setThorchainPercentage] = useState('0');
const [amountTripple, setAmountTripple] = useState('');
const [mayaPercentage, setMayaPercentage] = useState('0');
const [mayaParams, setMayaParams] = useState<ThorchainParams>({
  router: '',
  vault: '',
  asset: '',
  memo: '',
});

const [minOutputAmount, setMinOutputAmount] = useState('');
const [memo, setMemo] = useState<string>('');
const [encodedMessage, setEncodedMessage] = useState<string>('');
const [selectedScenario, setSelectedScenario] = useState<string>("");
const [contractAddress, setContractAddress] = useState<string>('');
const [contract, setContract] = useState<ethers.Contract | null>(null);
const [isEthSwap, setIsEthSwap] = useState<boolean>(true);
const [selectedFunction, setSelectedFunction] = useState('');
const [swapSteps, setSwapSteps] = useState<EncodedSwapStep[]>([]);
const [swpStepOut, setSwapStepOut] = useState<EncodedSwapStep[]>([]);
const [loading, setLoading] = useState(false);
const [signer, setsigner] = useState<any>();
const [recipient, setRecipient] = useState<string>('');


  const predefinedScenarios = [
    {
      name: "ETH to USDC on Chainflip, USDC to ETH on Sushi",
      chainflipParams: {
        dstChain: 4,
        dstAddress: "0x",
        dstToken: 7,
        srcToken: "0x0000000000000000000000000000000000000000",
        amount: "1700000000000000",
        mesage: "0x",
        gasBudget: "400000000000000",
        cfParameters: "0x"
      },
      encodingParams: {
        swapType: 1,
        router: "0x3672d3c7FF90Dcb3e26C379A58FB923C377D1b8e",
        outputToken: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        minOutputAmount: "0"
      }
    },
    // {
    //   name: "USDC to ETH on Chainflip, ETH to DAI on Sushi",
    //   chainflipParams: {
    //     dstChain: 4,
    //     dstAddress: "0x06c0e2bfa9d22b0b02ac2014deec6eff2cdcf571",
    //     dstToken: 0,
    //     srcToken: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    //     amount: "1000000000",
    //     mesage: "0x",
    //     gasBudget: "400000000000000",
    //     cfParameters: "0x"
    //   },
    //   encodingParams: {
    //     swapType: 1,
    //     router: "0x3672d3c7FF90Dcb3e26C379A58FB923C377D1b8e",
    //     outputToken: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    //     minOutputAmount: "0"
    //   }
    // },
    // {
    //   name: "ETH to BTC on THORChain",
    //   chainflipParams: {
    //     dstChain: 4,
    //     dstAddress: "0x06c0e2bfa9d22b0b02ac2014deec6eff2cdcf571",
    //     dstToken: 7,
    //     srcToken: "0x0000000000000000000000000000000000000000",
    //     amount: "1000000000000000000",
    //     mesage: "0x",
    //     gasBudget: "400000000000000",
    //     cfParameters: "0x"
    //   },
    //   encodingParams: {
    //     swapType: 0,
    //     router: "0x3672d3c7FF90Dcb3e26C379A58FB923C377D1b8e",
    //     chain: "BTC",
    //     tokenName: "BTC",
    //     destinationAddress: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
    //   }
    // },
    // {
    //   name: "Deposit FLIP to Chainflip Vault",
    //   chainflipParams: {
    //     dstChain: 4,
    //     dstAddress: "0x06c0e2bfa9d22b0b02ac2014deec6eff2cdcf571",
    //     dstToken: 7,
    //     srcToken: "0xYourFLIPTokenAddress", // Replace with actual FLIP token address
    //     amount: "1000000000000000000", // 1 FLIP
    //     mesage: "0x",
    //     gasBudget: "400000000000000",
    //     cfParameters: "0x"
    //   },
    //   encodingParams: {
    //     swapType: 2,
    //     router: "0xYourChainflipLPAddress", // Replace with actual Chainflip LP contract address
    //     nodeID: "0x1234567890123456789012345678901234567890123456789012345678901234" // Example nodeID
    //   }
    // }
  ];
  
    const handleFetchAndAssemble = async () => {
      try {
        const quoteData = await fetchQuote(odosParams, quoteUrl, tag);
        if (quoteData) {
          const transactionData = await assembleQuote(recipient, quoteData.pathId, assembleUrl, false, contractAddress);
          if (transactionData) {
            console.log('Transaction Data:', transactionData);
            setOdosInputs({SwapData: transactionData.data, odosRouter: transactionData.to});
            toast({
              title: 'Quote Assembled',
              description: 'Transaction data ready for execution.',
              status: 'success',
              duration: 5000,
              isClosable: true,
            });
          } else {
            toast({
              title: 'Assembly Failed',
              description: 'Failed to assemble transaction data.',
              status: 'error',
              duration: 5000,
              isClosable: true,
            });
          }
        } else {
          toast({
            title: 'Quote Fetch Failed',
            description: 'Could not fetch the quote.',
            status: 'error',
            duration: 5000,
            isClosable: true,
          });
        }
      } catch (error) {
        console.error('Error during fetch and assemble:', error);
        toast({
          title: 'Error',
          description: error instanceof Error ? error.message : 'An error occurred during fetch and assemble.',
          status: 'error',
          duration: 5000,
          isClosable: true,
        });
      }
    };

  useEffect(() => {
    if (selectedFunction === 'odosSwapThenChainflip') {
      setOdosParams({
        chainId: 42161, 
        compact: true,
        gasPrice: 20,
        inputTokens: [
          {
            amount: odosInputs?.inputAmount,
            tokenAddress: odosInputs?.inputToken
          }
        ],
        outputTokens: [
          {
            proportion: 1, 
            tokenAddress: odosInputs?.outputToken
          }
        ],
        referralCode: 0,
        slippageLimitPercent: 0.3,
        sourceBlacklist: [],
        sourceWhitelist: [],
        userAddr: contractAddress
      });
    }
  }, [odosInputs, selectedFunction, contractAddress]);

  console.log("ODOS PARAMS", odosParams);

  fetchQuote(odosParams, quoteUrl, tag).then((quote) => {
    if (quote) {
      console.log("Quote received:", quote);
    } else {
      console.log("Failed to receive a quote");
    }
  });
  const toast = useToast();

 
  

  useEffect(() => {
    if (encodingParams.swapType === 0) {
      setMemo(`:=${encodingParams.chain}.${encodingParams.tokenName}:${encodingParams.destinationAddress}`);
    } else if (encodingParams.swapType === 1) {
      setMemo(`${encodingParams.outputToken},${encodingParams.minOutputAmount}, ${encodingParams.swapSteps?.map(step => `${step.dex},${step.percentage},${step.tokenOut}`).join(',')}`);
    } else if (encodingParams.swapType === 2) {
      setMemo(`${encodingParams.nodeID}`);
    }
  }, [encodingParams]);
  const handleScenarioChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const scenario = predefinedScenarios.find(s => s.name === e.target.value);
    if (scenario) {
      setSelectedScenario(scenario.name);
      setEncodingParams(scenario.encodingParams);
      setChainflipParams(scenario.chainflipParams);
    }
  };
  useEffect(() => {
    if (typeof window.ethereum !== 'undefined' && contractAddress) {
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
        const signer = provider.getSigner();
        setsigner(signer)
        const newContract = new ethers.Contract(contractAddress, abi, signer);
        setContract(newContract);
      } catch (error) {
        console.error("Error creating contract instance:", error);
        toast({
          title: "Contract Creation Error",
          description: "Failed to create contract instance. Please check the contract address.",
          status: "error",
          duration: 5000,
          isClosable: true,
        });
      }
    }
  }, [contractAddress]);

  const handleEncodingInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setEncodingParams(prev => ({ ...prev, [name]: name === 'swapType' ? Number(value) : value }));
  };

  const handleChainflipInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setChainflipParams(prev => ({ ...prev, [name]: value }));
  };

  useEffect(() => {
    setChainflipParams(prev => ({ ...prev, message: encodedMessage }));
  }, [encodedMessage]);


  const handleSwapStepChange = (index: number, field: string, value: string) => {
    const newSteps = [...swapSteps];
    newSteps[index] = { ...newSteps[index], [field]: value };
    setSwapSteps(newSteps);
  };

  const handleSwapStepChangeOut = (index: number, field: string, value: string) => {
    const newStepOut = [...swpStepOut];
    if (field === 'dex') {
      newStepOut[index] = { ...newStepOut[index], [field]: parseInt(value) };
    } else if (field === 'percentage') {
      newStepOut[index] = { ...newStepOut[index], [field]: parseFloat(value) };
    } else if (field === 'tokenOut') {
      newStepOut[index] = { ...newStepOut[index], [field]: value };
    }
    setSwapStepOut(newStepOut);
  
    setEncodingParams(prevParams => ({
      ...prevParams,
      swapSteps: newStepOut
    }));
  };

  const addSwapStep = () => {
    setSwapSteps([...swapSteps, { dex: 0, percentage: 0, tokenOut: '' }]);
  };

  const addWapStepOut = () => {
    const newStep = { dex: 0, percentage: 0, tokenOut: '' };
    setSwapStepOut(prevSteps => [...prevSteps, newStep]);
    setEncodingParams(prevParams => ({
      ...prevParams,
      swapSteps: [...(prevParams.swapSteps || []), newStep]
    }));
  };
  
  const removeSwapStepOut = (index: number) => {
    setSwapStepOut(prevSteps => prevSteps.filter((_, i) => i !== index));
    setEncodingParams(prevParams => ({
      ...prevParams,
      swapSteps: prevParams.swapSteps?.filter((_, i) => i !== index)
    }));
  };

  const removeSwapStep = (index: number) => {
    setSwapSteps(swapSteps.filter((_, i) => i !== index));
  };


  const handleSubmit = async () => {
    if (!contract) {
      toast({ title: 'Contract not connected', status: 'error', duration: 3000, isClosable: true });
      return;
    }
  
    try {
      let tx;
      switch (selectedFunction) {
        case 'swapViaChainflipCCM':
          if (!isEthSwap){
            const usdtContract = new ethers.Contract(
              (chainflipParams.srcToken ?? ""),
                          ['function approve(address spender, uint256 amount) public returns (bool)'],
                          signer
                        );
                        const approveTx = await usdtContract.approve(contract.address, chainflipParams.amount);
                        await approveTx.wait();
                      }
          tx = await contract.swapViaChainflipCCM(
            chainflipParams,
            { value: isEthSwap ? chainflipParams.amount : 0 }
          );
          break;
        case 'EVMThenChainflipCCM':
          if (!isEthSwap){
          const usdtContract = new ethers.Contract(
            (evmInputs?.inputToken ?? ""),
                        ['function approve(address spender, uint256 amount) public returns (bool)'],
                        signer
                      );
                      const approveTx = await usdtContract.approve(contract, evmInputs?.inputAmount);
                      await approveTx.wait();
                    }
          tx = await contract.EVMThenChainflipCCM(
            evmInputs?.inputToken,
            evmInputs?.inputAmount, // Adjust decimals as needed
            swapSteps?.map(step => ({
              dex: step?.dex,
              percentage: step?.percentage.toString(), // Assuming percentage is in whole numbers (e.g., 50 for 50%)
              tokenOut: step?.tokenOut
            })),
            {
              dstChain: chainflipParams.dstChain,
              dstAddress: chainflipParams.dstAddress,
              dstToken: chainflipParams.dstToken,
              srcToken: chainflipParams.srcToken,
              amount: chainflipParams.amount, // Adjust decimals as needed
              message: chainflipParams.message || '0x',
              gasBudget: chainflipParams.gasBudget, // Assuming gasBudget is in Gwei
              cfParameters: chainflipParams.cfParameters
            },
            { 
              value: isEthSwap ? evmInputs?.inputAmount : 0 
            }
          );
          break;
        case 'odosSwapThenChainflipCMM':
          if (!isEthSwap){
            const usdtContract = new ethers.Contract(
              (evmInputs?.inputToken ?? ""),
              ['function approve(address spender, uint256 amount) public returns (bool)'],
              signer );
              const approveTx = await usdtContract.approve(contract, evmInputs?.inputAmount);
              await approveTx.wait();
              }
          tx = await contract.odosSwapThenChainflipCMM(
            odosInputs?.odosRouter,
            odosInputs?.SwapData,
            odosInputs?.inputToken,
            odosInputs?.outputToken,
            odosInputs?.inputAmount,
            odosInputs?.minOutputAmount,
            chainflipParams,
            { value: isEthSwap ? odosInputs?.inputAmount : 0 }
          );
          break;
          case 'EVMThenChainflip':
            if (!isEthSwap){
          const usdtContract = new ethers.Contract(
            (evmInputs?.inputToken ?? ""),
            ['function approve(address spender, uint256 amount) public returns (bool)'],
            signer );
            const approveTx = await usdtContract.approve(contract, evmInputs?.inputAmount);
            await approveTx.wait();}
          tx = await contract.EVMThenChainflip(
            evmInputs?.inputToken,
            evmInputs?.inputAmount, 
            swapSteps?.map(step => ({
              dex: step?.dex,
              percentage: step?.percentage.toString(), // Assuming percentage is in whole numbers (e.g., 50 for 50%)
              tokenOut: step?.tokenOut
            })),
            {
              dstChain: chainflipParams.dstChain,
              dstAddress: chainflipParams.dstAddress,
              dstToken: chainflipParams.dstToken,
              srcToken: chainflipParams.srcToken,
              amount: chainflipParams.amount, 
              cfParameters: chainflipParams.cfParameters
            },
            { 
              value: isEthSwap ? evmInputs?.inputAmount : 0 
            }
          );
          break;
          case 'odosSwapThenChainflipCMM':
            if (!isEthSwap){
              const usdtContract = new ethers.Contract(
                (odosInputs?.inputToken ?? ""),
                ['function approve(address spender, uint256 amount) public returns (bool)'],
                signer
                  );
                          const approveTx = await usdtContract.approve(contract.address, odosInputs?.inputAmount);
                          await approveTx.wait();
                }
          tx = await contract.odosSwapThenChainflip(
            odosInputs?.odosRouter,
            odosInputs?.SwapData,
            odosInputs?.inputToken,
            odosInputs?.outputToken,
            odosInputs?.inputAmount,
            odosInputs?.minOutputAmount,
            {
              dstChain: chainflipParams.dstChain,
              dstAddress: chainflipParams.dstAddress,
              dstToken: chainflipParams.dstToken,
              srcToken: chainflipParams.srcToken,
              amount: chainflipParams.amount, 
              cfParameters: chainflipParams.cfParameters
            },
            { value: isEthSwap ? odosInputs?.inputAmount : 0 }
          );
          break;
          case 'EVMthenThor':
            if (!isEthSwap){
              const usdtContract = new ethers.Contract(
                (evmInputs?.inputToken ?? ""),
                            ['function approve(address spender, uint256 amount) public returns (bool)'],
                            signer
                          );
                          const approveTx = await usdtContract.approve(contract.address, evmInputs?.inputAmount);
                          await approveTx.wait();
                        }
              tx = await contract.EVMThenThor(
                evmInputs?.inputToken,
                evmInputs?.inputAmount,
                swapSteps?.map(step => ({
                  dex: step?.dex,
                  percentage: step?.percentage.toString(),
                  tokenOut: step?.tokenOut
                })),
                {
                  vault: thorParams.vault,
                  router: thorParams.router,
                  token: thorParams?.asset,
                  memo: thorParams.memo,
                },
                { value: isEthSwap ? evmInputs?.inputAmount : 0 }
              );
              break;
              case 'trippleSwap':
                tx = await contract.EVMThenThorMayaChainflip(
                  evmInputs?.inputToken,
                  evmInputs?.inputAmount,
                  swapSteps?.map(step => ({
                    dex: step?.dex,
                    percentage: step?.percentage.toString(),
                    tokenOut: step?.tokenOut
                  })),
                  parseInt(thorchainPercentage),
                  parseInt(mayaPercentage),
                  {
                    vault: thorParams.vault,
                    router: thorParams.router,
                    token: thorParams?.asset,
                    memo: thorParams.memo,
                  },
                  {
                    vault: mayaParams.vault,
                    router: mayaParams.router,
                    token: mayaParams.asset,
                    memo: mayaParams.memo,
                  },
                  {
                    dstChain: chainflipParams.dstChain,
                    dstAddress: chainflipParams.dstAddress,
                    dstToken: chainflipParams.dstToken,
                    srcToken: chainflipParams.srcToken,
                    amount: chainflipParams.amount, 
                    cfParameters: chainflipParams.cfParameters
                  },
                  { value: isEthSwap ? evmInputs?.inputAmount : 0 }
                );
                break;
                    default:
                      throw new Error('Unsupported function');
                  }
                  const receipt = await tx.wait();
                  toast({
                    title: 'Transaction Successful',
                    description: `${selectedFunction} executed successfully`,
                    status: 'success',
                    duration: 5000,
                    isClosable: true,
                  });
                } catch (error: any) {
                  console.error("Transaction error:", error);
                  toast({ title: 'Transaction Failed', description: error.message, status: 'error', duration: 5000, isClosable: true });
                }
              };
    
  const encodeMessage = () => {
    try {
      let encoded;
      if (selectedFunction === 'swapViaChainflipCCM') {
        let memoBytes;
        if (encodingParams.swapType === 0) {
          // THORChain encoding
          memoBytes = ethers.utils.toUtf8Bytes(`:=${encodingParams.chain}.${encodingParams.tokenName}:${encodingParams.destinationAddress}`);
        } else if (encodingParams.swapType === 1) {
          // EVM DEX encoding
          memoBytes = ethers.utils.defaultAbiCoder.encode(
            ['address', 'uint256', 'tuple(uint8 dex, uint256 percentage, address tokenOut)[]'],
            [
              encodingParams.outputToken,
              ethers.utils.parseUnits(encodingParams.minOutputAmount || "0", 18),
              encodingParams.swapSteps?.map(step => [step.dex, step.percentage, step.tokenOut])
            ]
          );
        } else if (encodingParams.swapType === 2) {
          // Chainflip Vault deposit encoding
          memoBytes = ethers.utils.defaultAbiCoder.encode(['bytes32'], [encodingParams.nodeID]);
        } else {
          throw new Error('Invalid swap type');
        }
  
        encoded = ethers.utils.defaultAbiCoder.encode(
          ['uint8', 'address', 'bytes'],
          [encodingParams.swapType, encodingParams.router, memoBytes]
        );
      } else if (selectedFunction === 'EVMThenChainflipCCM' || selectedFunction === 'squidSwapThenChainflip') {
        let memoBytes;
        if (encodingParams.swapType === 0) {
          // THORChain encoding
          memoBytes = ethers.utils.toUtf8Bytes(`:=${encodingParams.chain}.${encodingParams.tokenName}:${encodingParams.destinationAddress}`);
        } else if (encodingParams.swapType === 1) {
          // EVM DEX encoding
          memoBytes = ethers.utils.defaultAbiCoder.encode(
            ['address', 'uint256', 'tuple(uint8 dex, uint256 percentage, address tokenOut)[]'],
            [
              encodingParams.outputToken,
              ethers.utils.parseUnits(encodingParams.minOutputAmount || "0", 18),
              encodingParams.swapSteps?.map(step => [step.dex, step.percentage, step.tokenOut])
            ]
          );
        } else if (encodingParams.swapType === 2) {
          // Chainflip Vault deposit encoding
          memoBytes = ethers.utils.defaultAbiCoder.encode(['bytes32'], [encodingParams.nodeID]);
        } else {
          throw new Error('Invalid swap type');
        }
  
        encoded = ethers.utils.defaultAbiCoder.encode(
          ['uint8', 'address', 'bytes'],
          [encodingParams.swapType, encodingParams.router, memoBytes]
        );
      }
      
      if (ethers.utils.hexDataLength(encoded ?? "0x") >= 10000) {
        throw new Error('Encoded message is too long (>= 10k bytes)');
      }
      
      setEncodedMessage(encoded ?? "0x");
    } catch (error) {
      console.error('Error encoding message:', error);
      toast({
        title: 'Encoding Error',
        description: error instanceof Error ? error.message : 'Failed to encode message. Check your inputs.',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };


  return (
    <Flex maxWidth="1200px" margin="auto" mt={8} p={6}>
      <Box flex={1} mr={8} p={6} borderWidth={1} borderRadius="lg" boxShadow="xl">
        <Heading as="h2" size="md" mb={4}>Contract Settings</Heading>
        <FormControl mb={4}>
          <FormLabel>Contract Address</FormLabel>
          <Input value={contractAddress} onChange={(e) => setContractAddress(e.target.value)} placeholder="Enter contract address" />
        </FormControl>
        
        <FormControl mb={4}>
          <FormLabel>Select Function</FormLabel>
          <Select value={selectedFunction} onChange={(e) => setSelectedFunction(e.target.value)}>
            <option value="">Select a function</option>
            <option value="swapViaChainflipCCM">SwapViaChainflipCCM</option>
            <option value="EVMThenChainflipCCM">EVMThenChainflipCCM</option>
            <option value="odosSwapThenChainflipCMM">odosSwapThenChainflipCMM</option>
            <option value="EVMThenChainflip">EVMThenChainflip</option>
            <option value="EVMthenThor">EVMthenThor</option>
            <option value="EVMThenThorMayaChainflip">EVMThenThorMayaChainflip</option>
          </Select>
        </FormControl>
        <Heading as="h2" size="md" mb={4}>Predefined Scenarios</Heading>
        <FormControl mb={4}>
          <FormLabel>Select Scenario</FormLabel>
          <Select value={selectedScenario} onChange={handleScenarioChange}>
            <option value="">Select a scenario</option>
            {predefinedScenarios.map(scenario => (
              <option key={scenario.name} value={scenario.name}>{scenario.name}</option>
            ))}
          </Select>
        </FormControl>
        <Divider></Divider>
        {(selectedFunction === 'swapViaChainflipCCM' || selectedFunction === 'odosSwapThenChainflip' || selectedFunction === 'EVMThenChainflipCCM' || selectedFunction === 'squidSwapThenChainflip' || selectedFunction === 'EVMThenChainflip')&& (
          <>
            <Heading as="h2" size="md" mb={4}>Message Encoding</Heading>
            <VStack spacing={4} align="stretch">
              <FormControl>
                <FormLabel>Swap Type</FormLabel>
                <Select name="swapType" value={encodingParams.swapType} onChange={handleEncodingInputChange}>
                  <option value={0}>THORChain/Maya</option>
                  <option value={1}>Sushiswap</option>
                  <option value={2}>Chainflip Vault Deposit</option>
                </Select>
              </FormControl>
              <FormControl>
                <FormLabel>Router</FormLabel>
                <Input name="router" value={encodingParams.router} onChange={handleEncodingInputChange} />
              </FormControl>
              {encodingParams.swapType === 0 ? (
                <>
                  <FormControl>
                    <FormLabel>Chain</FormLabel>
                    <Input name="chain" value={encodingParams.chain} onChange={handleEncodingInputChange} />
                  </FormControl>
                  <FormControl>
                    <FormLabel>Token Name</FormLabel>
                    <Input name="tokenName" value={encodingParams.tokenName} onChange={handleEncodingInputChange} />
                  </FormControl>
                  <FormControl>
                    <FormLabel>Destination Address</FormLabel>
                    <Input name="destinationAddress" value={encodingParams.destinationAddress} onChange={handleEncodingInputChange} />
                  </FormControl>
                </>
              ) : encodingParams.swapType === 1 ? (
                <>
                  <FormControl>
                    <FormLabel>Output Token</FormLabel>
                    <Input name="outputToken" value={encodingParams.outputToken} onChange={handleEncodingInputChange} />
                  </FormControl>
                  <FormControl>
                    <FormLabel>Min Output Amount</FormLabel>
                    <Input name="minOutputAmount" value={encodingParams.minOutputAmount} onChange={handleEncodingInputChange} />
                  </FormControl>
                  <Heading as="h3" size="sm" mb={2}>Swap Steps</Heading>
                  {encodingParams.swapSteps?.map((step, index) => (
                    <Box key={index} borderWidth={1} borderRadius="md" p={2} mb={2} bgColor={"#1D1D20"} borderColor={"#8158B9"}>
                      <FormControl>
                        <FormLabel>DEX</FormLabel>
                        <Select value={step.dex} onChange={(e) => handleSwapStepChangeOut(index, 'dex', e.target.value)}>
                          <option value={0}>Uniswap</option>
                          <option value={1}>Sushiswap</option>
                        </Select>
                      </FormControl>
                      <FormControl mt={2}>
                        <FormLabel>Percentage</FormLabel>
                        <Input type="number" value={step.percentage} onChange={(e) => handleSwapStepChangeOut(index, 'percentage', e.target.value)} />
                      </FormControl>
                      <FormControl mt={2}>
                        <FormLabel>Token OUT</FormLabel>
                      <Input type="string" value={step.tokenOut} onChange={(e) => handleSwapStepChangeOut(index, 'tokenOut', e.target.value)} />
                      </FormControl>
                      <Button mt={2} size="sm" colorScheme="red" onClick={() => removeSwapStepOut(index)}>Remove Step</Button>
                    </Box>
                  ))}
                  <Button colorScheme="green" onClick={addWapStepOut}>Add Swap Step</Button>
                </>
              ) : (
                <FormControl>
                  <FormLabel>Node ID</FormLabel>
                  <Input name="nodeID" value={encodingParams.nodeID} onChange={handleEncodingInputChange} />
                </FormControl>
              )}
              <Text fontWeight="bold">Generated Memo:</Text>
              <Textarea value={memo} isReadOnly />
            </VStack>
          </>
        )}
        <Button mt={4} colorScheme="blue" onClick={encodeMessage}>
          Encode Message
        </Button>
        {encodedMessage && (
          <>
            <Text fontWeight="bold" mt={4}>Encoded Message:</Text>
            <Textarea value={encodedMessage} isReadOnly mt={2} />
          </>
        )}
      </Box>
      <Box flex={1} p={6} borderWidth={1} borderRadius="lg" boxShadow="xl">
      {(selectedFunction === 'EVMThenChainflipCCM' || selectedFunction === 'EVMThenChainflip' || selectedFunction === 'EVMthenThor') &&  (
          <>
      <Heading as="h2" size="md" mb={4}>EVM Params (swap in)</Heading>
      <VStack spacing={4} align="stretch">
        <FormControl>
          <FormLabel>Input Token</FormLabel>
          <Input value={evmInputs?.inputToken} onChange={(e) => setEvmInputs({ ...evmInputs, inputToken: e.target.value })} />
        </FormControl>
        <FormControl>
          <FormLabel>Input Amount</FormLabel>
          <Input value={evmInputs?.inputAmount} onChange={(e) => setEvmInputs({ ...evmInputs, inputAmount: e.target.value })} />
        </FormControl>
        <FormControl>
          <FormLabel>Final Token</FormLabel>
          <Input value={evmInputs?.finalToken} onChange={(e) => setEvmInputs({ ...evmInputs, finalToken: e.target.value })} />
        </FormControl>
        </VStack>
            <Heading as="h2" size="md" mb={4}>EVM Swap Steps</Heading>
            <VStack spacing={4} align="stretch">
              {swapSteps.map((step, index) => (
                <Box key={index} p={4} borderWidth={1} borderRadius="md">
                  <Heading as="h3" size="sm" mb={2}>Step {index + 1}</Heading>
                  <FormControl>
                    <FormLabel>DEX</FormLabel>
                    <Select value={step.dex} onChange={(e) => handleSwapStepChange(index, 'dex', e.target.value)}>
                      <option value={0}>Uniswap</option>
                      <option value={1}>Sushiswap</option>
                    </Select>
                  </FormControl>
                  <FormControl mt={2}>
                    <FormLabel>Percentage</FormLabel>
                    <Input value={step.percentage} onChange={(e) => handleSwapStepChange(index, 'percentage', e.target.value)} />
                  </FormControl>
                  <FormControl mt={2}>
                    <FormLabel>Token Out</FormLabel>
                    <Input value={step.tokenOut} onChange={(e) => handleSwapStepChange(index, 'tokenOut', e.target.value)} />
                  </FormControl>
                  {index > 0 && (
                    <Button mt={2} colorScheme="red" onClick={() => removeSwapStep(index)}>Remove Step</Button>
                  )}
                </Box>
              ))}
              <Button colorScheme="blue" onClick={addSwapStep}>Add Swap Step</Button>
            </VStack>
          </>
        )}
          {
            (selectedFunction === 'odosSwapThenChainflip' || selectedFunction === 'odosSwapThenChainflipMayaThor')&& (
            <>
            <Heading as="h2" size="md" mb={4}>Recipient for OdosQuote</Heading>
            <FormControl>
              <FormLabel>Recipient</FormLabel>
              <Input value={recipient} onChange={(e) => setRecipient(e.target.value)} />
            </FormControl>
            <Heading as="h2" size="md" mb={4}>Odos Params</Heading>
            <FormControl>
              <FormLabel>Input Token</FormLabel>
              <Input value={odosInputs?.inputToken} onChange={(e) => setOdosInputs({ ...odosInputs, inputToken: e.target.value })} />
            </FormControl>
            <FormControl>
              <FormLabel>Output Token</FormLabel>
              <Input value={odosInputs?.outputToken} onChange={(e) => setOdosInputs({ ...odosInputs, outputToken: e.target.value })} />
            </FormControl>
            <FormControl>
              <FormLabel>Amount</FormLabel>
              <Input value={odosInputs?.inputAmount} onChange={(e) => setOdosInputs({ ...odosInputs, inputAmount: e.target.value })} />
            </FormControl>
            <FormControl>
              <FormLabel>Min Output</FormLabel>
              <Input value={odosInputs?.minOutputAmount} onChange={(e) => setOdosInputs({ ...odosInputs, minOutputAmount: e.target.value })} />
            </FormControl>
              <Button
          onClick={handleFetchAndAssemble}
          isLoading={loading}
          loadingText="Fetching..."
          colorScheme="blue"
        >
          Fetch Quote
          </Button>
          <FormControl>
              <FormLabel>Odos Router</FormLabel>
              <Input value={odosInputs?.odosRouter} onChange={(e) => setOdosInputs({ ...odosInputs, odosRouter: e.target.value })} />
            </FormControl>
            <FormControl>
              <FormLabel>Swap Data</FormLabel>
              <Input value={odosInputs?.SwapData} onChange={(e) => setOdosInputs({ ...odosInputs, SwapData: e.target.value })} />   
            </FormControl>
            </>
          )}
          {(selectedFunction === 'EVMthenThor' || selectedFunction === 'trippleSwap' || selectedFunction === 'odosSwapThenChainflipMayaThor') && ( 
              <>
      <Heading as="h2" size="md" mb={4} mt={6}>THORChain Parameters</Heading>
      <VStack spacing={4} align="stretch">
        <FormControl>
          <FormLabel>THORChain Router</FormLabel>
          <Input 
            value={thorParams?.router} 
            onChange={(e) => setThorParams((prev: any) => ({ ...prev, router: e.target.value }))} 
          />
        </FormControl>
        <FormControl>
          <FormLabel>THORChain Vault</FormLabel>
          <Input 
            value={thorParams?.vault} 
            onChange={(e) => setThorParams((prev: any) => ({ ...prev, vault: e.target.value }))} 
          />
        </FormControl>
        <FormControl>
          <FormLabel>THORChain Asset</FormLabel>
          <Input 
            value={thorParams?.asset} 
            onChange={(e) => setThorParams((prev: any) => ({ ...prev, asset: e.target.value }))} 
          />
        </FormControl>
        <FormControl>
          <FormLabel>THORChain Memo</FormLabel>
          <Input 
            value={thorParams?.memo} 
            onChange={(e) => setThorParams((prev: any) => ({ ...prev, memo: e.target.value }))} 
          />
        </FormControl>
      </VStack>
              </>
          )}
          {(selectedFunction === 'trippleSwap' || selectedFunction === 'odosSwapThenChainflipMayaThor') && (
            <>
                <FormControl mt={2}>
        <FormLabel>Amount</FormLabel>
        <Input type="number" value={amountTripple} onChange={(e) => setAmountTripple(e.target.value)} />
      </FormControl>
      </>
          )
          }
          {(selectedFunction === 'trippleSwap' || selectedFunction === 'odosSwapThenChainflipMayaThor') && (
            <>
                <FormControl mt={4}>
        <FormLabel>THORChain Percentage</FormLabel>
        <Input type="number" value={thorchainPercentage} onChange={(e) => setThorchainPercentage(e.target.value)} />
      </FormControl>
      <FormControl mt={2}>
        <FormLabel>Maya Percentage</FormLabel>
        <Input type="number" value={mayaPercentage} onChange={(e) => setMayaPercentage(e.target.value)} />
      </FormControl>
      <Heading as="h2" size="md" mb={4} mt={6}>Maya Parameters</Heading>
      <VStack spacing={4} align="stretch">
        <FormControl>
          <FormLabel>
            Maya Router</FormLabel>
          <Input 
            value={thorParams?.router} 
            onChange={(e) => setMayaParams((prev: any) => ({ ...prev, router: e.target.value }))} 
          />
        </FormControl>
        <FormControl>
          <FormLabel>Maya Vault</FormLabel>
          <Input 
            value={thorParams?.vault} 
            onChange={(e) => setMayaParams((prev: any) => ({ ...prev, vault: e.target.value }))} 
          />
        </FormControl>
        <FormControl>
          <FormLabel>Maya Asset</FormLabel>
          <Input 
            value={thorParams?.asset} 
            onChange={(e) => setMayaParams((prev: any) => ({ ...prev, asset: e.target.value }))} 
          />
        </FormControl>
        <FormControl>
          <FormLabel>Maya Memo</FormLabel>
          <Input 
            value={thorParams?.memo} 
            onChange={(e) => setMayaParams((prev: any) => ({ ...prev, memo: e.target.value }))} 
          />
        </FormControl>
      </VStack>
            </>
          )}
          {selectedFunction === 'squidSwapThenChainflip' && (
        <>
          <Heading as="h2" size="md" mb={4}>Squid Swap Parameters</Heading>
          <FormControl>
            <FormLabel>From Chain</FormLabel>
            <Input value={squidParams.fromChain} onChange={(e) => setSquidParams({...squidParams, fromChain: e.target.value})} />
          </FormControl>
          <FormControl>
            <FormLabel>To Chain</FormLabel>
            <Input value={squidParams.toChain} onChange={(e) => setSquidParams({...squidParams, toChain: e.target.value})} />
          </FormControl>
          <FormControl>
            <FormLabel>From Token</FormLabel>
            <Input value={squidParams.fromToken} onChange={(e) => setSquidParams({...squidParams, fromToken: e.target.value})} />
          </FormControl>
          <FormControl>
            <FormLabel>To Token</FormLabel>
            <Input value={squidParams.toToken} onChange={(e) => setSquidParams({...squidParams, toToken: e.target.value})} />
          </FormControl>
          <FormControl>
            <FormLabel>Amount</FormLabel>
            <Input value={squidParams.fromAmount} onChange={(e) => setSquidParams({...squidParams, fromAmount: e.target.value})} />
          </FormControl>
        </>
      )}

      {(selectedFunction !== 'EVMthenThor' ) && (
          <VStack spacing={4} align="stretch">
          <Heading as="h2" size="md" mb={4}>Chainflip CCM Parameters</Heading>
            <FormControl>
              <FormLabel>Destination Chain</FormLabel>
              <Input name="dstChain" value={chainflipParams.dstChain} onChange={handleChainflipInputChange} type="number" />
            </FormControl>
            <FormControl>
              <FormLabel>Destination Address</FormLabel>
              <Input name="dstAddress" value={chainflipParams.dstAddress} onChange={handleChainflipInputChange} />
            </FormControl>
            <FormControl>
              <FormLabel>Destination Token</FormLabel>
              <Input name="dstToken" value={chainflipParams.dstToken} onChange={handleChainflipInputChange} type="number" />
            </FormControl>
            <FormControl>
              <FormLabel>Source Token</FormLabel>
              <Input name="srcToken" value={chainflipParams.srcToken} onChange={handleChainflipInputChange} />
            </FormControl>
            <FormControl>
              <FormLabel>Amount</FormLabel>
              <Input name="amount" value={chainflipParams.amount} onChange={handleChainflipInputChange} />
            </FormControl>
            </VStack>
  )}
  {(selectedFunction === 'swapViaChainflipCCM' || selectedFunction === 'EVMThenChainflipCCM' || selectedFunction === 'odosSwapThenChainflipCMM') && (
              <VStack spacing={4} align="stretch">
            <FormControl>
              <FormLabel>Gas Budget</FormLabel>
              <Input name="gasBudget" value={chainflipParams.gasBudget} onChange={handleChainflipInputChange} />
            </FormControl>
            <FormControl>
              <FormLabel>CF Parameters</FormLabel>
              <Input name="cfParameters" value={chainflipParams.cfParameters} onChange={handleChainflipInputChange} />
            </FormControl>
            </VStack>
  )}
  
    
          {(selectedFunction === 'EVMThenChainflipCCM' || selectedFunction === 'EVMThenChainflip' || selectedFunction === 'EVMthenThor')  && (
            <FormControl mt={4}>
              <FormLabel>Min Total Output Amount</FormLabel>
              <Input value={minOutputAmount} onChange={(e) => setMinOutputAmount(e.target.value)} />
            </FormControl>
          )}
    
          <Checkbox isChecked={isEthSwap} onChange={(e) => setIsEthSwap(e.target.checked)} mt={4}>
            Is ETH Swap
          </Checkbox>
          
          {/* {!isEthSwap && (
            <Button mt={4} colorScheme="teal" onClick={approveToken} isDisabled={!contractAddress}>
              Approve Token
            </Button>
          )} */}
          
          <Button mt={4} colorScheme="green" onClick={handleSubmit} isDisabled={!contractAddress}>
            Execute {selectedFunction}
          </Button>
        </Box>
      </Flex>
    );
  }

export default ChainflipCCMSwap;