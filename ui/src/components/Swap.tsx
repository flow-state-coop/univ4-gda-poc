import { useState, useEffect } from "react";
import { Address, parseEther } from "viem";
import { useAccount, useConfig } from "wagmi";
import { writeContract } from "@wagmi/core";
import Stack from "react-bootstrap/Stack";
import Form from "react-bootstrap/Form";
import Button from "react-bootstrap/Button";
import { swapperAbi } from "../abi/swapper";
import { erc20Abi } from "../abi/erc20";

const SWAPPER = "0x9b4B3e8D33d64EACabffd414dc6cc7b7Ea42e722";
const VIRTUAL_GDA = "0x6745b438dfaD081Dfe9740FDFF38d96865cF1729";
const GDAy = "0xAc89c2aEa192d404801a3334a071504a4Bc7AC63";
const TOKEN = "0x58e0e291ebf6e03efeff6ef628ae34114545d0ed";
const HOOK = "0x9424Ff87a08da0F96ed2212dA91FD439b5f98540";
const MIN_PRICE_LIMIT = BigInt(4295128739) + BigInt(1);
const MAX_PRICE_LIMIT =
  BigInt("1461446703485210103287273052203988822378723970342") - BigInt(1);

export default function Swap() {
  const [tokenAmount, setTokenAmount] = useState("");
  const [virtualUnitsAmount, setVirtualUnitsAmount] = useState("");

  const { address } = useAccount();
  const wagmiConfig = useConfig();

  const swap = async () => {
    const amount = !!virtualUnitsAmount ? virtualUnitsAmount : tokenAmount;

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
    const zeroForOne = !!virtualUnitsAmount ? true : false;
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
        { zeroForOne, amountSpecified: parseEther(amount), sqrtPriceLimitX96 },
        { takeClaims: false, settleUsingBurn: false },
        "0x",
      ],
    });
  };

  return (
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
      <Button className="mt-3 w-100" onClick={swap}>
        Swap
      </Button>
    </Stack>
  );
}
