// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

import {ISuperToken} from "../superfluid/ISuperToken.sol";

/**
 * @title Pure Super Token custom interface
 * @author Superfluid
 */
interface IPureSuperTokenCustom {
    function initialize(string calldata name, string calldata symbol, uint256 initialSupply) external;
}

/**
 * @title Pure Super Token interface
 * @author Superfluid
 */
// solhint-disable-next-line no-empty-blocks
interface IPureSuperToken is IPureSuperTokenCustom, ISuperToken {}
