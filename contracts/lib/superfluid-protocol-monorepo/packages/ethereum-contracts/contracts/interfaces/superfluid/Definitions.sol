// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

/**
 * @title Super app definitions library
 * @author Superfluid
 */
library SuperAppDefinitions {
    /**
     *
     * / App manifest config word
     * /*************************************************************************
     */

    /*
     * App level is a way to allow the app to whitelist what other app it can
     * interact with (aka. composite app feature).
     *
     * For more details, refer to the technical paper of superfluid protocol.
     */
    uint256 internal constant APP_LEVEL_MASK = 0xFF;

    // The app is at the final level, hence it doesn't want to interact with any other app
    uint256 internal constant APP_LEVEL_FINAL = 1 << 0;

    // The app is at the second level, it may interact with other final level apps if whitelisted
    uint256 internal constant APP_LEVEL_SECOND = 1 << 1;

    function getAppCallbackLevel(uint256 configWord) internal pure returns (uint8) {
        return uint8(configWord & APP_LEVEL_MASK);
    }

    uint256 internal constant APP_JAIL_BIT = 1 << 15;

    function isAppJailed(uint256 configWord) internal pure returns (bool) {
        return (configWord & SuperAppDefinitions.APP_JAIL_BIT) > 0;
    }

    /**
     *
     * / Callback implementation bit masks
     * /*************************************************************************
     */
    uint256 internal constant AGREEMENT_CALLBACK_NOOP_BITMASKS = 0xFF << 32;
    uint256 internal constant BEFORE_AGREEMENT_CREATED_NOOP = 1 << (32 + 0);
    uint256 internal constant AFTER_AGREEMENT_CREATED_NOOP = 1 << (32 + 1);
    uint256 internal constant BEFORE_AGREEMENT_UPDATED_NOOP = 1 << (32 + 2);
    uint256 internal constant AFTER_AGREEMENT_UPDATED_NOOP = 1 << (32 + 3);
    uint256 internal constant BEFORE_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 4);
    uint256 internal constant AFTER_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 5);

    /**
     *
     * / App Jail Reasons
     * /*************************************************************************
     */
    uint256 internal constant APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK = 10;
    uint256 internal constant APP_RULE_NO_CRITICAL_SENDER_ACCOUNT = 11;
    uint256 internal constant APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT = 12;
    uint256 internal constant APP_RULE_CTX_IS_READONLY = 20;
    uint256 internal constant APP_RULE_CTX_IS_NOT_CLEAN = 21;
    uint256 internal constant APP_RULE_CTX_IS_MALFORMATED = 22;
    uint256 internal constant APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED = 30;
    uint256 internal constant APP_RULE_COMPOSITE_APP_IS_JAILED = 31;
    uint256 internal constant APP_RULE_MAX_APP_LEVEL_REACHED = 40;

    // Validate configWord cleaness for future compatibility, or else may introduce undefined future behavior
    function isConfigWordClean(uint256 configWord) internal pure returns (bool) {
        return (configWord & ~(APP_LEVEL_MASK | APP_JAIL_BIT | AGREEMENT_CALLBACK_NOOP_BITMASKS)) == uint256(0);
    }
}

/**
 * @title Context definitions library
 * @author Superfluid
 */
library ContextDefinitions {
    /**
     *
     * / Call info
     * /*************************************************************************
     */

    // app level
    uint256 internal constant CALL_INFO_APP_LEVEL_MASK = 0xFF;

    // call type
    uint256 internal constant CALL_INFO_CALL_TYPE_SHIFT = 32;
    uint256 internal constant CALL_INFO_CALL_TYPE_MASK = 0xF << CALL_INFO_CALL_TYPE_SHIFT;
    uint8 internal constant CALL_INFO_CALL_TYPE_AGREEMENT = 1;
    uint8 internal constant CALL_INFO_CALL_TYPE_APP_ACTION = 2;
    uint8 internal constant CALL_INFO_CALL_TYPE_APP_CALLBACK = 3;

    function decodeCallInfo(uint256 callInfo) internal pure returns (uint8 appCallbackLevel, uint8 callType) {
        appCallbackLevel = uint8(callInfo & CALL_INFO_APP_LEVEL_MASK);
        callType = uint8((callInfo & CALL_INFO_CALL_TYPE_MASK) >> CALL_INFO_CALL_TYPE_SHIFT);
    }

    function encodeCallInfo(uint8 appCallbackLevel, uint8 callType) internal pure returns (uint256 callInfo) {
        return uint256(appCallbackLevel) | (uint256(callType) << CALL_INFO_CALL_TYPE_SHIFT);
    }
}

