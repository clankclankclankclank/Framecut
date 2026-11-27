#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }
usage() {
    cat <<'HELP'
Usage: build_and_run_macos.sh [--zip FILE | --workspace DIR] [--build-only | --check]
Relative archive names are looked up in ~/Downloads. Without arguments the
script uses ~/Downloads/Framecut, the newest Concat*.zip or Framecut*.zip in
Downloads, an extracted *-workspace folder, or the adjacent source tree.
HELP
}

archive=
workspace=
mode=run
while (( $# )); do
    case "$1" in
        --zip|--workspace)
            (( $# >= 2 )) || fail "Missing argument for $1"
            if [[ "$1" == --zip ]]; then archive=$2; else workspace=$2; fi
            shift 2 ;;
        --build-only) mode=build; shift ;;
        --check) mode=check; shift ;;
        --help|-h) usage; exit ;;
        --) shift; break ;;
        *) fail "Unknown argument $1. Run with --help." ;;
    esac
done

[[ "$(uname -s)" == Darwin ]] || fail "This launcher requires macOS."
[[ -z "$archive" || -z "$workspace" ]] || fail "Choose either --zip or --workspace."
xcode-select -p >/dev/null 2>&1 && xcrun --find clang++ >/dev/null 2>&1 ||
    fail "Install the Xcode Command Line Tools with: xcode-select --install"

script_dir=$(cd -- "$(dirname -- "$0")" && pwd -P)
downloads="$HOME/Downloads"
mkdir -p "$downloads"

if [[ -z "$archive" && -z "$workspace" ]]; then
    if [[ -f "$downloads/Framecut/src/Cargo.toml" ]]; then
        workspace="$downloads/Framecut"
    else
        shopt -s nullglob nocaseglob
        for candidate in "$downloads"/Concat*.zip "$downloads"/Framecut*.zip; do
            if [[ -f "$candidate" && ( -z "$archive" || "$candidate" -nt "$archive" ) ]]; then
                archive=$candidate
            fi
        done
        if [[ -z "$archive" ]]; then
            for candidate in "$downloads"/Concat*-workspace "$downloads"/Framecut*-workspace; do
                if [[ -f "$candidate/src/Cargo.toml" && ( -z "$workspace" || "$candidate" -nt "$workspace" ) ]]; then
                    workspace=$candidate
                fi
            done
        fi
        shopt -u nullglob nocaseglob
        if [[ -z "$archive" && -z "$workspace" ]]; then workspace=$script_dir; fi
    fi
fi

if [[ -n "$archive" ]]; then
    [[ "$archive" == /* || "$archive" == */* ]] || archive="$downloads/$archive"
    [[ -f "$archive" ]] || fail "Archive not found: $archive"
    archive=$(cd -- "$(dirname -- "$archive")" && pwd -P)/$(basename -- "$archive")
    name=$(basename -- "$archive")
    workspace="$downloads/${name%.*}-workspace"
    [[ ! -e "$workspace" || -f "$workspace/src/Cargo.toml" ]] ||
        fail "The extraction destination already exists: $workspace"
    if [[ ! -f "$workspace/src/Cargo.toml" ]]; then
        stage=$(mktemp -d "$downloads/.framecut-extract.XXXXXXXX")
        trap 'rm -rf -- "$stage"' EXIT
        /usr/bin/python3 - "$archive" "$stage" "$workspace" <<'PYTHON'
from pathlib import Path, PurePosixPath
import os
import shutil
import stat
import sys
import zipfile

archive, staging, workspace = map(Path, sys.argv[1:])
try:
    with zipfile.ZipFile(archive) as bundle:
        for member in bundle.infolist():
            name = PurePosixPath(member.filename)
            mode = member.external_attr >> 16
            if name.is_absolute() or ".." in name.parts or "\\" in member.filename:
                raise ValueError(f"Unsafe archive path {member.filename!r}")
            if not name.parts or "__MACOSX" in name.parts or name.name == ".DS_Store":
                continue
            if stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR):
                raise ValueError(f"Unsupported archive member {member.filename!r}")
            target = staging.joinpath(*name.parts)
            if member.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with bundle.open(member) as source, target.open("xb") as output:
                shutil.copyfileobj(source, output)
            if mode & 0o111:
                target.chmod(0o755)
        candidates = [p for p in (staging, *staging.iterdir())
                      if (p / "src" / "Cargo.toml").is_file()
                      and (p / "src" / "crates" / "concat" / "Cargo.toml").is_file()]
        if len(candidates) != 1:
            raise ValueError("Expected one source root containing src/Cargo.toml and the desktop crate")
        os.rename(candidates[0], workspace)
except (OSError, ValueError, zipfile.BadZipFile, RuntimeError) as error:
    sys.exit(f"Could not extract {archive.name}: {error}")
PYTHON
        printf 'Extracted %s to %s\n' "$archive" "$workspace"
    fi
fi

[[ -f "$workspace/src/Cargo.toml" && -f "$workspace/src/crates/concat/Cargo.toml" ]] ||
    fail "No Concat source tree at $workspace. Put a source zip in $downloads or use --workspace."
workspace=$(cd -- "$workspace" && pwd -P)
export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if command -v brew >/dev/null; then
    rustup_bin="$(brew --prefix rustup)/bin"
    [[ ! -x "$rustup_bin/rustup" ]] || export PATH="$rustup_bin:$PATH"
fi

missing=()
for tool in cmake pkg-config ffmpeg cargo rustc; do
    command -v "$tool" >/dev/null || missing+=("$tool")
done
if (( ${#missing[@]} )); then
    fail "Missing: ${missing[*]}. Install with: brew install cmake pkgconf ffmpeg rustup"
fi
# libavcodec major 61 is FFmpeg 7.
ffmpeg_major=$(ffmpeg -version | awk 'NR == 1 { split($3, version, "."); print version[1] }')
if [[ "$ffmpeg_major" =~ ^[0-9]+$ ]] && (( ffmpeg_major < 7 )); then
    fail "FFmpeg 7 or later is required. Run: brew install ffmpeg"
fi
if [[ -n "${FFMPEG_DIR:-}" ]]; then
    export PKG_CONFIG_PATH="$FFMPEG_DIR/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
fi
if ! pkg-config --atleast-version=61 libavcodec && [[ -z "${FFMPEG_DIR:-}" ]]; then
    fail "FFmpeg 7+ development libraries are required. Run: brew install ffmpeg pkgconf"
fi

cd -- "$workspace/src"
# The repository pins Rust. The rustup proxies install the required toolchain
# on first use. A standalone Cargo can be used if it is sufficiently recent.
cargo --version
rustc --version
if [[ "$mode" == check ]]; then
    printf 'Toolchain found for %s. Source: %s\n' "$(uname -m)" "$workspace"
    exit
fi

profile=${FRAMECUT_PROFILE:-quick}
if [[ "$mode" == build ]]; then
    exec cargo build --locked --profile "$profile" -p concat
fi
exec cargo run --locked --profile "$profile" -p concat -- "$@"
