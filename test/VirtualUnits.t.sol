// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
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
import {VirtualUnits} from "../src/VirtualUnits.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {UniswapHook} from "../src/UniswapHook.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {UniswapHook} from "../src/UniswapHook.sol";
import {EasyPosm} from "./utils/EasyPosm.sol";
import {PoolManager} from "v4-core/src/PoolManager.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

contract VirtualUnitsTest is Test {
    using CurrencyLibrary for Currency;
    using EasyPosm for IPositionManager;

    ISuperfluidPool gdaPool;
    UniswapHook uniswapHook;
    IERC20 usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    ISuperToken poolSuperToken = ISuperToken(0x46fd5cfB4c12D87acD3a13e92BAa53240C661D93);
    PoolManager uniswapPoolManager = PoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b);
    IPositionManager posm = IPositionManager(0x7C5f5A4bBd8fD63184577525326123B519429bDc);
    IAllowanceTransfer constant PERMIT2 = IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

    address firstAccount = makeAddr("firstAccount");
    address secondAccount = makeAddr("secondAccount");
    address usdcWhale = 0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549;
    VirtualUnits virtualUnits;

    function setUp() public {
        vm.createSelectFork({blockNumber: 27206486, urlOrAlias: "base"});
        console.logAddress(address(this));

        vm.startPrank(usdcWhale);

        usdc.transfer(address(this), 1000000);

        vm.stopPrank();

        vm.startPrank(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        virtualUnits = new VirtualUnits(1000000, poolSuperToken);
        uniswapHook = virtualUnits.uniswapHook();
        gdaPool = virtualUnits.gdaPool();

        address token0 = address(virtualUnits);
        address token1 = address(usdc); // USDC

        // fees paid by swappers that accrue to liquidity providers
        uint24 lpFee = 3000; // 0.30%
        int24 tickSpacing = 60;

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: uniswapHook
        });

        // starting price of the pool, in sqrtPriceX96
        uint160 startingPrice = 79228162514264337593543950336; // floor(sqrt(1) * 2^96)
        uniswapPoolManager.initialize(pool, startingPrice);

        int24 tickLower = -600; // must be a multiple of tickSpacing
        int24 tickUpper = 600;

        // Add liq
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            1000000,
            1000000
        );
        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            startingPrice, TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), 2000000
        );
        console.logUint(amount0Expected);
        console.logUint(amount1Expected);

        tokenApprovals(IERC20(token0), IERC20(token1));

        bytes memory hookData = new bytes(0);
        posm.mint(
            pool, tickLower, tickUpper, liquidity, 1000000 + 1, 1000000 + 1, address(this), block.timestamp, hookData
        );
    }

    function test_deployment() public view {
        assertTrue(address(uniswapHook) != address(0));
    }

    function tokenApprovals(IERC20 token0, IERC20 token1) public {
        token0.approve(address(PERMIT2), type(uint256).max);
        PERMIT2.approve(address(token0), address(posm), type(uint160).max, type(uint48).max);
        token1.approve(address(PERMIT2), type(uint256).max);
        PERMIT2.approve(address(token1), address(posm), type(uint160).max, type(uint48).max);
    }
}
