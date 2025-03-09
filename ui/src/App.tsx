import { useState } from "react";
import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { base } from "wagmi/chains";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import Header from "./components/Header";
import Swap from "./components/Swap";
import "bootstrap/dist/css/bootstrap.min.css";

const config = getDefaultConfig({
  appName: "Uni V4 GDA POC",
  projectId: import.meta.env.VITE_WALLET_CONNECT_PROJECT_ID,
  chains: [base],
  ssr: true,
});
const queryClient = new QueryClient();

export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <Header />
          <Swap />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
