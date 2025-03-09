import { useState } from "react";
import { Address, parseEther } from "viem";
import { useAccount, useConfig, useReadContract } from "wagmi";
import { writeContract } from "@wagmi/core";
import Stack from "react-bootstrap/Stack";
import Form from "react-bootstrap/Form";
import Button from "react-bootstrap/Button";
import Alert from "react-bootstrap/Alert";
import Spinner from "react-bootstrap/Spinner";
import PoolConnectionButton from "./PoolConnectionButton";
import { swapperAbi } from "../abi/swapper";
import { erc20Abi } from "../abi/erc20";
import { gdaForwarderAbi } from "../abi/gdaForwarder";

const SWAPPER = "0x9b4B3e8D33d64EACabffd414dc6cc7b7Ea42e722";
const VIRTUAL_GDA = "0x6745b438dfaD081Dfe9740FDFF38d96865cF1729";
const GDAy = "0xAc89c2aEa192d404801a3334a071504a4Bc7AC63";
const TOKEN = "0x58e0e291ebf6e03efeff6ef628ae34114545d0ed";
const HOOK = "0x9424Ff87a08da0F96ed2212dA91FD439b5f98540";
const GDA_FORWARDER = "0x6DA13Bde224A05a288748d857b9e7DDEffd1dE08";
const MIN_PRICE_LIMIT = BigInt(4295128739) + BigInt(1);
const MAX_PRICE_LIMIT =
  BigInt("1461446703485210103287273052203988822378723970342") - BigInt(1);

export default function Swap() {
  const [tokenAmount, setTokenAmount] = useState("");
  const [virtualUnitsAmount, setVirtualUnitsAmount] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(false);

  const { address } = useAccount();
  const wagmiConfig = useConfig();
  const { data: isConnectedToPool } = useReadContract({
    address: GDA_FORWARDER,
    abi: gdaForwarderAbi,
    functionName: "isMemberConnected",
    args: [GDAy as Address, address ?? "0x"],
    query: { refetchInterval: 5000 },
  });

  const swap = async () => {
    const amount = virtualUnitsAmount ? virtualUnitsAmount : tokenAmount;

    setSuccess(false);
    setError(false);
    setIsLoading(true);

    try {
      await writeContract(wagmiConfig, {
        abi: erc20Abi,
        address: VIRTUAL_GDA,
        functionName: "approve",
        args: [SWAPPER, parseEther((Number(amount) * 10).toString())],
      });
      await writeContract(wagmiConfig, {
        abi: erc20Abi,
        address: TOKEN,
        functionName: "approve",
        args: [SWAPPER, parseEther((Number(amount) * 10).toString())],
      });
      const zeroForOne = virtualUnitsAmount ? true : false;
      const sqrtPriceLimitX96 = zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT;

      await writeContract(wagmiConfig, {
        abi: swapperAbi,
        address: SWAPPER as Address,
        functionName: "swap",
        args: [
          {
            currency0: TOKEN as Address,
            currency1: VIRTUAL_GDA as Address,
            fee: 3000,
            tickSpacing: 60,
            hooks: HOOK as Address,
          },
          {
            zeroForOne,
            amountSpecified: parseEther(amount),
            sqrtPriceLimitX96,
          },
          { takeClaims: false, settleUsingBurn: false },
          "0x",
        ],
      });
      setIsLoading(false);
      setSuccess(true);
    } catch (err) {
      console.error(err);
      setError(true);
      setIsLoading(false);
    }
  };

  return (
    <>
      <Stack
        direction="vertical"
        className="w-50 mx-auto my-5 px-3 py-2 border border-light rounded-4 shadow"
      >
        <h1>Swap</h1>
        <Form className="d-flex flex-column flex-sm-row gap-2 w-100 mt-3">
          <Form.Group className="w-50 mb-3">
            <Form.Label>Token</Form.Label>
            <Form.Control
              type="text"
              value={tokenAmount}
              onChange={(e) => {
                setTokenAmount(e.target.value);
                setVirtualUnitsAmount("");
              }}
            />
          </Form.Group>
          <Form.Group className="w-50 mb-3">
            <Form.Label>GDA</Form.Label>
            <Form.Control
              type="text"
              value={virtualUnitsAmount}
              onChange={(e) => {
                setVirtualUnitsAmount(e.target.value);
                setTokenAmount("");
              }}
            />
          </Form.Group>
        </Form>
        <Button
          disabled={!tokenAmount && !virtualUnitsAmount}
          className="mt-3 w-100"
          onClick={swap}
        >
          {isLoading ? <Spinner size="sm" /> : "Swap"}
        </Button>
        {success &&<Alert variant="success" className='mt-2'>Success!</Alert>}
        {error &&<Alert variant="danger" className='mt-2'>Error!</Alert>}
      </Stack>
      <Stack
        direction="vertical"
        className="w-50 mx-auto my-5 px-3 py-2 border border-light rounded-4 shadow"
      >
        <h2 className="mb-3">Connect to Distribution Pool</h2>
        <PoolConnectionButton
          isConnected={isConnectedToPool ?? false}
          poolAddress={GDAy}
        />
      </Stack>
    </>
  );
}
