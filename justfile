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

# Clean contracts
contracts-clean:
    cd contracts && forge clean

# Build contracts
contracts-build *args:
    cd contracts && forge build {{ args }}

# Lint contracts (forge lint + solhint)
contracts-lint:
    cd contracts && forge lint --deny warnings
    cd contracts && bunx --bun solhint --config .solhint.json 'src/**/*.sol'
    cd contracts && bunx --bun solhint --config .solhint.other.json 'test/**/*.sol'
    cd contracts && bunx --bun solhint --config .solhint.other.json 'script/**/*.sol'

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

# Verify RISC Zero contracts on Sourcify
contracts-verify-sourcify groth16 estop router chain *args:
    cd contracts && env -u ETHERSCAN_API_KEY \
    forge verify-contract {{groth16}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
        --chain {{chain}} --verifier sourcify --watch {{ args }}
    cd contracts && env -u ETHERSCAN_API_KEY \
    forge verify-contract {{estop}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol:RiscZeroVerifierEmergencyStop \
        --chain {{chain}} --verifier sourcify  --watch {{ args }}
    cd contracts && env -u ETHERSCAN_API_KEY \
    forge verify-contract {{router}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol:RiscZeroVerifierRouter \
        --chain {{chain}} --verifier sourcify --watch {{ args }}

# Verify on etherscan
contracts-verify-etherscan groth16 estop router chain *args:
    cd contracts && forge verify-contract {{groth16}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
        --chain {{chain}} --verifier etherscan --watch  {{ args }}
    cd contracts && forge verify-contract {{estop}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol:RiscZeroVerifierEmergencyStop \
        --chain {{chain}} --verifier etherscan  --watch {{ args }}
    cd contracts && forge verify-contract {{router}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol:RiscZeroVerifierRouter \
        --chain {{chain}} --verifier etherscan --watch {{ args }}

# Verify on custom explorer
contracts-verify-custom groth16 estop router chain verifier-url *args:
    cd contracts && forge verify-contract {{groth16}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
        --chain {{chain}} --verifier-url {{verifier-url}} --watch  {{ args }}
    cd contracts && forge verify-contract {{estop}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol:RiscZeroVerifierEmergencyStop \
        --chain {{chain}} --verifier-url {{verifier-url}}  --watch {{ args }}
    cd contracts && forge verify-contract {{router}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol:RiscZeroVerifierRouter \
        --chain {{chain}} --verifier-url {{verifier-url}} --watch {{ args }}

# Verify on both sourcify and etherscan
contracts-verify groth16 estop router chain: (contracts-verify-sourcify groth16 estop router chain) (contracts-verify-etherscan groth16 estop router chain)

# Publish contracts
contracts-publish version *args:
    cd contracts && forge soldeer push anoma-risc0-deployments~{{version}} {{ args }}

# Regenerate Rust bindings from the RISC Zero verifier contracts
contracts-gen-bindings:
    cd contracts && forge clean && forge bind \
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
