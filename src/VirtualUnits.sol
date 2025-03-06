// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
import {UniswapHook} from "./UniswapHook.sol";
import {PoolManager} from "v4-core/src/PoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

contract VirtualUnits is ERC20 {
    /// @notice Thrown if the caller does not have enough balance
    error INSUFFICIENT_BALANCE();
    /// @notice Thrown if the caller is not authorized
    error UNAUTHORIZED();

    ISuperfluidPool public gdaPool;
    UniswapHook public uniswapHook;

    address constant CREATE2_DEPLOYER = address(0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2);

    constructor(uint256 _initialSupply, ISuperToken _poolSuperToken) ERC20("Virtual Units", "VU") {
        _mint(msg.sender, _initialSupply);
        gdaPool = SuperTokenV1Library.createPoolWithCustomERC20Metadata(
            _poolSuperToken, address(this), PoolConfig(false, true), PoolERC20Metadata("Superfluid Pool", "POOL", 0)
        );
        PoolManager uniswapPoolManager = new PoolManager(address(this));
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );
        bytes memory constructorArgs = abi.encode(address(uniswapPoolManager));
        (, bytes32 salt) =
            HookMiner.find(address(this), flags, type(UniswapHook).creationCode, constructorArgs);
        uniswapHook = new UniswapHook{salt: salt}(uniswapPoolManager);
    }

    function mintUnits(address from, uint256 amount) external {
        if (msg.sender != address(uniswapHook)) {
            revert UNAUTHORIZED();
        }

        uint256 memberUnits = gdaPool.balanceOf(from);

        if (memberUnits < amount) {
            revert INSUFFICIENT_BALANCE();
        }

        _mint(from, (amount));
        gdaPool.updateMemberUnits(from, uint128(memberUnits - amount));
    }

    function burnUnits(address from, uint256 amount) external {
        if (msg.sender != address(uniswapHook)) {
            revert UNAUTHORIZED();
        }

        if (balanceOf(from) < amount) {
            revert INSUFFICIENT_BALANCE();
        }

        uint256 memberUnits = gdaPool.balanceOf(from);

        _burn(from, amount);
        gdaPool.updateMemberUnits(from, uint128(memberUnits + amount));
    }
}
