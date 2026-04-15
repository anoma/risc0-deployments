// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RiscZeroVerifierRouter} from "risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol";

/// @title SupportedNetworks
/// @author Anoma Foundation, 2025
/// @notice A contract to inherit from listing the networks with RISC Zero support.
/// @custom:security-contact security@anoma.foundation
contract SupportedNetworks {
    struct Data {
        RiscZeroVerifierRouter router;
        bool isAnomaDeployed;
    }

    /// @notice A mapping containing the supported chain IDs and network names.
    mapping(uint256 chainId => string networkName) internal _supportedNetworks;

    /// @notice A mapping from supported network names to RISC Zero verifier routers.
    mapping(string networkName => Data routerData) internal _riscZeroVerifierRouters;

    /// @notice Thrown when a network is not supported.
    /// @param chainId The chain ID of the unsupported network.
    error UnsupportedNetwork(uint256 chainId);

    /// @notice Initializes the supported networks and associated RISC Zero verifier router addresses
    /// (see https://dev.risczero.com/api/3.0/blockchain-integration/contracts/verifier).
    constructor() {
        _supportNetwork({
            name: "sepolia",
            chainId: 11155111,
            riscZeroVerifierRouter: 0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187,
            isAnomaDeployed: false
        });
        _supportNetwork({
            name: "mainnet",
            chainId: 1,
            riscZeroVerifierRouter: 0x8EaB2D97Dfce405A1692a21b3ff3A172d593D319,
            isAnomaDeployed: false
        });

        _supportNetwork({
            name: "arbitrum-sepolia",
            chainId: 421614,
            riscZeroVerifierRouter: 0x0b144E07A0826182B6b59788c34b32Bfa86Fb711,
            isAnomaDeployed: false
        });
        _supportNetwork({
            name: "arbitrum",
            chainId: 42161,
            riscZeroVerifierRouter: 0x0b144E07A0826182B6b59788c34b32Bfa86Fb711,
            isAnomaDeployed: false
        });

        _supportNetwork({
            name: "base-sepolia",
            chainId: 84532,
            riscZeroVerifierRouter: 0x0b144E07A0826182B6b59788c34b32Bfa86Fb711,
            isAnomaDeployed: false
        });
        _supportNetwork({
            name: "base",
            chainId: 8453,
            riscZeroVerifierRouter: 0x0b144E07A0826182B6b59788c34b32Bfa86Fb711,
            isAnomaDeployed: false
        });

        _supportNetwork({
            name: "optimism-sepolia",
            chainId: 11155420,
            riscZeroVerifierRouter: 0xB369b4dd27FBfb59921d3A4a3D23AC2fc32FB908,
            isAnomaDeployed: false
        });
        _supportNetwork({
            name: "optimism",
            chainId: 10,
            riscZeroVerifierRouter: 0x0b144E07A0826182B6b59788c34b32Bfa86Fb711,
            isAnomaDeployed: false
        });

        _supportNetwork({
            name: "bsc-testnet",
            chainId: 97,
            riscZeroVerifierRouter: 0x7C1B7b8fEB636eA9Ecd32152Bce2744a0EEf39C7,
            isAnomaDeployed: true
        });
        _supportNetwork({
            name: "bsc",
            chainId: 56,
            riscZeroVerifierRouter: 0x7C1B7b8fEB636eA9Ecd32152Bce2744a0EEf39C7,
            isAnomaDeployed: true
        });

        _supportNetwork({
            name: "tempo-moderato",
            chainId: 42431,
            riscZeroVerifierRouter: 0xCaE654028902b31B18e23D21407E17A3E2fd930c,
            isAnomaDeployed: true
        });
        _supportNetwork({
            name: "tempo",
            chainId: 4217,
            riscZeroVerifierRouter: 0xCaE654028902b31B18e23D21407E17A3E2fd930c,
            isAnomaDeployed: true
        });
    }

    // solhint-disable comprehensive-interface

    /// @notice Returns the router data for the current network.
    /// @return data The router data of the current network.
    function getRouterData() public view returns (Data memory data) {
        data = _riscZeroVerifierRouters[_supportedNetworks[block.chainid]];
        require(address(data.router) != address(0), UnsupportedNetwork({chainId: block.chainid}));
    }

    // solhint-enable comprehensive-interface

    /// @notice Stores the data for a network to be supported for deployment.
    /// @param name The network name.
    /// @param chainId The chain ID of the network.
    /// @param riscZeroVerifierRouter The RISC Zero verifier router address obtained from
    /// https://dev.risczero.com/api/3.0/blockchain-integration/contracts/verifier.
    /// @param isAnomaDeployed Whether the RISC Zero verifier was deployed by Anoma.
    /// @dev The network `name` must match the `[rpc_endpoints]` names in the `foundry.toml` file for the test in
    /// `DeployProtocolAdapter.t.sol` to succeed.
    function _supportNetwork(string memory name, uint256 chainId, address riscZeroVerifierRouter, bool isAnomaDeployed)
        internal
    {
        _supportedNetworks[chainId] = name;
        _riscZeroVerifierRouters[name] =
            Data({router: RiscZeroVerifierRouter(riscZeroVerifierRouter), isAnomaDeployed: isAnomaDeployed});
    }
}
