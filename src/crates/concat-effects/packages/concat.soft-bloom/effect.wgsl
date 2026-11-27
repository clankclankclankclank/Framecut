// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, threshold: f32, radius: f32 }

fn highlights(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let threshold = params.threshold / 100.0;
    let knee = smoothstep(threshold, threshold + 0.25, luma(to_display(c.rgb)));
    return vec4<f32>(c.rgb * c.a * knee, c.a);
}

fn extract(uv: vec2<f32>) -> vec4<f32> {
    let d = texel();
    return (highlights(uv + d) + highlights(uv - d)
        + highlights(uv + vec2<f32>(d.x, -d.y))
        + highlights(uv + vec2<f32>(-d.x, d.y))) * 0.25;
}

// Spacing grows with height, so the look travels from preview to export.
fn radius_uv() -> vec2<f32> {
    return params.radius / 100.0 * 0.04 * frame.size.y / frame.size;
}

fn horizontal(uv: vec2<f32>) -> vec4<f32> {
    let d = vec2<f32>(radius_uv().x, 0.0);
    return (extract_at(uv - 2.0 * d) + 4.0 * extract_at(uv - d)
          + 6.0 * extract_at(uv) + 4.0 * extract_at(uv + d)
          + extract_at(uv + 2.0 * d)) / 16.0;
}

fn vertical(uv: vec2<f32>) -> vec4<f32> {
    let d = vec2<f32>(0.0, radius_uv().y);
    return (horizontal_at(uv - 2.0 * d) + 4.0 * horizontal_at(uv - d)
          + 6.0 * horizontal_at(uv) + 4.0 * horizontal_at(uv + d)
          + horizontal_at(uv + 2.0 * d)) / 16.0;
}

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    return vec4<f32>(c.rgb + vertical_at(uv).rgb * params.amount / 100.0, c.a);
}
