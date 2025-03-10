// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

import {ISuperToken} from "../superfluid/ISuperToken.sol";

/**
 * @title Super ETH (SETH) custom token interface
 * @author Superfluid
 */
interface ISETHCustom {
    // using native token
    function upgradeByETH() external payable;
    function upgradeByETHTo(address to) external payable;
    function downgradeToETH(uint256 wad) external;
}

/**
 * @title Super ETH (SETH) full interface
 * @author Superfluid
 */
// solhint-disable-next-line no-empty-blocks
interface ISETH is ISETHCustom, ISuperToken {}
