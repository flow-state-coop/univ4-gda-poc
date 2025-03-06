// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
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

contract VirtualUnitsTest is Test {
    ISuperfluidPool _gdaPool;
    UniswapHook _uniswapHook;
    VirtualUnits _virtualUnits;
    ISuperToken _poolSuperToken = ISuperToken(0x46fd5cfB4c12D87acD3a13e92BAa53240C661D93);

    address firstAccount = makeAddr("firstAccount");
    address secondAccount = makeAddr("secondAccount");

    function setUp() public {
        vm.createSelectFork({blockNumber: 27206486, urlOrAlias: "base"});

        _virtualUnits = new VirtualUnits(100000, _poolSuperToken);
        _gdaPool = _virtualUnits.gdaPool();
        _uniswapHook = _virtualUnits.uniswapHook();
    }

    function test_deployment() public view {
        assertTrue(address(_virtualUnits) != address(0));
        assertTrue(address(_virtualUnits.gdaPool()) != address(0));
    }

    function test_mintUnits() public {
        __mintUnits();

        assertEq(_virtualUnits.balanceOf(firstAccount), 10);
    }

    function test_mintUnits_UNAUTHORIZED() public {
        vm.startPrank(address(_virtualUnits));

        _gdaPool.updateMemberUnits(firstAccount, 10);

        vm.warp(block.timestamp + 100);
        vm.startPrank(secondAccount);
        vm.expectRevert();

        _virtualUnits.mintUnits(firstAccount, 10);
    }

    function test_burnUnits_UNAUTHORIZED() public {
        __mintUnits();

        vm.warp(block.timestamp + 100);
        vm.startPrank(secondAccount);
        vm.expectRevert();

        _virtualUnits.burnUnits(firstAccount, 5);
    }

    function test_burnUnits() public {
        __mintUnits();

        assertEq(_virtualUnits.balanceOf(firstAccount), 10);

        __burnUnits();

        assertEq(_virtualUnits.balanceOf(firstAccount), 5);
        assertEq(_gdaPool.balanceOf(firstAccount), 5);
    }

    function __mintUnits() internal {
        vm.startPrank(address(_virtualUnits));

        _gdaPool.updateMemberUnits(firstAccount, 10);

        vm.warp(block.timestamp + 100);
        vm.startPrank(address(_uniswapHook));

        _virtualUnits.mintUnits(firstAccount, 10);
    }

    function __burnUnits() internal {
        vm.warp(block.timestamp + 100);
        vm.startPrank(address(_uniswapHook));

        _virtualUnits.burnUnits(firstAccount, 5);
    }
}
