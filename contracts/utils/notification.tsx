import { iNotification } from '@/types/notification'
import { useToast } from '@chakra-ui/react'
import Image from 'next/image'
import toast from 'react-hot-toast'

export const generateError = (message: string): iNotification => {
  return {
    message,
    type: 'error',
  }
}

export const generateSuccess = (message: string): iNotification => {
  return {
    message,
    type: 'success',
  }
}

export const isNotification = (object: any): object is iNotification =>
  object.type === 'error' || object.type === 'success'

export const isError = (object: any): object is iNotification =>
  object.type === 'error'

export const isSuccess = (object: any): object is iNotification =>
  object.type === 'success'



export const throwNotification = (notification: iNotification) => {
  // const toast = useToast()
  const trimmedMessage = notification.message.length > 30 && notification.type === 'error' ? notification.message.substring(0, 30) + '...' : notification.message;
  toast[notification.type](trimmedMessage, {
    icon: notification.type === 'success' ? '✔️' : '❌',
    style: {
      borderRadius: '10px',
      background: '#333',
      color: '#fff',
    },
  });
  // toast({
  //   title: 'Account created.',
  //   description: notification.message,
  //   status: notification.type === 'success' ? 'success' : 'error',
  //   duration: 9000,
  //   isClosable: true,
  // })
};
