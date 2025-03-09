// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {VirtualUnits} from "../src/VirtualUnits.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {UniswapHook} from "../src/UniswapHook.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId} from "v4-core/src/types/PoolId.sol";
import {UniswapHook} from "../src/UniswapHook.sol";
import {EasyPosm} from "./utils/EasyPosm.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

contract VirtualUnitsTest is Test {
    using CurrencyLibrary for Currency;
    using EasyPosm for IPositionManager;
    using StateLibrary for IPoolManager;

    ISuperfluidPool gdaPool;
    UniswapHook uniswapHook;
    VirtualUnits virtualUnits;
    IERC20 usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    ISuperToken poolSuperToken = ISuperToken(0x46fd5cfB4c12D87acD3a13e92BAa53240C661D93);
    IPoolManager uniswapPoolManager = IPoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b);
    IPositionManager posm = IPositionManager(0x7C5f5A4bBd8fD63184577525326123B519429bDc);
    IAllowanceTransfer permit2 = IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

    address firstAccount = makeAddr("firstAccount");
    address secondAccount = makeAddr("secondAccount");
    address usdcWhale = 0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549;

    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    // starting price of the pool, in sqrtPriceX96
    uint160 startingPrice = 79228162514264337593543950336; // floor(sqrt(1) * 2^96)
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    function setUp() public {
        vm.createSelectFork({blockNumber: 27206486, urlOrAlias: "base"});
        vm.startPrank(usdcWhale);

        usdc.transfer(address(this), 1000000);
        usdc.transfer(firstAccount, 200);

        vm.stopPrank();
        vm.startPrank(address(this), address(this));

        virtualUnits = new VirtualUnits(2000000, poolSuperToken);
        uniswapHook = virtualUnits.uniswapHook();
        gdaPool = virtualUnits.gdaPool();

        address token0 = address(virtualUnits);
        address token1 = address(usdc);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: uniswapHook
        });
        uniswapPoolManager.initialize(poolKey, startingPrice);

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            1000000,
            1000000
        );

        bytes memory hookData = new bytes(0);

        IERC20(token0).approve(address(permit2), type(uint256).max);
        permit2.approve(address(token0), address(posm), type(uint160).max, type(uint48).max);
        IERC20(token1).approve(address(permit2), type(uint256).max);
        permit2.approve(address(token1), address(posm), type(uint160).max, type(uint48).max);
        posm.mint(
            poolKey, tickLower, tickUpper, liquidity, 1000000 + 1, 1000000 + 1, address(this), block.timestamp, hookData
        );
    }

    function test_deployment() public view {
        assertTrue(address(virtualUnits) != address(0));
        assertTrue(address(uniswapHook) != address(0));
    }

    function test_swap() public {
        address token0 = address(virtualUnits);
        address token1 = address(usdc);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: uniswapHook
        });

        (uint160 sqrtPriceX96,,,) = uniswapPoolManager.getSlot0(poolKey.toId());

        assertEq(sqrtPriceX96, startingPrice);

        PoolSwapTest swapRouter = new PoolSwapTest(uniswapPoolManager);

        IERC20(token0).approve(address(swapRouter), type(uint256).max);
        IERC20(token1).approve(address(swapRouter), type(uint256).max);

        bool zeroForOne = false;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: 100,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
        });
        bytes memory hookData = new bytes(0);

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        uint256 unitsBefore = gdaPool.getUnits(address(this));
        uint256 virtualUnitsBefore = virtualUnits.balanceOf(address(this));

        swapRouter.swap(poolKey, params, testSettings, hookData);

        uint256 unitsAfter = gdaPool.getUnits(address(this));
        uint256 virtualUnitsAfter = virtualUnits.balanceOf(address(this));

        assertEq(virtualUnitsBefore, 1000000);
        assertEq(unitsBefore, 1000000);
        assertEq(virtualUnitsAfter, 1000100);
        assertEq(unitsAfter, 1000100);
    }

    function test_transferUnits() public {
        uint256 gdaUnitsBalanceBefore = gdaPool.getUnits(address(this));
        uint256 virtualUnitsBalanceBefore = virtualUnits.balanceOf(address(this));

        virtualUnits.transferUnits(firstAccount, 1000000);

        uint256 gdaUnitsBalanceAfter = gdaPool.getUnits(address(this));
        uint256 virtualUnitsBalanceAfter = virtualUnits.balanceOf(address(this));

        assertEq(gdaUnitsBalanceBefore, 1000000);
        assertEq(virtualUnitsBalanceBefore, 1000000);
        assertEq(gdaUnitsBalanceAfter, 0);
        assertEq(virtualUnitsBalanceAfter, 0);
    }
}
