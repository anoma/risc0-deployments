// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {RiscZeroGroth16Verifier} from "risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol";

import {DeployRiscZeroVerifier} from "../script/DeployRiscZeroVerifier.s.sol";

contract DeployRiscZeroVerifierTest is Test {
    function test_DeployRiscZeroVerifier_puts_the_groth16_verifier_behind_an_emergency_stop_of_the_guardian() public {
        address guardian = makeAddr("guardian");

        (RiscZeroVerifierEmergencyStop emergencyStop, RiscZeroGroth16Verifier groth16Verifier) =
            new DeployRiscZeroVerifier().run({guardian: guardian});

        assertEq(address(emergencyStop.verifier()), address(groth16Verifier));
        assertEq(emergencyStop.owner(), guardian);
    }
}
