// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std-1.17.0/src/Script.sol";
import {IRiscZeroSelectable} from "risc0-risc0-ethereum-3.0.1/contracts/src/IRiscZeroSelectable.sol";
import {
    RiscZeroVerifierEmergencyStop
} from "risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol";
import {RiscZeroVerifierRouter} from "risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol";

import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";
import {SupportedNetworks} from "../src/SupportedNetworks.sol";

/// @notice Checks the emergency stop of a Groth16 verifier and writes the `addVerifier` call that adds it to the router
/// of the current chain as a batch file of the Safe Transaction Builder. A signer of the PA Safe imports the file into
/// the Transaction Builder.
contract GenerateAddVerifierPayload is Script, SupportedNetworks {
    /// @notice The Safe of the protocol adapters, which must own the router and guard the emergency stop.
    address public constant PA_SAFE = 0xE9082Ac8Aa2Fb27DEfDBAC604921C196b884Da10;

    /// @notice The batch file, in the layout that the Transaction Builder exports.
    /// @dev `createdAt` is fixed, so that the same call always gives the same file.
    string internal constant _BATCH_FILE = "{\n" "  \"version\": \"1.0\",\n" "  \"chainId\": \"<chainId>\",\n"
        "  \"createdAt\": 0,\n" "  \"meta\": {\n" "    \"name\": \"Add a RISC Zero verifier\",\n"
        "    \"description\": \"<description>\",\n" "    \"txBuilderVersion\": \"2.1.0\",\n"
        "    \"createdFromSafeAddress\": \"<safe>\",\n" "    \"createdFromOwnerAddress\": \"\",\n"
        "    \"checksum\": \"<checksum>\"\n" "  },\n" "  \"transactions\": [\n" "    {\n" "      \"to\": \"<to>\",\n"
        "      \"value\": \"0\",\n" "      \"data\": \"<data>\",\n" "      \"contractMethod\": null,\n"
        "      \"contractInputsValues\": null\n" "    }\n" "  ]\n" "}\n";

    /// @notice The text of `_BATCH_FILE` that the Transaction Builder hashes into `meta.checksum`.
    /// @dev The serialization of `checksum.ts` in the Safe Transaction Builder: it sorts the keys, sets `meta.name` to
    /// null, and leaves out `meta.checksum`.
    string internal constant _CHECKSUM_INPUT = "{[\"chainId\",\"createdAt\",\"meta\",\"transactions\",\"version\"]"
        "\"<chainId>\",0,"
        "{[\"createdFromOwnerAddress\",\"createdFromSafeAddress\",\"description\",\"name\",\"txBuilderVersion\"]"
        "\"\",\"<safe>\",\"<description>\",null,\"2.1.0\",},"
        "[{[\"contractInputsValues\",\"contractMethod\",\"data\",\"to\",\"value\"]null,null,\"<data>\",\"<to>\",\"0\",}],"
        "\"1.0\",}";

    /// @notice The description of the batch, which contains no character that JSON escapes.
    string internal constant _DESCRIPTION =
        "Calls addVerifier on the RISC Zero verifier router. Selector: <selector>. Emergency stop: <emergencyStop>.";

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

    /// @notice Checks the emergency stop and writes its batch file for the router of the current chain to
    /// `safe-payloads/addVerifier_to_riscZeroVerifierRouter_<network>.json`.
    /// @param emergencyStop The emergency stop of the Groth16 verifier to add.
    function run(RiscZeroVerifierEmergencyStop emergencyStop) public {
        RiscZeroVerifierRouter router = getRouterData().router;
        check({router: router, emergencyStop: emergencyStop});

        string memory path = string.concat(
            "safe-payloads/addVerifier_to_riscZeroVerifierRouter_", _supportedNetworks[block.chainid], ".json"
        );
        vm.createDir({path: "safe-payloads", recursive: true});
        // NOTE: The `fs_permissions` of `foundry.toml` allow writes only to `safe-payloads/`.
        // forge-lint: disable-next-line(unsafe-cheatcode)
        vm.writeFile({
            path: path,
            data: batchFile({
                chainId: block.chainid,
                router: router,
                selector: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR,
                emergencyStop: emergencyStop
            })
        });
    }

    /// @notice Reverts unless the PA Safe owns the router and guards the emergency stop, and the verifier behind the
    /// emergency stop has the Groth16 selector of `RiscZeroVerifierSelectors`.
    /// @param router The router to add the verifier to.
    /// @param emergencyStop The emergency stop of the verifier.
    function check(RiscZeroVerifierRouter router, RiscZeroVerifierEmergencyStop emergencyStop) public view {
        address routerOwner = router.owner();
        require(routerOwner == PA_SAFE, RouterOwnerNotPaSafe(routerOwner));

        address guardian = emergencyStop.owner();
        require(guardian == PA_SAFE, GuardianNotPaSafe(guardian));

        bytes4 selector = IRiscZeroSelectable(address(emergencyStop.verifier())).SELECTOR();
        require(
            selector == RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR,
            VerifierSelectorMismatch({expected: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR, actual: selector})
        );
    }

    /// @notice Returns the Transaction Builder batch file that adds a verifier to a router.
    /// @param chainId The chain of the router.
    /// @param router The router to add the verifier to.
    /// @param selector The selector under which the router adds the verifier.
    /// @param emergencyStop The emergency stop of the verifier.
    /// @return json The batch file, with the checksum that the Transaction Builder checks on import.
    function batchFile(
        uint256 chainId,
        RiscZeroVerifierRouter router,
        bytes4 selector,
        RiscZeroVerifierEmergencyStop emergencyStop
    ) public pure returns (string memory json) {
        string memory description = vm.replace(_DESCRIPTION, "<selector>", vm.toString(abi.encodePacked(selector)));
        description = vm.replace(description, "<emergencyStop>", vm.toString(address(emergencyStop)));
        bytes memory data = abi.encodeCall(RiscZeroVerifierRouter.addVerifier, (selector, emergencyStop));

        string memory checksumInput =
            _fill({template: _CHECKSUM_INPUT, chainId: chainId, router: router, description: description, data: data});
        json = _fill({template: _BATCH_FILE, chainId: chainId, router: router, description: description, data: data});
        json = vm.replace(json, "<checksum>", vm.toString(keccak256(bytes(checksumInput))));
    }

    /// @notice Fills the placeholders that `_BATCH_FILE` and `_CHECKSUM_INPUT` share.
    /// @param template `_BATCH_FILE` or `_CHECKSUM_INPUT`.
    /// @param chainId The chain of the router.
    /// @param router The router to add the verifier to.
    /// @param description The description of the batch.
    /// @param data The `addVerifier` call.
    /// @return filled The template with the values of the batch.
    function _fill(
        string memory template,
        uint256 chainId,
        RiscZeroVerifierRouter router,
        string memory description,
        bytes memory data
    ) internal pure returns (string memory filled) {
        filled = vm.replace(template, "<chainId>", vm.toString(chainId));
        filled = vm.replace(filled, "<safe>", vm.toString(PA_SAFE));
        filled = vm.replace(filled, "<description>", description);
        filled = vm.replace(filled, "<to>", vm.toString(address(router)));
        filled = vm.replace(filled, "<data>", vm.toString(data));
    }
}
