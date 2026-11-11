// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierEmergencyStop.sol";
import {RiscZeroVerifierRouter} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierRouter.sol";
import {RiscZeroMockVerifier} from "risc0-risc0-ethereum-3.1.0/contracts/src/test/RiscZeroMockVerifier.sol";
import {SafeProxy} from "safe-smart-account-1.5.0/contracts/proxies/SafeProxy.sol";
import {SafeL2} from "safe-smart-account-1.5.0/contracts/SafeL2.sol";

import {DeployRiscZeroVerifier} from "../script/DeployRiscZeroVerifier.s.sol";
import {Parameters} from "../script/Parameters.sol";
import {ProposeAddVerifier} from "../script/ProposeAddVerifier.s.sol";
import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";

/// @notice Outside broadcast mode, the script simulates the PA Safe executing the call, so the router must end up with
/// the verifier.
contract ProposeAddVerifierTest is Test {
    ProposeAddVerifier internal _script;
    RiscZeroVerifierRouter internal _router;
    RiscZeroVerifierEmergencyStop internal _emergencyStop;

    function setUp() public {
        // Keeps the script on the simulation branch; the variable changes only for this forge process.
        // forge-lint: disable-next-line(unsafe-cheatcode)
        vm.setEnv("SAFE_BROADCAST", "false");
        // BSC, where the PA Safe owns the router.
        vm.chainId(56);

        _script = new ProposeAddVerifier();
        _deploySafeAt(Parameters.PA_MULTISIG);

        _router = _script.getRouterData().router;
        _deployRouterAt({target: address(_router), admin: Parameters.PA_MULTISIG});

        (_emergencyStop,) = new DeployRiscZeroVerifier().run();
    }

    function test_run_adds_the_verifier_to_the_router() public {
        _script.run({emergencyStop: _emergencyStop});

        assertEq(
            address(_router.getVerifier(RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR)), address(_emergencyStop)
        );
    }

    function test_run_reverts_if_the_simulated_call_fails() public {
        // The router rejects a selector that it has already, so the simulated execution fails.
        vm.prank(Parameters.PA_MULTISIG);
        _router.addVerifier({selector: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR, verifier: _emergencyStop});

        vm.expectRevert(ProposeAddVerifier.TransactionSimulationFailed.selector);
        _script.run({emergencyStop: _emergencyStop});
    }

    function test_check_reverts_if_anoma_did_not_deploy_the_router() public {
        // Sepolia, where RISC Zero deployed the router.
        vm.chainId(11155111);
        assertFalse(_script.getRouterData().isAnomaDeployed, "Anoma did not deploy the router on Sepolia");

        vm.expectRevert(abi.encodeWithSelector(ProposeAddVerifier.RouterNotAnomaDeployed.selector, block.chainid));
        _script.check({emergencyStop: _emergencyStop});
    }

    function test_check_reverts_if_the_pa_safe_does_not_own_the_router() public {
        address deployer = makeAddr("deployer");
        _deployRouterAt({target: address(_router), admin: deployer});

        vm.expectRevert(abi.encodeWithSelector(ProposeAddVerifier.RouterOwnerNotPaSafe.selector, deployer));
        _script.check({emergencyStop: _emergencyStop});
    }

    function test_check_reverts_if_the_pa_safe_is_not_the_guardian() public {
        address guardian = makeAddr("guardian");
        RiscZeroVerifierEmergencyStop emergencyStop =
            new RiscZeroVerifierEmergencyStop({_verifier: _emergencyStop.verifier(), guardian: guardian});

        vm.expectRevert(abi.encodeWithSelector(ProposeAddVerifier.GuardianNotPaSafe.selector, guardian));
        _script.check({emergencyStop: emergencyStop});
    }

    function test_check_reverts_if_the_verifier_has_another_selector() public {
        bytes4 expected = RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR;
        bytes4 selector = ~expected;
        RiscZeroVerifierEmergencyStop emergencyStop = new RiscZeroVerifierEmergencyStop({
            _verifier: new RiscZeroMockVerifier(selector), guardian: Parameters.PA_MULTISIG
        });

        vm.expectRevert(
            abi.encodeWithSelector(ProposeAddVerifier.VerifierSelectorMismatch.selector, expected, selector)
        );
        _script.check({emergencyStop: emergencyStop});
    }

    /// @notice Installs a Safe 1.5.0 with three of five owners, as the PA Safe has, at the target address.
    function _deploySafeAt(address target) internal {
        address[] memory owners = new address[](5);
        for (uint256 i = 0; i < owners.length; ++i) {
            owners[i] = makeAddr(string.concat("owner ", vm.toString(i)));
        }

        address safe = address(new SafeProxy(address(new SafeL2())));
        SafeL2(payable(safe))
            .setup({
                _owners: owners,
                _threshold: 3,
                to: address(0),
                data: "",
                fallbackHandler: address(0),
                paymentToken: address(0),
                payment: 0,
                paymentReceiver: payable(address(0))
            });

        vm.etch(target, safe.code);
        vm.copyStorage(safe, target);
    }

    /// @notice Installs a router of the admin at the target address.
    function _deployRouterAt(address target, address admin) internal {
        RiscZeroVerifierRouter router = new RiscZeroVerifierRouter({admin: admin});

        vm.etch(target, address(router).code);
        vm.copyStorage(address(router), target);
    }
}
