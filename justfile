# Show commands before running (helps debug failures)
set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe
default:
    @just --list

# --- Contracts ---

# Install contract dependencies
contracts-deps:
    cd contracts && forge soldeer install

# Clean contract dependencies
contracts-deps-clean:
    cd contracts && forge soldeer clean

# Install the contract tooling (solhint) from the lockfile
contracts-tooling:
    cd contracts && bun install --frozen-lockfile

# Clean contracts
contracts-clean:
    cd contracts && forge clean

# Build contracts
contracts-build *args:
    cd contracts && forge build {{ args }}

# Lint contracts: forge lint, then solhint for the rules that forge lint lacks
contracts-lint:
    cd contracts && forge lint --deny notes --report-unused-suppressions
    cd contracts && bunx --bun solhint --max-warnings 0 --config .solhint.json 'src/**/*.sol'
    cd contracts && bunx --bun solhint --max-warnings 0 --config .solhint.other.json 'test/**/*.sol'
    cd contracts && bunx --bun solhint --max-warnings 0 --config .solhint.other.json 'script/**/*.sol'

# Run slither on contracts
contracts-static-analysis:
    cd contracts && slither .
    @echo "Removing slither compilation artifacts..."
    cd contracts && forge clean

# Format contracts
contracts-fmt *args:
    cd contracts && forge fmt {{ args }}

# Check contract formatting
contracts-fmt-check:
    cd contracts && forge fmt --check

# Run contract tests
contracts-test *args:
    cd contracts && forge test {{ args }}

# Simulate deployment (dry-run)
contracts-simulate admin guardian chain *args:
    @echo "ADMIN: $ADMIN"
    @echo "GUARDIAN: $GUARDIAN"
    @echo "Cleaning contracts to ensure reproducible build..."
    @just contracts-clean
    cd contracts && forge script \
        script/DeployRiscZeroContracts.s.sol:DeployRiscZeroContracts \
        --sig "run(address,address)" {{admin}} {{guardian}} \
        --rpc-url {{chain}} {{ args }}

# Deploy RISC Zero contracts (router + groth16 + emergency stop)
contracts-deploy deployer admin guardian chain *args:
    @echo "Cleaning contracts to ensure reproducible build..."
    @just contracts-clean
    cd contracts && forge script \
        script/DeployRiscZeroContracts.s.sol:DeployRiscZeroContracts \
        --sig "run(address,address)" {{admin}} {{guardian}} \
        --broadcast --rpc-url {{chain}} --account {{deployer}} --sender $(cast wallet address --account {{deployer}}) {{ args }}

# Simulate the deployment of a verifier for an existing router (dry-run)
contracts-simulate-verifier chain *args:
    @echo "Cleaning contracts to ensure reproducible build..."
    @just contracts-clean
    cd contracts && forge script \
        script/DeployRiscZeroVerifier.s.sol:DeployRiscZeroVerifier \
        --rpc-url {{chain}} {{ args }}

# Deploy a verifier and its emergency stop for an existing router (groth16 + emergency stop). `deployer` is the account
# of the deployment wallet in `contracts/script/Parameters.sol`, which the script deploys from.
contracts-deploy-verifier deployer chain *args:
    @echo "Cleaning contracts to ensure reproducible build..."
    @just contracts-clean
    cd contracts && forge script \
        script/DeployRiscZeroVerifier.s.sol:DeployRiscZeroVerifier \
        --broadcast --rpc-url {{chain}} --account {{deployer}} {{ args }}

# Simulate the `addVerifier` proposal (dry-run): checks the emergency stop and simulates the PA Safe executing the call
contracts-simulate-add-verifier-proposal estop chain *args:
    cd contracts && forge script \
        script/ProposeAddVerifier.s.sol:ProposeAddVerifier \
        --sig "run(address)" {{estop}} \
        --rpc-url {{chain}} {{ args }}

# Propose adding the verifier behind an emergency stop to the router to the PA Safe. `deployer` is the account of the
# deployment wallet in `contracts/script/Parameters.sol`, which proposes the call.
# The Safe Transaction Service request runs through `curl`, so the recipe needs `--ffi`.
contracts-propose-add-verifier deployer estop chain *args:
    cd contracts && forge script \
        script/ProposeAddVerifier.s.sol:ProposeAddVerifier \
        --sig "run(address)" {{estop}} \
        --broadcast --ffi --rpc-url {{chain}} --account {{deployer}} {{ args }}

# The RISC Zero contracts, by their path in the risc0-ethereum dependency
risc0_ethereum_src := "dependencies/risc0-risc0-ethereum-3.1.0/contracts/src"
groth16_verifier_contract := risc0_ethereum_src + "/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier"
emergency_stop_contract := risc0_ethereum_src + "/RiscZeroVerifierEmergencyStop.sol:RiscZeroVerifierEmergencyStop"
router_contract := risc0_ethereum_src + "/RiscZeroVerifierRouter.sol:RiscZeroVerifierRouter"

