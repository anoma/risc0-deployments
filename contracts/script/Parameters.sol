// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Parameters
/// @author Anoma Foundation, 2026
/// @notice The accounts of the verifier scripts: the PA Safe, the deployment wallet that proposes to it, and the guardian
/// on BSC testnet, where the PA Safe does not exist.
/// @custom:security-contact security@anoma.foundation
library Parameters {
    /// @notice The deployment wallet, which can propose transactions to the PA Safe on every chain.
    address internal constant DEPLOYMENT_WALLET = 0x61462bE56782568376f9cB069382EFa72764a407;

    /// @notice The protocol adapter multisig, a Safe that owns the routers that Anoma deployed and guards their
    /// emergency stops, on every chain except BSC testnet.
    address internal constant PA_MULTISIG = 0xE9082Ac8Aa2Fb27DEfDBAC604921C196b884Da10;

    /// @notice The chain ID of BSC testnet.
    uint256 internal constant BSC_TESTNET_CHAIN_ID = 97;

    /// @notice The guardian of the emergency stops on BSC testnet.
    address internal constant BSC_TESTNET_GUARDIAN = 0xcD5679555424B5132E1bAbE1FD965c44BF1dDb7b;
}
