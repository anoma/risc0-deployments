// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Parameters
/// @author Anoma Foundation, 2026
/// @notice The accounts of the PA Safe proposals: the Safe that receives them and the account that proposes them.
/// @custom:security-contact security@anoma.foundation
library Parameters {
    /// @notice The deployment wallet, which can propose transactions to the PA Safe on every chain.
    address internal constant DEPLOYMENT_WALLET = 0x61462bE56782568376f9cB069382EFa72764a407;

    /// @notice The protocol adapter Safe, which owns the routers that Anoma deployed and guards their emergency stops,
    /// on every chain except BSC testnet.
    address internal constant PA_SAFE = 0xE9082Ac8Aa2Fb27DEfDBAC604921C196b884Da10;
}
