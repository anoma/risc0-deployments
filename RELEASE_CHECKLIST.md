# Release Checklist

Releases of the packages contained in this monorepo follow the [SemVer convention](https://semver.org/spec/v2.0.0.html).

> ![NOTE]
> The `contracts` (soldeer) and `bindings` (crates.io) packages are independently versioned with `X.Y.Z` and `A.B.C`, respectively.

We distinguish between the following release cases for the **contracts** package:

- Adding RISC Zero contract deployments of a **new** RISC Zero protocol version resulting in a new `vX.0.0` version.

- Adding new RISC Zero contract deployments of the **current** RISC Zero protocol version resulting in a new `vX.Y.0` version.

- Correcting an existing RISC Zero contract of the **current** RISC Zero protocol version resulting in a new `vX.Y.Z` version.

and for the **bindings** package:

- Changing the bound contracts or supported networks resulting in a new `vA.0.0` version.

- Maintaining the bindings (dependency bumps, fixes) resulting in a new `vA.B.C` version.

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

- [ ] Run the test suite with `just contracts-test`. The tests fork every supported network to check its router and Groth16 verifier, so CI does not run them.

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

- [ ] Right after the deployment, verify the three contracts on Sourcify and Etherscan. Etherscan copies a verification to each contract with the same code, and its API cannot replace a copied entry.

  ```sh
  just contracts-verify-deployment $GROTH16 $ESTOP $ROUTER <CHAIN_NAME>
  ```

  On a chain that Etherscan does not serve, such as Tempo, verify each contract on Sourcify alone, for example the Groth16 verifier with

  ```sh
  just contracts-verify-sourcify $GROTH16 "$(just --evaluate groth16_verifier_contract)" <CHAIN_NAME>
  ```

  and the other two with `emergency_stop_contract` and `router_contract`. `just contracts-verify-custom <ADDRESS> <CONTRACT> <CHAIN_NAME> <VERIFIER_URL>` verifies a contract on another explorer.

  With the free Etherscan key, Etherscan refuses to look up the creation transaction on some chains, such as BSC. There, give the constructor arguments as hex without `0x`, for example for the emergency stop:

  ```sh
  just contracts-verify-etherscan $ESTOP "$(just --evaluate emergency_stop_contract)" <CHAIN_NAME> --constructor-args $(cast abi-encode "constructor(address,address)" $GROTH16 $GUARDIAN | cut -c3-)
  ```

- [ ] Check the verification on https://sourcify.dev/#/lookup and on the explorer of the chain.

### 4. Ensure the Admin has Accepted the Ownership Transfer

- [ ] Accept the ownership of the RISC Zero verifier router as the `$ADMIN`

- [ ] Check afterwards the admin has been updated correctly in the RISC Zero verifier router contract.

### 5. Update the supported networks and create a GitHub Release

- [ ] Update [`./contracts/src/SupportedNetworks.sol`](./contracts/src/SupportedNetworks.sol).

- [ ] Merge a PR containing the work into main.

- [ ] Create new [GH release](https://github.com/anoma/risc0-deployments/releases).

### 6. Publish a new Soldeer package

- [ ] Publish the `anoma-risc0-deployments` package on https://soldeer.xyz/ with

  ```sh
  just contracts-publish <X.Y.Z> --dry-run
  ```

  and check the resulting `.zip` file. If everything is correct, remove the `--dry-run` flag and publish the package.

## Adding a Verifier to a Router

When `risc0-ethereum` releases a Groth16 verifier with a new selector, add it to each router that [`SupportedNetworks.sol`](./contracts/src/SupportedNetworks.sol) marks with `isAnomaDeployed`. RISC Zero adds it to its own routers.

The PA Safe `0xE9082Ac8Aa2Fb27DEfDBAC604921C196b884Da10` owns these routers and guards their emergency stops.

### 1. Prerequisites

- [ ] Move to the new `risc0-ethereum` version in `contracts/foundry.toml`, and set the new selector in [`RiscZeroVerifierSelectors.sol`](./contracts/src/RiscZeroVerifierSelectors.sol). `just contracts-test` checks that the selector matches the verifier.

- [ ] Do the steps of the [prerequisites](#1-prerequisites) for a deployment, except for `ADMIN` and `GUARDIAN`. Import the deployment wallet of [`Parameters.sol`](./contracts/script/Parameters.sol) as `deployer`: the deploy script deploys from it and makes the PA Safe the guardian.

### 2. Deploy and Verify the Verifier

For each chain, do the following:

- [ ] Export the router of the chain from `SupportedNetworks.sol`

  ```sh
  export ROUTER=<ROUTER_CONTRACT_ADDRESS>
  ```

- [ ] **Simulate** the deployment by running

  ```sh
  just contracts-simulate-verifier <CHAIN_NAME>
  ```

- [ ] After a successful simulation, **deploy** the verifier and its emergency stop by running

  ```sh
  just contracts-deploy-verifier deployer <CHAIN_NAME>
  ```

  If `deployer` is not the deployment wallet, forge stops before it sends a transaction.

- [ ] Export the addresses of the new contracts

  ```sh
  export GROTH16=<GROTH16_VERIFIER_CONTRACT_ADDRESS>
  export ESTOP=<EMERGENCY_STOP_CONTRACT_ADDRESS>
  ```

- [ ] Right after the deployment, verify both contracts on Sourcify and Etherscan. The router exists already, so this step does not verify it.

  ```sh
  just contracts-verify-verifier $GROTH16 $ESTOP <CHAIN_NAME>
  ```

  On a chain that Etherscan does not serve, verify each contract on Sourcify alone, as in [Deploy and Verify the RISC Zero Contracts](#3-deploy-and-verify-the-risc-zero-contracts).

### 3. Add the Verifier to the Router

- [ ] **Simulate** the proposal by running

  ```sh
  just contracts-simulate-add-verifier-proposal $ESTOP <CHAIN_NAME>
  ```

  The script reads the router of the chain from `SupportedNetworks.sol`. It checks that Anoma deployed the router (`isAnomaDeployed`), that the PA Safe owns the router and guards `$ESTOP`, and that the verifier behind `$ESTOP` has the selector of `RiscZeroVerifierSelectors.sol`. Then it simulates the PA Safe executing the `addVerifier(<SELECTOR>, $ESTOP)` call at its current nonce, and prints this nonce.

- [ ] Check in the Safe app that no queued transaction of the PA Safe on the chain has this nonce. The script proposes at the current nonce, so a queued transaction with this nonce conflicts with the proposal, and the signers can execute only one of them.

- [ ] After a successful simulation, **propose** the call to the PA Safe by running

  ```sh
  just contracts-propose-add-verifier deployer $ESTOP <CHAIN_NAME>
  ```

  `deployer` must be the account of the deployment wallet in [`Parameters.sol`](./contracts/script/Parameters.sol), which proposes the call. The signers of the PA Safe then confirm and execute the transaction in the Safe app.

- [ ] Check that the router returns the new emergency stop

  ```sh
  cast call $ROUTER "getVerifier(bytes4)(address)" <SELECTOR> --rpc-url <CHAIN_NAME>
  ```

- [ ] Run `just contracts-test`. It forks all supported networks except Monad and Monad testnet, so check those two with the `cast call` above.

### 4. Stop the Previous Verifier

- [ ] After the protocol adapters of the chain use the new selector, the guardian calls `estop()` on the emergency stop of the previous verifier. Each contract that still uses the previous selector then stops too.

- [ ] Keep the previous selector in the router, and do not call `removeVerifier`. The legacy protocol adapter reads the stop state of its verifier through the router, and this read reverts for a removed selector.

### 5. Release

- [ ] Merge the work, create a GitHub release, and publish the contracts package as in steps 5 and 6 of [Deploying RISC Zero contracts](#deploying-risc-zero-contracts).

- [ ] Release the bindings.

## Releasing the Bindings

### 1. Prerequisites

- [ ] Check that the bindings are up-to-date with

  ```sh
  just bindings-check
  ```

- [ ] Checkout a new git branch branching off from `main`.

- [ ] Check that there are no staged or unstaged changes by running `git status`.

### 2. Bump and Test the Bindings

- [ ] Change the `bindings` package version number in the [`./bindings/Cargo.toml`](./bindings/Cargo.toml) file to `A.B.C` following [SemVer](https://semver.org/spec/v2.0.0.html).

- [ ] Clean the bindings build with `just bindings-clean`.

- [ ] Regenerate the bindings with `just contracts-gen-bindings` and check that `just bindings-check` passes.

- [ ] Run `just bindings-build` and check that the `Cargo.lock` file reflects the version number change.

- [ ] Run the tests with `just bindings-test`.

### 3. Create a new `bindings` GitHub Release

- [ ] After merging, create a new `bindings/vA.B.C` tag.

- [ ] Create a new [GH release](https://github.com/anoma/risc0-deployments/releases).

### 4. Publish a new `bindings` package

- [ ] Publish the `anoma-risc0-deployments-bindings` package on https://crates.io/ with

  ```sh
  just bindings-publish --dry-run
  ```

  and check the result. If everything is correct, remove the `--dry-run` flag and publish the package.
