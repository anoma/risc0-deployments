[![Contracts Tests](https://github.com/anoma/risc0-deployments/actions/workflows/contracts.yml/badge.svg)](https://github.com/anoma/risc0-deployments/actions/workflows/contracts.yml) [![soldeer.xyz](https://img.shields.io/badge/soldeer.xyz-anoma--risc0--deployments-blue?logo=ethereum)](https://soldeer.xyz/project/anoma-risc0-deployments) [![License](https://img.shields.io/badge/license-MIT-blue)](https://raw.githubusercontent.com/anoma/risc0-deployments/refs/heads/main/LICENSE)

[![Bindings Tests](https://github.com/anoma/risc0-deployments/actions/workflows/bindings.yml/badge.svg)](https://github.com/anoma/risc0-deployments/actions/workflows/bindings.yml) [![crates.io](https://img.shields.io/badge/crates.io-anoma--risc0--deployments--bindings-blue?logo=rust)](https://crates.io/crates/anoma-risc0-deployments-bindings) [![License](https://img.shields.io/badge/license-MIT-blue)](https://raw.githubusercontent.com/anoma/risc0-deployments/refs/heads/main/LICENSE)

# RISC0 Deployments

This repo makes the [RISC Zero](https://risczero.com/) verifier deployments available as a [soldeer](https://soldeer.xyz/) package and as Rust bindings, for use with the [Anoma EVM protocol adapter](https://github.com/anoma/pa-evm).

## Project Structure

This monorepo is structured as follows:

```
.
├── bindings
├── contracts
├── justfile
├── README.md
└── RELEASE_CHECKLIST.md
```

The [contracts](./contracts/) folder contains the deploy scripts and supporting [Solidity](https://soliditylang.org/) sources as well as the [Foundry forge](https://book.getfoundry.sh/forge/) tests. The RISC Zero verifier, mock verifier, router, and emergency-stop contracts come from the [`risc0-ethereum`](https://github.com/risc0/risc0-ethereum) soldeer dependency. This folder is published as the `anoma-risc0-deployments` soldeer package; see its [README](./contracts/README.md) for the low-level `forge` commands.

The [bindings](./bindings/) folder provides [Rust](https://www.rust-lang.org/) bindings for the RISC Zero verifier contracts (`RiscZeroGroth16Verifier`, `RiscZeroMockVerifier`, `RiscZeroVerifierEmergencyStop`, and `RiscZeroVerifierRouter`) using the [alloy-rs](https://github.com/alloy-rs) library, published as the `anoma-risc0-deployments-bindings` crate. They are consumed by the Anoma protocol-adapter integration tests to deploy a mock verifier stack against a local chain.

The repository-level [`justfile`](./justfile) bundles the contract and bindings recipes (run `just` to list them); the [Release Checklist](./RELEASE_CHECKLIST.md) documents the deployment and publishing flows.

## Security

If you believe you've found a security issue, we encourage you to notify us via Email
at [security@anoma.foundation](mailto:security@anoma.foundation).

Please do not use the issue tracker for security issues. We welcome working with you to resolve the issue promptly.