/**
 * @title Flow Operator definitions library
 * @author Superfluid
 */
library FlowOperatorDefinitions {
    uint8 internal constant AUTHORIZE_FLOW_OPERATOR_CREATE = uint8(1) << 0;
    uint8 internal constant AUTHORIZE_FLOW_OPERATOR_UPDATE = uint8(1) << 1;
    uint8 internal constant AUTHORIZE_FLOW_OPERATOR_DELETE = uint8(1) << 2;
    uint8 internal constant AUTHORIZE_FULL_CONTROL =
        AUTHORIZE_FLOW_OPERATOR_CREATE | AUTHORIZE_FLOW_OPERATOR_UPDATE | AUTHORIZE_FLOW_OPERATOR_DELETE;
    uint8 internal constant REVOKE_FLOW_OPERATOR_CREATE = ~(uint8(1) << 0);
    uint8 internal constant REVOKE_FLOW_OPERATOR_UPDATE = ~(uint8(1) << 1);
    uint8 internal constant REVOKE_FLOW_OPERATOR_DELETE = ~(uint8(1) << 2);

    function isPermissionsClean(uint8 permissions) internal pure returns (bool) {
        return (
            permissions
                & ~(AUTHORIZE_FLOW_OPERATOR_CREATE | AUTHORIZE_FLOW_OPERATOR_UPDATE | AUTHORIZE_FLOW_OPERATOR_DELETE)
        ) == uint8(0);
    }
}

/**
 * @title Batch operation library
 * @author Superfluid
 */
