# Contributing to Framecut

The fastest way to help is to try a real edit and [report what you find](https://github.com/clankclankclankclank/Framecut/issues/new/choose). Include your OS, GPU, Framecut version or Git commit, and the type of media you used. For a large feature, open an issue with a short description of the workflow and the proposed change.

## Set up the workspace

Follow the [macOS build guide](docs/FRAMECUT.md#install-and-run-from-downloads), or see the [engine documentation](src/README.md#build-and-run) for other development setups. The Rust workspace lives under `src/`.

```sh
cd src
cargo run --locked --profile quick -p concat
```

## Check a change

From `src/`, run the checks for the crates you touched:

```sh
cargo fmt --all -- --check
cargo test --locked -p concat-effects
cargo test --locked -p concat-render --features gpu --lib plan::tests::
```

GPU effect changes can be checked on a working wgpu backend:

```sh
cargo test --locked -p concat-render --features gpu --lib every_package_probe_holds
```

Describe how you tested the change in your pull request. Include hardware, test footage characteristics, and before-and-after numbers for performance patches. Include a screenshot or short recording for visible UI changes. If you change translatable UI text, run `python3 scripts/locales.py` from the repository root. [Translation guide](TRANSLATING.md)

## Attribution and licensing

Framecut uses **AGPL-3.0-or-later**. Preserve existing license headers and attribution. If a patch adds third-party material, identify its source and license in the pull request. The upstream Concat contributor terms in [CLA.md](CLA.md) apply when submitting changes to Concat.
