# Framecut

Framecut is an independent project built from [Concat](https://github.com/jub0t/Concat), based on upstream commit `22dcbdc`. It keeps the upstream Rust workspace under `src/crates`, the shared wgpu preview and export pipeline, FFmpeg development libraries, and the native Slint editor. The landing page in `site/` is static and can be served independently.

The upstream and modified source are available under **AGPL-3.0-or-later**. Preserve the [license](../LICENSE) and [third-party notices](../THIRD_PARTY_NOTICES.md). If you convey builds or operate a modified network-facing version, provide the corresponding source as required by the AGPL. The Framecut name and icon identify this fork. See the [upstream trademark policy](../TRADEMARK.md).

## Install and run from Downloads

Install Homebrew and the Xcode Command Line Tools. Run the first command only if the tools are missing, and wait for the installer to finish before proceeding.

```sh
xcode-select --install
brew install rustup cmake pkgconf ffmpeg
```

Download the [Framecut source ZIP](https://github.com/clankclankclankclank/Framecut/archive/refs/heads/main.zip) into `~/Downloads`. Extract it and launch the editor with these commands.

```sh
cd ~/Downloads
unzip Framecut-main.zip
cd Framecut-main
bash build_and_run_macos.sh --workspace "$PWD"
```

If you already have the launcher in Downloads or another checkout, let it extract an archive into its own workspace folder.

```sh
cd ~/Downloads
bash /path/to/build_and_run_macos.sh --zip Framecut-main.zip
```

The launcher also checks for `~/Downloads/Framecut` and automatically finds the newest `Concat*.zip` or `Framecut*.zip` when no path is passed. An explicit archive extracts to `~/Downloads/<archive-stem>-workspace`. It reuses that folder on later invocations. For a different source revision, use a ZIP with a different basename. Use `--check` to validate the workspace and installed tools, `--build-only` to compile without opening a window, or double-click `build_and_run_macos.command` from the source tree. Both launcher files must be next to one another.

The Rust toolchain is pinned in `src/rust-toolchain.toml`. FFmpeg 7+ headers and libraries are needed to link the engine. The Apple Silicon verification used FFmpeg 9.1. Use a native Homebrew installation for your Mac's architecture. The editor and static site have no Node.js build step. The first build can take several minutes while Cargo downloads dependencies and native libraries. Near the end of the progress counter, the Slint compiler and linker can run for several minutes between updates.

The equivalent direct build and launch commands are:

```sh
export PATH="$(brew --prefix rustup)/bin:$PATH"
cd ~/Downloads/Framecut-main/src
cargo build --locked --profile quick -p concat
cargo run --locked --profile quick -p concat
```

## Effects and transitions

| Package | Controls |
| --- | --- |
| Dusk Grade | Amount, tonal pivot, warmth, saturation |
| Soft Bloom | Amount, highlight threshold, radius |
| Prism Fringe | Amount, focus, angle |
| Streak Blur | Amount, direction |
| Orbital Blur | Spin, zoom, centre X and Y |
| Silver Grain | Amount, grain size, cadence |
| Screen Print | Amount, pitch, angle |
| Tube Monitor | Amount, glass curve, scanlines, tape tear |
| Spring Hit | Amount, settle time, direction, ringing |
| Soft Iris | Feather, centre X and Y |

The library loads the TOML manifests and effect cards. Add an effect to a clip or adjustment layer, then use the controls in the inspector. To animate a control, add a keyframe at the playhead, move to another frame, and add a new value. Use the curve editor to adjust easing where available. Soft Iris is placed on the timeline from the Transitions shelf and eases across the cut. The existing grading and imported `.cube` LUT workflow remains available in the editor.

Preview and export resolve the same manifests, parameters, effect order and shader code. The GPU runs the same effect at the corresponding timeline instant. Scrub proxies and lower-resolution preview can differ in individual pixels from the full-resolution export, and the final codec can change the encoded pixels. A machine with no wgpu adapter can fall back to upstream’s limited CPU renderer. The new WGSL effects require a working wgpu backend.

## Implementation plan and files

1. Index the immutable export and preview timeline in `concat-render/src/plan.rs` and wire both callers through `concat-export`. Search each lane's clip boundaries by timestamp and preserve the existing last-added winner for overlaps. Check the indexed and unindexed planners against the same test timeline.
2. In `concat-effects/src/catalogue.rs`, keep up to 96 recently used static passes. An edit to one effect's parameters misses for that parameter set and other effects can reuse their entries. Keyed values continue to be evaluated at the requested instant. The source frame pools stay independent of effect settings. In `concat-core/src/animate.rs`, find the enclosing keyframe segment by binary search.
3. Reuse pooled texture views in `concat-render/src/gpu.rs`. Overlap proxy decode and encode through a bounded queue in `concat-host/src/proxy.rs`. Decode follows the existing hardware policy with software fallback. The proxy key includes subsecond modification time. In `concat-media/src/encode.rs`, prefer hardware ProRes 4444 where VideoToolbox can open it and retain the software encoder as a fallback.
4. Ship ten sets of manifests, shaders and pixel probes in `concat-effects/packages/`. Use the manifest-driven inspector and render the still cards with the project's CLI on Metal. Apply Framecut colors and branding to the Slint shell, effect shelf and inspector. Use the same visual palette and real rendered card images on the responsive site.
5. Validate with the macOS launcher, GPU probes, and matched before-and-after workloads. Record measured results and machine details in [the benchmark report](FRAMECUT_BENCHMARKS.md).

## Preview the website

```sh
cd ~/Downloads/Framecut-main
python3 -m http.server 8764 --bind 127.0.0.1 --directory site
```

Open [the local site](http://127.0.0.1:8764). Choose an effect and use the comparison slider. The examples are stills rendered by the native shader pipeline. Editing, keyframing and export run in the desktop app.