library BatchOperation {
    /**
     * @dev ERC20.approve batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationApprove(
     *     abi.decode(data, (address spender, uint256 amount))
     * )
     */
    uint32 internal constant OPERATION_TYPE_ERC20_APPROVE = 1;
    /**
     * @dev ERC20.transferFrom batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationTransferFrom(
     *     abi.decode(data, (address sender, address recipient, uint256 amount)
     * )
     */
    uint32 internal constant OPERATION_TYPE_ERC20_TRANSFER_FROM = 2;
    /**
     * @dev ERC777.send batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationSend(
     *     abi.decode(data, (address recipient, uint256 amount, bytes userData)
     * )
     */
    uint32 internal constant OPERATION_TYPE_ERC777_SEND = 3;
    /**
     * @dev ERC20.increaseAllowance batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationIncreaseAllowance(
     *     abi.decode(data, (address account, address spender, uint256 addedValue))
     * )
     */
    uint32 internal constant OPERATION_TYPE_ERC20_INCREASE_ALLOWANCE = 4;
    /**
     * @dev ERC20.decreaseAllowance batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDecreaseAllowance(
     *     abi.decode(data, (address account, address spender, uint256 subtractedValue))
     * )
     */
    uint32 internal constant OPERATION_TYPE_ERC20_DECREASE_ALLOWANCE = 5;
    /**
     * @dev SuperToken.upgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 internal constant OPERATION_TYPE_SUPERTOKEN_UPGRADE = 1 + 100;
    /**
     * @dev SuperToken.downgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 internal constant OPERATION_TYPE_SUPERTOKEN_DOWNGRADE = 2 + 100;
    /**
     * @dev SuperToken.upgradeTo batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgradeTo(
     *     abi.decode(data, (address to, uint256 amount)
     * )
     */
    uint32 internal constant OPERATION_TYPE_SUPERTOKEN_UPGRADE_TO = 3 + 100;
    /**
     * @dev SuperToken.downgradeTo batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngradeTo(
     *     abi.decode(data, (address to, uint256 amount)
     * )
     */
    uint32 internal constant OPERATION_TYPE_SUPERTOKEN_DOWNGRADE_TO = 4 + 100;
    /**
     * @dev Superfluid.callAgreement batch operation type
     *
     * Call spec:
     * callAgreement(
     *     ISuperAgreement(target)),
     *     abi.decode(data, (bytes callData, bytes userData)
     * )
     */
    uint32 internal constant OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT = 1 + 200;
    /**
     * @dev Superfluid.callAppAction batch operation type
     *
     * Call spec:
     * callAppAction(
     *     ISuperApp(target)),
     *     data
     * )
     */
    uint32 internal constant OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION = 2 + 200;
    /**
     * @dev SimpleForwarder.forwardCall batch operation type
     *
     * Call spec:
     * forwardCall(
     *     target,
     *     data
     * )
     * NOTE: This operation allows to make arbitrary calls to arbitrary targets.
     * The calls are routed through a dedicated utility contract `SimpleForwarder`.
     * This is important because the host contract has privileged access to other framework contracts,
     * SuperTokens, SuperApps etc.
     * Allowing arbitrary calls to arbitrary targets with the host as sender would thus be unsafe.
     */
    uint32 internal constant OPERATION_TYPE_SIMPLE_FORWARD_CALL = 1 + 300;
    /**
     * @dev ERC2771Forwarder.forward2771Call batch operation type
     *
     * Call spec:
     * forward2771Call(
     *     target,
     *     msgSender,
     *     data
     * )
     *
     * NOTE: In the context of this operation, the `ERC2771Forwarder` contract acts as the
     * _trusted forwarder_ which must be trusted by the _recipient contract_ (operation target).
     * It shall do so by dynamically looking up the ERC2771Forwarder used by the host, like this:
     *
     * function isTrustedForwarder(address forwarder) public view returns(bool) {
     *     return forwarder == address(host.getERC2771Forwarder());
     * }
     *
     * If used in the context of a `forwardBatchCall`, we effectively have a chaining/nesting
     * of ERC-2771 calls where the host acts as _recipient contract_ of the enveloping 2771 call
     * and the ERC2771Forwarder acts as the _trusted forwarder_ of the nested 2771 call(s).
     * That's why `msgSender` could be either the actual `msg.sender` (if using `batchCall`)
     * or the relayed sender address (if using `forwardBatchCall`).
     */
    uint32 internal constant OPERATION_TYPE_ERC2771_FORWARD_CALL = 2 + 300;
}

/**
 * @title Superfluid governance configs library
 * @author Superfluid
 */
library SuperfluidGovernanceConfigs {
    bytes32 internal constant SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");
    bytes32 internal constant CFAV1_PPP_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.PPPConfiguration");
    bytes32 internal constant SUPERTOKEN_MINIMUM_DEPOSIT_KEY =
        keccak256("org.superfluid-finance.superfluid.superTokenMinimumDeposit");

    function getTrustedForwarderConfigKey(address forwarder) internal pure returns (bytes32) {
        return keccak256(abi.encode("org.superfluid-finance.superfluid.trustedForwarder", forwarder));
    }

    function getAppRegistrationConfigKey(address deployer, string memory registrationKey)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode("org.superfluid-finance.superfluid.appWhiteListing.registrationKey", deployer, registrationKey)
        );
    }

    function getAppFactoryConfigKey(address factory) internal pure returns (bytes32) {
        return keccak256(abi.encode("org.superfluid-finance.superfluid.appWhiteListing.factory", factory));
    }

    function decodePPPConfig(uint256 pppConfig)
        internal
        pure
        returns (uint256 liquidationPeriod, uint256 patricianPeriod)
    {
        liquidationPeriod = (pppConfig >> 32) & type(uint32).max;
        patricianPeriod = pppConfig & type(uint32).max;
    }
}
