# Framecut benchmark report

Measured on 28 November 2026 (IST) using one Apple M5 Pro Mac with 24 GB RAM, macOS 27.2.1, Metal, FFmpeg 9.1, and Rust 1.93.1. Both builds used the same optimized Cargo profile, sample footage and test harness. Upstream was `22dcbdc`. Each checkout used its own build artifacts.

The harness generated two four-second 1080p30 H.264 samples. The scrub project placed two visible layers with effects at the start of a 1,802-clip timeline. The export project drew those same layers into 120-frame files. Proxy timings include decode, scale and encode. Export and proxy rows report the median of three runs.

| Measurement | Upstream | Framecut |
| --- | ---: | ---: |
| Scrub plan creation | 89.865 ms | 92.633 ms |
| Timeline lookup for prefetch, mean over 12,000 queries | 3.492 µs | 0.515 µs |
| Cold scrub and render, p50 / p95 (12 samples) | 1.346 / 46.536 ms | 1.338 / 66.336 ms |
| Warm scrub and render, p50 / p95 (96 samples) | 0.505 / 0.994 ms | 0.496 / 1.012 ms |
| 540p working proxy generation | 231.008 ms | 177.722 ms |
| 540p H.264 export | 180.700 ms | 183.216 ms |
| 1080p ProRes 4444 export | 8.729 s | 1.233 s |

Timeline lookup was **6.8× faster**. Proxy generation took **23% less time**. ProRes 4444 export was **7.1× faster** on this machine, changing from `prores_ks` in software to `prores_videotoolbox` in hardware. H.264 used VideoToolbox in both builds and was 1.4% slower in this run. Warm scrub median changed by nine microseconds and p95 rose by eighteen microseconds. Cold p95 has only twelve samples and includes the first device and shader work in the process.

The ProRes profile and decoded frame count were verified with FFprobe. A keyed grade was also tested by comparing the paused GPU preview and the corresponding frames decoded from the exported ProRes file, allowing for codec rounding. Intel Mac timing and build behavior were outside this machine's test coverage.

## Reproduce

Use a macOS machine with the dependencies in the [build guide](FRAMECUT.md). The benchmark generator uses the Homebrew FFmpeg build with libx264.

```sh
export PATH="$(brew --prefix rustup)/bin:$PATH"
git clone https://github.com/jub0t/Concat.git /tmp/concat-upstream
git -C /tmp/concat-upstream checkout 22dcbdc
./scripts/benchmark-framecut.sh /tmp/concat-upstream /tmp/framecut-results
```

Use a fresh results directory for a new experiment. The script writes each build's raw samples to `before.txt` and `after.txt`, encoder selections and stage timings to matching `*-ffmpeg.log` files, and the generated videos beside them. Reserve several gigabytes for the isolated baseline build and encoded samples.
