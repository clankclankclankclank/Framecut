// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, size: f32, cadence: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let grid = floor(uv * frame.size / max(frame.size.y / 1080.0 * params.size, 0.5));
    let tick = floor(frame.clip_time * params.cadence);
    let noise = hash(grid, tick) + hash(grid + vec2<f32>(37.0, 11.0), tick) - 1.0;
    let display = to_display(c.rgb);
    let mid = clamp(luma(display), 0.0, 1.0);
    let strength = (0.3 + 0.7 * 4.0 * mid * (1.0 - mid)) * params.amount / 100.0;
    return vec4<f32>(from_display(display + noise * strength * 0.22), c.a);
}