# Verify a contract on Sourcify. `chain` is an RPC endpoint of `contracts/foundry.toml`, which gives the chain ID.
contracts-verify-sourcify address contract chain *args:
    cd contracts && env -u ETHERSCAN_API_KEY forge verify-contract {{address}} {{contract}} \
        --rpc-url {{chain}} --verifier sourcify --watch {{ args }}

# Verify a contract on Etherscan, with the constructor arguments of its creation transaction
contracts-verify-etherscan address contract chain *args:
    cd contracts && forge verify-contract {{address}} {{contract}} \
        --rpc-url {{chain}} --verifier etherscan --watch \
        --guess-constructor-args --skip-is-verified-check {{ args }}

# Verify a contract on a custom explorer
contracts-verify-custom address contract chain verifier-url *args:
    cd contracts && forge verify-contract {{address}} {{contract}} \
        --rpc-url {{chain}} --verifier-url {{verifier-url}} --watch {{ args }}

# Verify a contract on Sourcify and Etherscan
contracts-verify address contract chain: (contracts-verify-sourcify address contract chain) (contracts-verify-etherscan address contract chain)

# Verify a Groth16 verifier and its emergency stop on Sourcify and Etherscan
contracts-verify-verifier groth16 estop chain: (contracts-verify groth16 groth16_verifier_contract chain) (contracts-verify estop emergency_stop_contract chain)

# Verify the Groth16 verifier, the emergency stop and the router of a deployment on Sourcify and Etherscan
contracts-verify-deployment groth16 estop router chain: (contracts-verify-verifier groth16 estop chain) (contracts-verify router router_contract chain)

# Publish contracts to soldeer. VERSION must be semver (e.g. 1.2.0).
# Flags such as --dry-run go AFTER the version: `just contracts-publish 1.2.0 --dry-run`.
contracts-publish version *args:
    @[[ "{{version}}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]] || { echo "error: invalid version '{{version}}'. Expected semver like 1.2.0. Usage: just contracts-publish <version> [flags] (put --dry-run AFTER the version)." >&2; exit 1; }
    cd contracts && forge soldeer push anoma-risc0-deployments~{{version}} {{ args }}

# Regenerate Rust bindings from the RISC Zero verifier contracts
contracts-gen-bindings:
    # `forge bind` builds without bytecode, which drops the `deploy` helpers, so
    # build first and let it read those artifacts.
    cd contracts && forge clean && forge build && forge bind \
        --skip-build \
        --select '^(RiscZeroGroth16Verifier|RiscZeroMockVerifier|RiscZeroVerifierEmergencyStop|RiscZeroVerifierRouter)$' \
        --bindings-path ../bindings/src/generated/ \
        --module \
        --overwrite

# --- Bindings ---

# Clean bindings
bindings-clean:
    cd bindings && cargo clean

# Build bindings
bindings-build *args:
    cd bindings && cargo build {{ args }}

# Test bindings
bindings-test *args:
    cd bindings && cargo test {{ args }}

# Check bindings are up-to-date
bindings-check: contracts-gen-bindings
    git diff --exit-code bindings/src/generated/

# Lint bindings (clippy)
bindings-lint:
    cd bindings && cargo clippy --no-deps -- -Dwarnings
    cd bindings && cargo clippy --no-deps --tests -- -Dwarnings

# Format bindings
bindings-fmt *args:
    cd bindings && cargo fmt {{ args }}

# Check bindings formatting
bindings-fmt-check:
    cd bindings && cargo fmt -- --check

# Publish bindings
bindings-publish *args:
    cd bindings && cargo publish {{ args }}

# --- All ---

# Lint all (contracts + bindings)
all-lint:
    @echo "==> Linting contracts..."
    @just contracts-lint
    @echo "==> Linting bindings..."
    @just bindings-lint

# Format all (contracts + bindings)
all-fmt:
    @echo "==> Formatting contracts..."
    @just contracts-fmt
    @echo "==> Formatting bindings..."
    @just bindings-fmt

# Check formatting for all (contracts + bindings)
all-fmt-check:
    @echo "==> Checking contract formatting..."
    @just contracts-fmt-check
    @echo "==> Checking bindings formatting..."
    @just bindings-fmt-check

# Build all (contracts + bindings)
all-build:
    @echo "==> Building contracts..."
    @just contracts-build
    @echo "==> Building bindings..."
    @just bindings-build

# Test all (contracts + bindings)
all-test:
    @echo "==> Testing contracts..."
    @just contracts-test
    @echo "==> Testing bindings..."
    @just bindings-test

# Prerequisites check (mirrors CI)
all-check:
    git status
    @echo "==> Static analysis with slither..."
    @just contracts-static-analysis
    @echo "==> Checking formatting..."
    @just all-fmt-check
    @echo "==> Linting..."
    @just all-lint
    @echo "==> Checking bindings are up-to-date..."
    @just bindings-check
