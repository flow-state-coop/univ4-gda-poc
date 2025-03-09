import Stack from "react-bootstrap/Stack";
import Navbar from "react-bootstrap/Navbar";
import Image from "react-bootstrap/Image";
import Logo from "../assets/logo.png";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function Header() {
  return (
    <>
      <Navbar className="w-100 border-bottom border-secondary border-opacity-25 shadow">
        <Stack
          direction="horizontal"
          className="justify-content-between w-100 px-4"
        >
          <Image src={Logo} alt="Logo" width={64} height={64} />
          <ConnectButton />
        </Stack>
      </Navbar>
    </>
  );
}
