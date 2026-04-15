// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Versioning
/// @author Anoma Foundation, 2025
/// @notice A library containing the RISC Zero verifier selectors for the supported networks.
/// @custom:security-contact security@anoma.foundation
library RiscZeroVerifierSelectors {
    /// @notice The Groth16 RISC Zero verifier selector.
    bytes4 internal constant _GROTH16_VERIFIER_SELECTOR = 0x73c457ba;
}
