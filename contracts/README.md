[![Contracts Tests](https://github.com/anoma/risc0-deployments/actions/workflows/contracts.yml/badge.svg)](https://github.com/anoma/risc0-deployments/actions/workflows/contracts.yml) [![soldeer.xyz](https://img.shields.io/badge/soldeer.xyz-anoma--risc0--deployments-blue?logo=ethereum)](https://soldeer.xyz/project/anoma-risc0-deployments) [![License](https://img.shields.io/badge/license-MIT-blue)](https://raw.githubusercontent.com/anoma/risc0-deployments/refs/heads/main/LICENSE)

# RISC0 Deployments Contracts

Deploy scripts and supporting [Solidity](https://soliditylang.org/) sources making the [RISC Zero](https://risczero.com/) verifier contracts available as a soldeer package. The verifier, mock verifier, router, and emergency-stop contracts themselves come from the [`risc0-ethereum`](https://github.com/risc0/risc0-ethereum) soldeer dependency.

## Prerequisites

1. Get an up-to-date version of [Foundry](https://github.com/foundry-rs/foundry) with

   ```sh
   curl -L https://foundry.paradigm.xyz | sh
   foundryup
   ```

2. Optionally, to lint the contracts, install [solhint](https://github.com/protofire/solhint) using a JS package manager such as [Bun](https://bun.com/) with

   ```sh
   curl -fsSL https://bun.sh/install | sh
   bun install
   ```

3. Optionally, for static analysis, install [Slither](https://github.com/crytic/slither) with

   ```sh
   python3 -m pip install slither-analyzer
   ```

   or brew

   ```sh
   brew install slither-analyzer
   ```

## Usage

#### Installation

Change the directory to the `contracts` folder with `cd contracts` and run

```sh
forge soldeer install
```

#### Build

To compile the contracts, run

```sh
forge build
```

#### Tests & Coverage

To run the tests, run

```sh
forge test
```

To show the coverage report, run

```sh
forge coverage
```

Append the

- `--no-match-coverage "(script|test)"` to exclude scripts and tests,
- `--report lcov` to generate the `lcov.info` file that can be used by code review tooling.

#### Linting & Static Analysis

As a prerequisite, install the

- `solhint` linter (see https://github.com/protofire/solhint)
- `slither` static analyzer (see https://github.com/crytic/slither)

To run the linter and static analyzer, run

```sh
bunx solhint --config .solhint.json 'src/**/*.sol' && \
bunx solhint --config .solhint.other.json 'script/**/*.sol' 'test/**/*.sol' && \
slither .
```

#### Rust Bindings

To regenerate the Rust bindings (see the [forge bind](https://getfoundry.sh/forge/reference/bind/) documentation), run

```sh
forge bind \
  --select '^(RiscZeroGroth16Verifier|RiscZeroMockVerifier|RiscZeroVerifierEmergencyStop|RiscZeroVerifierRouter)$' \
  --bindings-path ../bindings/src/generated/ \
  --module \
  --overwrite
```

#### Documentation

Run

```sh
forge doc
```

#### Deployment

To simulate the deployment of the RISC Zero verifier router, Groth16 verifier, and emergency-stop wrapper on sepolia, run

```sh
forge script script/DeployRiscZeroContracts.s.sol:DeployRiscZeroContracts \
  --sig "run(address,address)" <ADMIN> <GUARDIAN> \
  --rpc-url sepolia
```

Append the

- `--broadcast` flag to deploy to the network
- `--verify` flag for subsequent contract verification (Sourcify by default; set `ETHERSCAN_API_KEY` to also verify on Etherscan)
- `--slow` flag to add 15 seconds of waiting time between verification attempts
- `--account <ACCOUNT_NAME>` flag to use a previously imported keystore (see `cast wallet --help` for more info)

#### Block Explorer Verification

The verifier contracts live in the `risc0-ethereum` dependency, so verification references their source paths. For post-deployment verification of the Groth16 verifier on **Sourcify** run

```sh
forge verify-contract \
   <ADDRESS> \
   dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
   --chain sepolia \
   --verifier sourcify
```

For **Etherscan** (requires `ETHERSCAN_API_KEY`) run

```sh
forge verify-contract \
   <ADDRESS> \
   dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
   --chain sepolia \
   --verifier etherscan
```

Repeat for the `RiscZeroVerifierEmergencyStop` and `RiscZeroVerifierRouter` contracts (see the [Release Checklist](../RELEASE_CHECKLIST.md) for the full set of commands).
