// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {RiscZeroVerifierRouter} from "risc0-risc0-ethereum-3.1.0/contracts/src/RiscZeroVerifierRouter.sol";
import {TestReceipt} from "risc0-risc0-ethereum-3.1.0/contracts/test/TestReceiptV3_1.sol";

import {Parameters} from "../script/Parameters.sol";
import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";
import {SupportedNetworks} from "../src/SupportedNetworks.sol";

// The node of each network runs the calls, because forge cannot fork Monad and the other networks in one run.
contract SupportedNetworksTest is SupportedNetworks, Test {
    struct AnomaNetwork {
        string name;
        address guardian;
    }

    constructor() SupportedNetworks() {}

    function tableRiscZeroNetworksTest_SupportedNetworks_the_router_verifies_the_groth16_test_receipt(string memory riscZeroNetwork)
        public
    {
        assertFalse(_riscZeroVerifierRouters[riscZeroNetwork].isAnomaDeployed, "RISC Zero deployed the router");
        _verifyTheTestReceipt({network: riscZeroNetwork});
    }

    function tableAnomaNetworksTest_SupportedNetworks_the_router_verifies_the_groth16_test_receipt(AnomaNetwork memory anomaNetwork)
        public
    {
        assertTrue(_riscZeroVerifierRouters[anomaNetwork.name].isAnomaDeployed, "Anoma deployed the router");
        _verifyTheTestReceipt({network: anomaNetwork.name});
    }

    function tableAnomaNetworksTest_SupportedNetworks_the_guardian_owns_the_emergency_stop_of_the_groth16_verifier(AnomaNetwork memory anomaNetwork)
        public
    {
        address emergencyStop = abi.decode(
            _call({
                network: anomaNetwork.name,
                target: _router({network: anomaNetwork.name}),
                // `getVerifier` has two overloads, so `abi.encodeCall` cannot name it.
                data: abi.encodeWithSignature(
                    "getVerifier(bytes4)", RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR
                )
            }),
            (address)
        );
        address guardian = abi.decode(
            _call({network: anomaNetwork.name, target: emergencyStop, data: abi.encodeCall(Ownable.owner, ())}),
            (address)
        );
        assertEq(guardian, anomaNetwork.guardian, "The guardian of the network owns the emergency stop");
    }

    function fixtureRiscZeroNetwork() public pure returns (string[] memory riscZeroNetwork) {
        riscZeroNetwork = new string[](8);
        riscZeroNetwork[0] = "sepolia";
        riscZeroNetwork[1] = "mainnet";
        riscZeroNetwork[2] = "arbitrum-sepolia";
        riscZeroNetwork[3] = "arbitrum";
        riscZeroNetwork[4] = "base-sepolia";
        riscZeroNetwork[5] = "base";
        riscZeroNetwork[6] = "optimism-sepolia";
        riscZeroNetwork[7] = "optimism";
    }

    function fixtureAnomaNetwork() public pure returns (AnomaNetwork[] memory anomaNetwork) {
        anomaNetwork = new AnomaNetwork[](8);
        anomaNetwork[0] = AnomaNetwork({name: "bsc-testnet", guardian: Parameters.BSC_TESTNET_GUARDIAN});
        anomaNetwork[1] = AnomaNetwork({name: "bsc", guardian: Parameters.PA_MULTISIG});
        anomaNetwork[2] = AnomaNetwork({name: "tempo-moderato", guardian: Parameters.PA_MULTISIG});
        anomaNetwork[3] = AnomaNetwork({name: "tempo", guardian: Parameters.PA_MULTISIG});
        anomaNetwork[4] = AnomaNetwork({name: "monad-testnet", guardian: Parameters.PA_MULTISIG});
        anomaNetwork[5] = AnomaNetwork({name: "monad", guardian: Parameters.PA_MULTISIG});
        anomaNetwork[6] = AnomaNetwork({name: "stable-mainnet", guardian: Parameters.PA_MULTISIG});
        anomaNetwork[7] = AnomaNetwork({name: "megaeth", guardian: Parameters.PA_MULTISIG});
    }

    function _verifyTheTestReceipt(string memory network) internal {
        assertEq(
            bytes4(TestReceipt.SEAL),
            RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR,
            "The test receipt has the Groth16 selector"
        );
        _call({
            network: network,
            target: _router({network: network}),
            data: abi.encodeCall(
                RiscZeroVerifierRouter.verify, (TestReceipt.SEAL, TestReceipt.IMAGE_ID, sha256(TestReceipt.JOURNAL))
            )
        });
    }

    function _router(string memory network) internal returns (address router) {
        uint256 chainId = vm.parseUint(vm.toString(vm.rpc({urlOrAlias: network, method: "eth_chainId", params: "[]"})));
        assertEq(_supportedNetworks[chainId], network, "The RPC endpoint serves the chain of the network");
        router = address(_riscZeroVerifierRouters[network].router);
    }

    function _call(string memory network, address target, bytes memory data) internal returns (bytes memory result) {
        vm.serializeAddress({objectKey: "transaction", valueKey: "to", value: target});
        string memory transaction = vm.serializeBytes({objectKey: "transaction", valueKey: "data", value: data});
        result =
            vm.rpc({urlOrAlias: network, method: "eth_call", params: string.concat("[", transaction, ",\"latest\"]")});
    }
}
