# Release Checklist

Releases of the packages contained in this monorepo follow the [SemVer convention](https://semver.org/spec/v2.0.0.html).

We distinguish between three release cases:

- Adding RISC Zero contract deployments of a **new** RISC Zero protocol version resulting in a new `vX.0.0` version.

- Adding new RISC Zero contract deployments of the **current** RISC Zero protocol version resulting in a new `vX.Y.0` version.

- Correcting an existing RISC Zero contract of the **current** RISC Zero protocol version resulting in a new `vX.Y.Z` version.

## Deploying RISC Zero contracts

### 1. Prerequisites

- [ ] Visit https://www.soliditylang.org/ and check that Solidity compiler version used in `contracts/foundry.toml` has no [known vulnerabilities](https://docs.soliditylang.org/en/latest/bugs.html).

- [ ] Install the dependencies with

  ```sh
  just contracts-deps
  ```

- [ ] Check that the dependencies are up-to-date and have no known vulnerabilities in the dependencies

- [ ] Check that the deployer wallet is funded and add it to `cast` with

  ```sh
  cast wallet import deployer --private-key <PRIVATE_KEY>
  ```

  or

  ```sh
  cast wallet import deployer --mnemonic <MNEMONICC>
  ```

- [ ] Check that the RISC Zero verifier router admin address is set up correctly and export it with

  ```sh
  export ADMIN=<ADDRESS>
  ```

- [ ] Check that the RISC Zero emergency stop guardian address is set up correctly and export it with

  ```sh
  export GUARDIAN=<ADDRESS>
  ```

- [ ] Set the Alchemy RPC provider by exporting

  ```sh
  export ALCHEMY_API_KEY=<KEY>
  ```

- [ ] Set the Etherscan key

  ```sh
  export ETHERSCAN_API_KEY=<KEY>
  ```

### 2. Build the Contracts

- [ ] Run `just contracts-build`

- [ ] Run the test suite with `just contracts-test`

### 3. Deploy and Verify the RISC Zero Contracts

For each chain, you want to deploy to, do the following:

- [ ] **Simulate** the deployment by running

  ```sh
  just contracts-simulate $ADMIN $GUARDIAN <CHAIN_NAME>
  ```

- [ ] After successful simulation, **deploy** the contract by running

  ```sh
  just contracts-deploy deployer $ADMIN $GUARDIAN <CHAIN_NAME>
  ```

- [ ] Export the addresses of the newly deployed RISC Zero contract

  ```sh
  export GROTH16=<GROTH16_VERIFIER_CONTRACT_ADDRESS>
  export ESTOP=<EMERGENCY_STOP_CONTRACT_ADDRESS>
  export ROUTER=<ROUTER_CONTRACT_ADDRESS>
  ```

- [ ] Verify the contract on
  - [ ] sourcify

    ```sh
    just contracts-verify-sourcify $GROTH16 $ESTOP $ROUTER <CHAIN>
    ```

  - [ ] Etherscan

    ```sh
    just contracts-verify-etherscan $GROTH16 $ESTOP $ROUTER <CHAIN>
    ```

  - [ ] custom explorers

    ```sh
        just contracts-verify-custom $GROTH16 $ESTOP $ROUTER <VERIFIER_URL> <CHAIN>
    ```

    and check that the verification worked (e.g., on https://sourcify.dev/#/lookup).

### 4. Ensure the Admin has Accepted the Ownership Transfer

- [ ] Accept the ownership of the RISC Zero verifier router as the `$ADMIN`

- [ ] Check afterwards the admin has been updated correctly in the RISC Zero verifier router contract.

### 5. Update the supported networks and create a GitHub Release

- [ ] Update [`./src/SupportedNetworks.sol`](./src/SupportedNetworks.sol).

- [ ] Merge a PR containing the work into main.

- [ ] Create new [GH release](https://github.com/anoma/pa-evm/releases).

### 6. Publish a new Soldeer package

- [ ] Publish the `anoma-risc0-deployments` package on https://soldeer.xyz/ with

  ```sh
  just contracts-publish <X.Y.Z> --dry-run
  ```

  where `<X.Y.Z>` is the `_PROTOCOL_ADAPTER_VERSION` number and check the resulting `.zip` file. If everything is correct, remove the `--dry-run` flag and publish the package.
