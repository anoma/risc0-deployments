// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {
    ControlID,
    RiscZeroGroth16Verifier
} from "risc0-risc0-ethereum-3.1.0/contracts/src/groth16/RiscZeroGroth16Verifier.sol";

import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";

contract RiscZeroVerifierSelectorsTest is Test {
    function test_RiscZeroVerifierSelectors_the_groth16_selector_is_the_selector_of_the_groth16_verifier() public {
        RiscZeroGroth16Verifier groth16Verifier =
            new RiscZeroGroth16Verifier(ControlID.CONTROL_ROOT, ControlID.BN254_CONTROL_ID);

        assertEq(RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR, groth16Verifier.SELECTOR());
    }
}
