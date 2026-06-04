//! Rust bindings for the RISC Zero verifier contracts used by Anoma's EVM
//! deployments and integration tests: the Groth16 verifier, the mock verifier,
//! the verifier router, and the emergency-stop wrapper.
//!
//! Generated from the contracts in this repository with `forge bind`; regenerate
//! via `just contracts-gen-bindings`.

#[rustfmt::skip]
pub mod generated;
