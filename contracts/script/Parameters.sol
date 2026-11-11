// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Parameters
/// @author Anoma Foundation, 2026
/// @notice The accounts of the verifier scripts: the PA Safe, and the deployment wallet, which deploys the verifiers and
/// proposes to the PA Safe.
/// @custom:security-contact security@anoma.foundation
library Parameters {
    /// @notice The deployment wallet, which can propose transactions to the PA Safe on every chain.
    address internal constant DEPLOYMENT_WALLET = 0x61462bE56782568376f9cB069382EFa72764a407;

    /// @notice The protocol adapter multisig, a Safe that owns the routers that Anoma deployed and guards their
    /// emergency stops.
    address internal constant PA_MULTISIG = 0xE9082Ac8Aa2Fb27DEfDBAC604921C196b884Da10;
}
