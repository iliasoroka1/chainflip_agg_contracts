import { Box } from "@chakra-ui/react";
import { ReactNode } from "react";
// import { Analytics } from '@vercel/analytics/react';

interface Props {
  children: ReactNode;
}

function Trade({ children }: Props) {
  return (
    // <Container>
    <Box>
      {children}
      </Box>
      // {/* <Analytics /> */}
    // </Container>
  );
};

export default Trade;
