// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {VirtualUnits} from "../src/VirtualUnits.sol";
import {
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {
    PoolConfig,
    PoolERC20Metadata
} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {UniswapHook} from "../src/UniswapHook.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {PoolManager} from "v4-core/src/PoolManager.sol";

contract DeployVirtualToken is Script {
    function run() public {
        ISuperfluidPool gdaPool;
        UniswapHook uniswapHook;
        VirtualUnits virtualUnits;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ISuperToken poolSuperToken = ISuperToken(0x46fd5cfB4c12D87acD3a13e92BAa53240C661D93);
        virtualUnits = new VirtualUnits(1000000000 * 1e18, poolSuperToken);

        uniswapHook = virtualUnits.uniswapHook();
        gdaPool = virtualUnits.gdaPool();

        console.logAddress(address(virtualUnits));
        console.logAddress(address(gdaPool));
        console.logAddress(address(uniswapHook));

        vm.stopBroadcast();
    }
}
