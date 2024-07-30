import { motion } from 'framer-motion';
import Modal from 'react-modal';
import Button from '@/components/common/Button';
import { WalletsProviders } from '@/services/wallets';
import { Wallet } from '@/types/wallet';
import { generateError, throwNotification } from '@/utils/notification';
import Image from 'next/image';
import { useMemo, useState } from 'react';
import { useDispatch } from 'react-redux';
import PopupModal from '@/components/common/PopupModal';


interface Props {
  openKeystoreMenuModal: (bool: boolean) => void;
  openLedgerModal: (bool: boolean) => void;
  closeModal: () => void;
}

const ConnectModal = ({ openKeystoreMenuModal, openLedgerModal, closeModal }: Props) => {
  const dispatch = useDispatch();
  const [isChecked, setIsChecked] = useState(false);
  const [loading, setIsLoading] = useState(false);
  const [selectedWallet, setSelectedWallet] = useState<Wallet | undefined>();

  const canConnect = isChecked && selectedWallet;

  const handleCheckboxChange = (event: React.ChangeEvent<HTMLInputElement>) =>
    setIsChecked(event.target.checked);

  const connect = async () => {
    if (!canConnect || !selectedWallet) return
    setIsLoading(true)

    try {
      if (selectedWallet.name.toLowerCase() === 'keystore') {
        openKeystoreMenuModal(true)
      } else if (selectedWallet.name.toLowerCase() === 'ledger') {
        openLedgerModal(true)
      } else await selectedWallet.connect(dispatch)
      closeModal()
    } catch (e) {
      console.error(e)
      throwNotification(
        generateError('Error occurred trying to connect your wallet')
      )
      closeModal()
    }

    return Promise.resolve()
  }

  const animationVariants = {
    hidden: { opacity: 0, y: -100 },
    visible: { opacity: 1, y: 0 },
  };


  const modalStyles = {
    content: {
      background: 'rgba(255, 255, 255, 0.7)', // Semi-transparent background
      border: '1px solid #ccc',
      borderRadius: '10px',
      width: '60%', // Adjusted width
      maxWidth: '400px', // Maximum width, adjust as needed
      height: 'fit-content', // Adjusted to content
      maxHeight: '90vh', // Optional: Maximum height
      margin: 'auto', // Centers the modal horizontally and vertically
      display: 'flex', // Flex layout to center content
      flexDirection: 'column', // Column layout for internal content
      justifyContent: 'space-between',
    },
    overlay: {
      backgroundColor: 'rgba(0, 0, 0, 0.5)', // Dark overlay
      backdropFilter: 'blur(5px)', // Blur effect for the background
      display: 'flex',
      alignItems: 'center', // Align modal vertically in the center
      justifyContent: 'center', // Align modal horizontally in the center
    },
  };
  return (
    <Modal isOpen={true} onRequestClose={closeModal} style={modalStyles}>
      <motion.div
        initial="hidden"
        animate="visible"
        variants={animationVariants}
        transition={{ duration: 0.5 }}
      >
      <h2 className="text-lg font-bold text-center my-4 text-gray-800">Connect Wallet</h2>
       <div className="grid grid-cols-3 gap-2 md:grid-cols-2 sm:grid-cols-2 sm:overflow-y-auto sm:overflow-x-hidden">
        {WalletsProviders().map((wallet: Wallet, index) => {
          return (
            <div
              className={`flex flex-col justify-center items-center gap-4 cursor-pointer h-28 bg-transparent border border-borderUnselected hover:border-borderSelected hover:scale-105 transition-all duration-300 ease-in-out rounded-20 font-medium text-sm ${
                selectedWallet?.name === wallet.name
                  ? 'border-borderSelected scale-105 transition-all duration-300'
                  : selectedWallet && selectedWallet.name !== wallet.name
                  ? 'opacity-25 transition-all duration-300'
                  : ''
              }`}
              key={index}
              onClick={() => setSelectedWallet(wallet)}
            >
              <Image
                className="cursor-pointer"
                src={`${wallet.icon}`}
                alt="close-icon"
                width="32"
                height="32"
              />
              <p className="font-normal">{wallet.name}</p>
            </div>
          )
        })}
      </div>
      <div className="mt-4">
        <Button
          text={'Connect'}
          onClick={connect}
        />
      </div>
    </motion.div>
    </Modal>
  )
}

export default ConnectModal


import { FC } from 'react'
import styled, { css } from 'styled-components';

const StyledButton = styled.div<{ isActive: boolean; isLoading?: boolean }>`
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 3.5rem; // Equivalent to 'h-14'
  font-weight: bold;
  background-color: #B67652; // Adjust the color to fit your theme
  color: black;
  border-radius: 20px; // Equivalent to 'rounded-20'
  margin-top: 0.5rem; // Equivalent to 'mt-2'
  transition: all 300ms;
  cursor: ${(props) => (props.isActive ? 'pointer' : 'not-allowed')};
  opacity: ${(props) => (props.isActive ? 1 : 0.25)};

  ${(props) =>
    props.isLoading &&
    css`
      /* Additional styles for loading state */
    `}

  &:hover {
    /* Hover styles if applicable */
  }
`;

interface Props {
  text: string
  onClick?: () => void
}

const Button: FC<Props> = ({ text, onClick }) => {
  return (
    <StyledButton isActive={true} onClick={onClick}>
      {(
        <svg
          className="animate-spin -ml-1 mr-3 h-5 w-5 text-black"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          ></circle>
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          ></path>
        </svg>
      )}
      {text}
    </StyledButton>
  );
};

export default Button


          {/* {max && (
            <span
              className="text-pink font-bold cursor-pointer"
              onClick={max}
            >
              Max
            </span>
          )} */}
