// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {RiscZeroGroth16Verifier} from "risc0-risc0-ethereum-3.1.0/contracts/src/groth16/RiscZeroGroth16Verifier.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierEmergencyStop.sol";

import {DeployRiscZeroVerifier} from "../script/DeployRiscZeroVerifier.s.sol";
import {Parameters} from "../script/Parameters.sol";

contract DeployRiscZeroVerifierTest is Test {
    function test_DeployRiscZeroVerifier_puts_the_groth16_verifier_behind_an_emergency_stop_of_the_pa_safe() public {
        assertNotEq(block.chainid, Parameters.BSC_TESTNET_CHAIN_ID, "The test chain is not BSC testnet");

        (RiscZeroVerifierEmergencyStop emergencyStop, RiscZeroGroth16Verifier groth16Verifier) =
            new DeployRiscZeroVerifier().run();

        assertEq(address(emergencyStop.verifier()), address(groth16Verifier));
        assertEq(emergencyStop.owner(), Parameters.PA_MULTISIG);
    }

    function test_DeployRiscZeroVerifier_makes_the_deployment_wallet_the_guardian_on_bsc_testnet() public {
        vm.chainId(Parameters.BSC_TESTNET_CHAIN_ID);

        (RiscZeroVerifierEmergencyStop emergencyStop,) = new DeployRiscZeroVerifier().run();

        assertEq(emergencyStop.owner(), Parameters.DEPLOYMENT_WALLET);
    }

    function test_DeployRiscZeroVerifier_deploys_from_the_deployment_wallet() public {
        uint64 nonce = vm.getNonce(Parameters.DEPLOYMENT_WALLET);

        (RiscZeroVerifierEmergencyStop emergencyStop, RiscZeroGroth16Verifier groth16Verifier) =
            new DeployRiscZeroVerifier().run();

        assertEq(address(groth16Verifier), vm.computeCreateAddress(Parameters.DEPLOYMENT_WALLET, nonce));
        assertEq(address(emergencyStop), vm.computeCreateAddress(Parameters.DEPLOYMENT_WALLET, nonce + 1));
    }
}
