// SPDX-License-Identifier: AGPL-3.0-or-later

//! Repeatable scrub, proxy and multitrack export timings for a supplied sample.

use std::error::Error;
use std::hint::black_box;
use std::path::Path;
use std::sync::atomic::AtomicBool;
use std::time::{Duration, Instant};

use concat_effects::AppliedFilter;
use concat_export::{ClipKind, ColorSpace, ExportClip, ExportRequest, Reporter};
use concat_media::{ReaderPool, VideoCodec};

const CANVAS: [u8; 4] = [0, 0, 0, 255];
const WIDTH: u32 = 960;
const HEIGHT: u32 = 540;

fn ms(time: Duration) -> f64 {
    time.as_secs_f64() * 1000.0
}

fn clip(path: &str, start: f64, duration: f64, track: usize) -> ExportClip {
    let mut clip = ExportClip::blank(ClipKind::Video, start, duration, track);
    clip.path = path.to_owned();
    clip.muted = true;
    clip.has_audio = Some(false);
    clip.media_width = Some(1920);
    clip.media_height = Some(1080);
    clip
}

fn main() -> Result<(), Box<dyn Error>> {
    let _ = concat_host::logs::open_console(None);
    let args: Vec<_> = std::env::args().skip(1).collect();
    let [a, b, destination] = args.as_slice() else {
        return Err(
            "usage: framecut_bench <sample-a.mp4> <sample-b.mp4> <output-directory>".into(),
        );
    };
    let destination = Path::new(destination);
    std::fs::create_dir_all(destination)?;

    let mut clips = vec![clip(a, 0.0, 4.0, 0), clip(b, 0.0, 4.0, 1)];
    clips[0].effects.push(AppliedFilter::new("concat.vignette"));
    clips[1].opacity = 0.65;
    clips[1].scale = 0.6;
    clips[1]
        .effects
        .push(AppliedFilter::new("concat.chromatic-aberration"));
    // Put the four-second sample at the beginning of a larger edit. The
    // other clips share the same footage but never cover a sampled frame.
    let mut scrub_clips = clips.clone();
    for index in 0..1800 {
        let start = 4.0 + f64::from(index as u32) / 2.0;
        scrub_clips.push(clip(a, start, 0.5, index % 2));
    }

    let plan_began = Instant::now();
    let plan =
        concat_export::preview_plan(&scrub_clips, WIDTH, HEIGHT, 30, 1, ColorSpace::Sdr, CANVAS);
    println!("scrub_plan_ms={:.3}", ms(plan_began.elapsed()));
    let pool = ReaderPool::new(512 * 1024 * 1024, 6);
    let samples = [7, 60, 19, 76, 21, 34, 85, 0, 12, 70, 33, 54];
    // Measure the same frame planning that feeds decode-ahead, separately
    // from source decode, GPU draw and readback.
    let queries = 12_000;
    let began = Instant::now();
    for index in 0..queries {
        let earlier = f64::from(samples[index % samples.len()] - 1) / 30.0;
        black_box(concat_export::preview_moments(&plan, earlier, 1, false));
    }
    println!(
        "timeline_queries={queries} us_per_query={:.3}",
        began.elapsed().as_secs_f64() * 1_000_000.0 / queries as f64
    );

    for (label, rounds) in [("cold", 1), ("warm", 8)] {
        let mut times = Vec::new();
        for _ in 0..rounds {
            for frame in samples {
                let began = Instant::now();
                let sources = concat_export::preview_sources_of(
                    &pool,
                    &plan,
                    f64::from(frame) / 30.0,
                    false,
                    false,
                )?;
                if sources.plan().layers.len() != 2 {
                    return Err(format!("frame {frame} is missing a sample clip").into());
                }
                black_box(sources.pixels(true)?);
                times.push(ms(began.elapsed()));
            }
        }
        times.sort_by(f64::total_cmp);
        let p50 = times[times.len().div_ceil(2) - 1];
        let p95 = times[(times.len() * 95).div_ceil(100) - 1];
        println!(
            "scrub_{label}_samples={} p50_ms={p50:.3} p95_ms={p95:.3}",
            times.len()
        );
    }

    for attempt in 0..3 {
        let began = Instant::now();
        let proxy_path = destination.join(format!("proxy-{attempt}.mp4"));
        concat_host::proxy::write(a, &proxy_path, (WIDTH, HEIGHT), None)?;
        println!("proxy_ms={:.3}", ms(began.elapsed()));
    }

    for codec in [VideoCodec::H264, VideoCodec::ProRes4444] {
        let (width, height) = if codec == VideoCodec::ProRes4444 {
            (1920, 1080)
        } else {
            (WIDTH, HEIGHT)
        };
        for attempt in 0..3 {
            let output =
                destination.join(format!("{}-{attempt}.{}", codec.name(), codec.container()));
            let request = ExportRequest {
                width,
                height,
                rate_num: 30,
                rate_den: 1,
                crf: 18,
                preset: "medium".to_owned(),
                codec,
                ten_bit: false,
                rate_mode: Default::default(),
                bitrate_kbps: 0,
                color_range: Default::default(),
                color_space: ColorSpace::Sdr,
                hdr: false,
                effect_time_offset: 0.0,
                canvas: CANVAS,
                clips: clips.clone(),
                resume: None,
                output: output.to_string_lossy().into_owned(),
            };
            let began = Instant::now();
            let reported = concat_export::render(
                &request,
                Reporter {
                    progress: &mut |_, _, _| {},
                    cancel: &AtomicBool::new(false),
                },
            );
            reported.map_err(|error| format!("{error:?}"))?;
            let took = ms(began.elapsed());
            println!(
                "export_{}_ms={took:.3} fps={:.2}",
                codec.name(),
                120_000.0 / took
            );
        }
    }
    Ok(())
}
