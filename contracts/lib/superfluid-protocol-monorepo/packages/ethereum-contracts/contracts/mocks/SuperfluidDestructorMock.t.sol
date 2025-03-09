// SPDX-License-Identifier: AGPLv3
// solhint-disable
pragma solidity ^0.8.23;

contract SuperfluidDestructorMock {
    bool public immutable NON_UPGRADABLE_DEPLOYMENT = false;

    fallback() external {
        // this == impl in this call
        assembly {
            selfdestruct(0)
        }
    }
}
