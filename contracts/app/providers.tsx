"use client";
import { ReactNode } from "react";
import { Provider } from "react-redux";
import { ChakraProvider } from "@chakra-ui/react";
import { theme } from "@/theme/theme";

const Providers = ({ children }: { children: ReactNode }) => {
  return (
          <ChakraProvider theme={theme}>
                {children}
          </ChakraProvider>
  );
};

export default Providers;

