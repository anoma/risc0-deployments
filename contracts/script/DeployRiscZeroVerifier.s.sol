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

import {Parameters} from "./Parameters.sol";

contract DeployRiscZeroVerifier is Script {
    /// @notice Deploys the Groth16 verifier and the emergency stop of the current RISC Zero version for an existing
    /// router from the deployment wallet. The PA Safe guards the emergency stop.
    function run()
        public
        returns (RiscZeroVerifierEmergencyStop emergencyStop, RiscZeroGroth16Verifier groth16Verifier)
    {
        vm.startBroadcast(Parameters.DEPLOYMENT_WALLET);

        groth16Verifier = new RiscZeroGroth16Verifier(ControlID.CONTROL_ROOT, ControlID.BN254_CONTROL_ID);

        emergencyStop =
            new RiscZeroVerifierEmergencyStop({_verifier: groth16Verifier, guardian: Parameters.PA_MULTISIG});

        vm.stopBroadcast();
    }
}
