// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {Address} from "openzeppelin/contracts/utils/Address.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol";
import {RiscZeroVerifierRouter} from "risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol";
import {RiscZeroMockVerifier} from "risc0-risc0-ethereum-3.0.1/contracts/src/test/RiscZeroMockVerifier.sol";

import {DeployRiscZeroVerifier} from "../script/DeployRiscZeroVerifier.s.sol";
import {GenerateAddVerifierPayload} from "../script/GenerateAddVerifierPayload.s.sol";
import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";

contract GenerateAddVerifierPayloadTest is Test {
    GenerateAddVerifierPayload internal _script;
    address internal _paSafe;
    RiscZeroVerifierRouter internal _router;
    RiscZeroVerifierEmergencyStop internal _emergencyStop;

    function setUp() public {
        _script = new GenerateAddVerifierPayload();
        _paSafe = _script.PA_SAFE();
        _router = new RiscZeroVerifierRouter({admin: _paSafe});
        (_emergencyStop,) = new DeployRiscZeroVerifier().run({guardian: _paSafe});
    }

    function test_check_reverts_if_the_pa_safe_does_not_own_the_router() public {
        address deployer = makeAddr("deployer");
        RiscZeroVerifierRouter router = new RiscZeroVerifierRouter({admin: deployer});

        vm.expectRevert(abi.encodeWithSelector(GenerateAddVerifierPayload.RouterOwnerNotPaSafe.selector, deployer));
        _script.check({router: router, emergencyStop: _emergencyStop});
    }

    function test_check_reverts_if_the_pa_safe_is_not_the_guardian() public {
        address guardian = makeAddr("guardian");
        (RiscZeroVerifierEmergencyStop emergencyStop,) = new DeployRiscZeroVerifier().run({guardian: guardian});

        vm.expectRevert(abi.encodeWithSelector(GenerateAddVerifierPayload.GuardianNotPaSafe.selector, guardian));
        _script.check({router: _router, emergencyStop: emergencyStop});
    }

    function test_check_reverts_if_the_verifier_has_another_selector() public {
        bytes4 expected = RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR;
        bytes4 selector = ~expected;
        RiscZeroVerifierEmergencyStop emergencyStop =
            new RiscZeroVerifierEmergencyStop({_verifier: new RiscZeroMockVerifier(selector), guardian: _paSafe});

        vm.expectRevert(
            abi.encodeWithSelector(GenerateAddVerifierPayload.VerifierSelectorMismatch.selector, expected, selector)
        );
        _script.check({router: _router, emergencyStop: emergencyStop});
    }

    function test_batchFile_adds_the_verifier_when_the_pa_safe_submits_its_transaction() public {
        bytes4 selector = RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR;
        string memory json = _script.batchFile({
            chainId: block.chainid, router: _router, selector: selector, emergencyStop: _emergencyStop
        });
        address to = vm.parseJsonAddress(json, ".transactions[0].to");
        uint256 value = vm.parseUint(vm.parseJsonString(json, ".transactions[0].value"));
        bytes memory data = vm.parseJsonBytes(json, ".transactions[0].data");

        vm.prank(_paSafe);
        Address.functionCallWithValue({target: to, data: data, value: value});

        assertEq(address(_router.getVerifier(selector)), address(_emergencyStop));
    }

    function test_check_accepts_a_verifier_that_DeployRiscZeroVerifier_deploys_for_the_pa_safe() public view {
        _script.check({router: _router, emergencyStop: _emergencyStop});
    }

    function test_batchFile_has_the_checksum_that_the_transaction_builder_computes() public view {
        string memory json = _script.batchFile({
            chainId: 56,
            router: RiscZeroVerifierRouter(0x7C1B7b8fEB636eA9Ecd32152Bce2744a0EEf39C7),
            selector: 0x73c457ba,
            emergencyStop: RiscZeroVerifierEmergencyStop(0xBbcD45801a3c3B858fbc66674FE7c9f94e33dC72)
        });

        // The checksum that `apps/tx-builder/src/lib/checksum.ts` of the Safe Transaction Builder computes.
        assertEq(
            vm.parseJsonString(json, ".meta.checksum"),
            "0xa990a298b922850485e35488beea8cc43580aaa3c00bb8223d026444017d3342"
        );
    }

    function test_batchFile_names_the_chain_and_the_pa_safe() public view {
        string memory json = _script.batchFile({
            chainId: 56,
            router: _router,
            selector: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR,
            emergencyStop: _emergencyStop
        });

        assertEq(vm.parseJsonString(json, ".chainId"), "56");
        assertEq(vm.parseJsonAddress(json, ".meta.createdFromSafeAddress"), _paSafe);
    }
}
