// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";

contract DeploySwapper is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IPoolManager uniswapPoolManager = IPoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b);
        PoolSwapTest swapRouter = new PoolSwapTest(uniswapPoolManager);

        console.logAddress(address(swapRouter));

        vm.stopBroadcast();
    }
}
