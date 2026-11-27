# Framecut

Framecut is a local, open-source video editor built from Concat. It adds ten GPU effects and transitions, indexed timeline lookups, faster proxy generation, and hardware ProRes 4444 encoding on supported Macs.

- [Build and run on macOS](docs/FRAMECUT.md)
- [Engine changes and effect controls](docs/FRAMECUT.md#implementation-plan-and-files)
- [Before-and-after benchmarks](docs/FRAMECUT_BENCHMARKS.md)
- [Landing page source](site/)

The native studio uses Slint. The Rust engine under `src/crates` uses wgpu for preview and export and links to FFmpeg. Existing Concat project files use the same document format.

## Source and license

Framecut is distributed under **AGPL-3.0-or-later**. It preserves the history and attribution of [Concat](https://github.com/jub0t/Concat), originally developed by Jareer Abdullah. See the [license](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md).
