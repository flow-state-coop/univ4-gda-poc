// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {console} from "forge-std/Test.sol";
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
    PoolManager uniswapPoolManager = PoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b);

    constructor(uint256 _initialSupply, ISuperToken _poolSuperToken) ERC20("GDA", "GDA") {
        _mint(msg.sender, _initialSupply);
        gdaPool = SuperTokenV1Library.createPoolWithCustomERC20Metadata(
            _poolSuperToken, address(this), PoolConfig(false, true), PoolERC20Metadata("Superfluid Pool", "POOL", 0)
        );
        gdaPool.updateMemberUnits(msg.sender, uint128(_initialSupply));
        uint160 flags =
            uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG);
        bytes memory constructorArgs = abi.encode(address(uniswapPoolManager), address(this));
        (, bytes32 salt) = HookMiner.find(address(this), flags, type(UniswapHook).creationCode, constructorArgs);
        uniswapHook = new UniswapHook{salt: salt}(uniswapPoolManager, address(this));
    }

    function mintUnits(address from, uint256 amount) public {
        if (msg.sender != address(uniswapHook)) {
            revert UNAUTHORIZED();
        }

        uint256 memberUnits = gdaPool.balanceOf(from);

        gdaPool.updateMemberUnits(from, uint128(memberUnits + amount));
    }

    function burnUnits(address from, uint256 amount) public {
        if (msg.sender != address(uniswapHook)) {
            revert UNAUTHORIZED();
        }

        uint256 memberUnits = gdaPool.balanceOf(from);
        console.logUint(memberUnits);

        gdaPool.updateMemberUnits(from, uint128(memberUnits - amount));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        uint256 ownerUnits = gdaPool.getUnits(owner);
        uint256 recipientUnits = gdaPool.getUnits(to);

        _transfer(owner, to, amount);
        gdaPool.updateMemberUnits(to, uint128(recipientUnits + amount));
        gdaPool.updateMemberUnits(owner, uint128(ownerUnits - amount));

        return true;
    }
}
