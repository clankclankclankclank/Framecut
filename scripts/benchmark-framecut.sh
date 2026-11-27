#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

if (( $# != 2 )); then
    printf 'Usage: %s /path/to/baseline-checkout /path/to/results\n' "$0" >&2
    exit 2
fi

root=$(cd "$(dirname "$0")/.." && pwd -P)
baseline=$(cd "$1" && pwd -P)
mkdir -p "$2"
results=$(cd "$2" && pwd -P)
example=crates/concat-host/examples/framecut_bench.rs
[[ ! -e "$baseline/src/$example" ]] || {
    printf 'Use an upstream baseline checkout without %s\n' "$example" >&2
    exit 2
}
mkdir -p "$baseline/src/$(dirname "$example")"
cp -n "$root/src/$example" "$baseline/src/$example"
trap 'rm -f -- "$baseline/src/$example"' EXIT

ffmpeg -v error -y -f lavfi -i 'testsrc2=size=1920x1080:rate=30' -t 4 \
    -c:v libx264 -preset fast -g 60 -threads 4 "$results/motion.mp4"
ffmpeg -v error -y -f lavfi -i 'smptebars=size=1920x1080:rate=30' -t 4 \
    -c:v libx264 -preset fast -g 60 -threads 4 "$results/bars.mp4"

# Build both before the timed runs to avoid measuring compilation.
for checkout in "$baseline" "$root"; do
    label=after
    if [[ "$checkout" == "$baseline" ]]; then label=before; fi
    (
        cd "$checkout/src"
        # The checkouts share crate names and versions. Isolate artifacts so
        # a local crate cannot accidentally link an object from the other tree.
        if [[ "$label" == before ]]; then
            export CARGO_TARGET_DIR="$results/target-before"
        else
            export CARGO_TARGET_DIR="${FRAMECUT_BENCH_TARGET_DIR:-$root/src/target}"
        fi
        cargo build --locked --profile quick -p concat-host --features gpu --example framecut_bench
        cp "$CARGO_TARGET_DIR/quick/examples/framecut_bench" "$results/$label-bench"
    )
done

for label in before after; do
    "$results/$label-bench" "$results/motion.mp4" "$results/bars.mp4" "$results/$label" \
        2>"$results/$label-ffmpeg.log" | tee "$results/$label.txt"
done
