// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std-1.17.0/src/Script.sol";
import {
    ControlID,
    RiscZeroGroth16Verifier
} from "risc0-risc0-ethereum-3.1.0/contracts/src/groth16/RiscZeroGroth16Verifier.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierEmergencyStop.sol";

contract DeployRiscZeroVerifier is Script {
    /// @notice Deploys the Groth16 verifier and the emergency stop of the current RISC Zero version for an existing
    /// router.
    /// @param guardian The address that can emergency stop the verifier.
    function run(address guardian)
        public
        returns (RiscZeroVerifierEmergencyStop emergencyStop, RiscZeroGroth16Verifier groth16Verifier)
    {
        vm.startBroadcast(msg.sender);

        groth16Verifier = new RiscZeroGroth16Verifier(ControlID.CONTROL_ROOT, ControlID.BN254_CONTROL_ID);

        emergencyStop = new RiscZeroVerifierEmergencyStop({_verifier: groth16Verifier, guardian: guardian});

        vm.stopBroadcast();
    }
}
