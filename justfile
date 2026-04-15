# Show commands before running (helps debug failures)
set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe
default:
    @just --list

# --- Contracts ---

# Install contract dependencies
contracts-deps:
    forge soldeer install

# Clean contract dependencies
contracts-deps-clean:
    forge soldeer clean

# Clean contracts
contracts-clean:
    forge clean

# Build contracts
contracts-build *args:
    forge build {{ args }}

# Lint contracts (forge lint + solhint)
contracts-lint:
    forge lint --deny warnings
    bunx --bun solhint --config .solhint.json 'src/**/*.sol'
    bunx --bun solhint --config .solhint.other.json 'test/**/*.sol'
    bunx --bun solhint --config .solhint.other.json 'script/**/*.sol'

# Run slither on contracts
contracts-static-analysis:
    slither .
    @echo "Removing slither compilation artifacts..."
    forge clean

# Format contracts
contracts-fmt *args:
    forge fmt {{ args }}

# Check contract formatting
contracts-fmt-check:
    forge fmt --check

# Run contract tests
contracts-test *args:
    forge test {{ args }}

# Simulate deployment (dry-run)
contracts-simulate admin guardian chain *args:
    forge script \
        test/script/DeployRiscZeroContracts.s.sol:DeployRiscZeroContracts \
        --sig "run(address,address)" {{admin}} {{guardian}} \
        --rpc-url {{chain}} {{ args }}

# Deploy RISC Zero verifier (router + groth16 + emergency stop)
contracts-deploy deployer admin guardian chain *args:
    forge script \
        test/script/DeployRiscZeroContracts.s.sol:DeployRiscZeroContracts \
        --sig "run(address,address)" {{admin}} {{guardian}} \
        --broadcast --rpc-url {{chain}} --account {{deployer}} {{ args }}

# Verify RISC Zero verifier contracts on Sourcify
contracts-verify-sourcify groth16 estop router chain *args:
    forge verify-contract {{groth16}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
        --chain {{chain}} --verifier sourcify --watch {{ args }}
    forge verify-contract {{estop}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol:RiscZeroVerifierEmergencyStop \
        --chain {{chain}} --verifier sourcify  --watch {{ args }}
    forge verify-contract {{router}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol:RiscZeroVerifierRouter \
        --chain {{chain}} --verifier sourcify --watch {{ args }}

# Verify on etherscan
contracts-verify-etherscan groth16 estop router chain *args:
    forge verify-contract {{groth16}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/groth16/RiscZeroGroth16Verifier.sol:RiscZeroGroth16Verifier \
        --chain {{chain}} --verifier etherscan --watch  {{ args }}
    forge verify-contract {{estop}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierEmergencyStop.sol:RiscZeroVerifierEmergencyStop \
        --chain {{chain}} --verifier etherscan  --watch {{ args }}
    forge verify-contract {{router}} \
        dependencies/risc0-risc0-ethereum-3.0.1/contracts/src/RiscZeroVerifierRouter.sol:RiscZeroVerifierRouter \
        --chain {{chain}} --verifier etherscan --watch {{ args }}

# Verify on both sourcify and etherscan
contracts-verify groth16 estop router chain: (contracts-verify-sourcify groth16 estop router chain) (contracts-verify-etherscan groth16 estop router chain)

# Publish contracts
contracts-publish version *args:
    forge soldeer push anoma-risc0-deployments~{{version}} {{ args }}

# --- All ---

# Prerequisites check (mirrors CI)
all-check:
    git status
    @echo "==> Static analysis with slither..."
    @just contracts-static-analysis
    @echo "==> Checking formatting..."
    @just contracts-fmt-check
    @echo "==> Linting..."
    @just contracts-lint
