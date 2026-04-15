// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std-1.15.0/src/Test.sol";

import {Pausable} from "openzeppelin/contracts/utils/Pausable.sol";

import {RiscZeroVerifierSelectors} from "../src/RiscZeroVerifierSelectors.sol";
import {SupportedNetworks} from "../src/SupportedNetworks.sol";

contract SupportedNetworksTest is SupportedNetworks, Test {
    struct TestCase {
        string name;
    }

    constructor() SupportedNetworks() {}

    // forge-lint: disable-next-line(mixed-case-function)
    function tableNetworksTest_SupportedNetworks_the_risc_zero_router_routes_to_the_groth16_verifier(TestCase memory network)
        public
    {
        uint256 chainId = vm.createFork(network.name);
        vm.selectFork(chainId);

        getRouterData().router.getVerifier({selector: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR});
    }

    // forge-lint: disable-next-line(mixed-case-function)
    function tableNetworksTest_SupportedNetworks_the_groth16_verifier_is_not_stopped(TestCase memory network) public {
        uint256 chainId = vm.createFork(network.name);
        vm.selectFork(chainId);

        assertFalse(
            Pausable(
                    address(
                        getRouterData().router
                            .getVerifier({selector: RiscZeroVerifierSelectors._GROTH16_VERIFIER_SELECTOR})
                    )
                ).paused(),
            "The verfier has been stopped."
        );
    }

    function fixtureNetwork() public pure returns (TestCase[] memory network) {
        network = new TestCase[](10);
        network[0] = TestCase({name: "sepolia"});
        network[1] = TestCase({name: "mainnet"});

        network[2] = TestCase({name: "arbitrum-sepolia"});
        network[3] = TestCase({name: "arbitrum"});

        network[4] = TestCase({name: "base-sepolia"});
        network[5] = TestCase({name: "base"});

        network[6] = TestCase({name: "optimism-sepolia"});
        network[7] = TestCase({name: "optimism"});

        network[8] = TestCase({name: "bsc-testnet"});
        network[9] = TestCase({name: "bsc"});

        return network;
    }
}
