// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std-1.17.0/src/Script.sol";
import {IRiscZeroSelectable} from "risc0-risc0-ethereum-3.1.0/contracts/src/IRiscZeroSelectable.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierEmergencyStop.sol";
import {RiscZeroVerifierRouter} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierRouter.sol";
import {IOwnerManager} from "safe-smart-account-1.5.0/contracts/interfaces/IOwnerManager.sol";
import {Safe} from "safe-utils-0.0.24/src/Safe.sol";

import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";
import {SupportedNetworks} from "../src/SupportedNetworks.sol";
import {Parameters} from "./Parameters.sol";

/// @notice Checks the emergency stop of a Groth16 verifier and proposes to the PA Safe the `addVerifier` call that adds
/// it to the router of the current chain. The signers of the PA Safe confirm and execute the call in the Safe app.
contract ProposeAddVerifier is Script, SupportedNetworks {
    using Safe for *;

    /// @notice The client of the Safe Transaction Service for the PA Safe.
    Safe.Client internal _safe;

    /// @notice Thrown if Anoma did not deploy the router of the current chain.
    /// @param chainId The chain ID of the current chain.
    error RouterNotAnomaDeployed(uint256 chainId);

    /// @notice Thrown if the PA Safe does not own the router.
    /// @param routerOwner The owner of the router.
    error RouterOwnerNotPaSafe(address routerOwner);

    /// @notice Thrown if the PA Safe is not the guardian of the emergency stop.
    /// @param guardian The guardian of the emergency stop.
    error GuardianNotPaSafe(address guardian);

    /// @notice Thrown if the verifier behind the emergency stop does not have the Groth16 selector of
    /// `RiscZeroVerifierSelectors`.
    /// @param expected The Groth16 selector of `RiscZeroVerifierSelectors`.
    /// @param actual The selector of the verifier.
    error VerifierSelectorMismatch(bytes4 expected, bytes4 actual);

    /// @notice Thrown if the simulated execution of the call by the PA Safe fails.
    error TransactionSimulationFailed();

    /// @notice Checks the emergency stop and proposes its `addVerifier` call from the deployment wallet to the PA Safe
    /// through the Safe Transaction Service, at the current nonce of the PA Safe.
    /// @param emergencyStop The emergency stop of the Groth16 verifier to add.
    /// @dev Without `--broadcast`, the script simulates the execution of the call by the PA Safe instead.
    function run(RiscZeroVerifierEmergencyStop emergencyStop) public {
        RiscZeroVerifierRouter router = check({emergencyStop: emergencyStop});

        bytes memory callData = abi.encodeCall(
            RiscZeroVerifierRouter.addVerifier, (RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR, emergencyStop)
        );

        _safe.initialize(Parameters.PA_SAFE);

        if (Safe.isBroadcastMode()) {
            _safe.proposeTransaction(address(router), callData, Parameters.DEPLOYMENT_WALLET);
        } else {
            require(
                _safe.simulateTransactionMultiSigNoSign(
                    address(router), callData, IOwnerManager(Parameters.PA_SAFE).getOwners()
                ),
                TransactionSimulationFailed()
            );
        }
    }

    /// @notice Reverts unless Anoma deployed the router of the current chain, the PA Safe owns this router and guards the
    /// emergency stop, and the verifier behind the emergency stop has the Groth16 selector of `RiscZeroVerifierSelectors`.
    /// @param emergencyStop The emergency stop of the verifier.
    /// @return router The router of the current chain, from `SupportedNetworks`.
    function check(RiscZeroVerifierEmergencyStop emergencyStop) public view returns (RiscZeroVerifierRouter router) {
        Data memory routerData = getRouterData();
        require(routerData.isAnomaDeployed, RouterNotAnomaDeployed({chainId: block.chainid}));
        router = routerData.router;

        address routerOwner = router.owner();
        require(routerOwner == Parameters.PA_SAFE, RouterOwnerNotPaSafe(routerOwner));

        address guardian = emergencyStop.owner();
        require(guardian == Parameters.PA_SAFE, GuardianNotPaSafe(guardian));

        bytes4 selector = IRiscZeroSelectable(address(emergencyStop.verifier())).SELECTOR();
        require(
            selector == RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR,
            VerifierSelectorMismatch({expected: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR, actual: selector})
        );
    }
}
