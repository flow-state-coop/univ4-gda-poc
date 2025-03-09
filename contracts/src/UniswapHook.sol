// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/Test.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {VirtualUnits} from "./VirtualUnits.sol";

contract UniswapHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    address public virtualUnits;

    constructor(IPoolManager _poolManager, address _virtualUnits) BaseHook(_poolManager) {
        virtualUnits = _virtualUnits;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: true,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        bool isToken0 = Currency.unwrap(key.currency0) == virtualUnits;

        if (isToken0 && params.zeroForOne) {
            uint256 deltaAmount0 = uint256(int256(-delta.amount0()));

            VirtualUnits(virtualUnits).burnUnits(tx.origin, deltaAmount0);
        } else if (!isToken0 && params.zeroForOne) {
            uint256 deltaAmount1 = uint256(int256(delta.amount1()));

            VirtualUnits(virtualUnits).mintUnits(tx.origin, deltaAmount1);
        } else if (isToken0 && !params.zeroForOne) {
            uint256 deltaAmount0 = uint256(int256(delta.amount0()));

            VirtualUnits(virtualUnits).mintUnits(tx.origin, deltaAmount0);
        } else if (!isToken0 && !params.zeroForOne) {
            uint256 deltaAmount1 = uint256(int256(-delta.amount1()));

            VirtualUnits(virtualUnits).burnUnits(tx.origin, deltaAmount1);
        }

        return (BaseHook.afterSwap.selector, 0);
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        bool isToken0 = Currency.unwrap(key.currency0) == virtualUnits;

        uint256 deltaAmount = uint256(int256(isToken0 ? -delta.amount0() : -delta.amount1()));

        VirtualUnits(virtualUnits).burnUnits(tx.origin, deltaAmount);

        return (BaseHook.afterAddLiquidity.selector, delta);
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        bool isToken0 = Currency.unwrap(key.currency0) == virtualUnits;

        uint256 deltaAmount = uint256(int256(isToken0 ? delta.amount0() : delta.amount1()));

        VirtualUnits(virtualUnits).mintUnits(tx.origin, deltaAmount);

        return (BaseHook.afterRemoveLiquidity.selector, delta);
    }
}
