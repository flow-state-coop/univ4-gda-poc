import { useState } from "react";
import { Address } from "viem";
import { useAccount, useWriteContract, usePublicClient } from "wagmi";
import { gdaForwarderAbi } from "../abi/gdaForwarder";
import Button from "react-bootstrap/Button";
import Spinner from "react-bootstrap/Spinner";

const GDA_FORWARDER = "0x6DA13Bde224A05a288748d857b9e7DDEffd1dE08";

export default function PoolConnectionButton(props: {
  poolAddress: string;
  isConnected: boolean;
}) {
  const { poolAddress, isConnected } = props;

  const [isTransactionConfirming, setIsTransactionConfirming] = useState(false);

  const publicClient = usePublicClient();
  const { writeContractAsync } = useWriteContract();
  const { address } = useAccount();

  const handlePoolConnection = async () => {
    if (!address || !publicClient) {
      return;
    }

    try {
      setIsTransactionConfirming(true);

      const hash = await writeContractAsync({
        address: GDA_FORWARDER,
        abi: gdaForwarderAbi,
        functionName: "connectPool",
        args: [poolAddress as Address, "0x"],
      });

      await publicClient.waitForTransactionReceipt({
        hash,
        confirmations: 5,
      });

      setIsTransactionConfirming(false);
    } catch (err) {
      console.error(err);

      setIsTransactionConfirming(false);
    }
  };

  return (
    <Button
      onClick={handlePoolConnection}
      disabled={isConnected}
      className="w-100 text-white"
    >
      {isTransactionConfirming ? (
        <Spinner size="sm" />
      ) : isConnected ? (
        "Connected"
      ) : (
        "Connect"
      )}
    </Button>
  );
}
