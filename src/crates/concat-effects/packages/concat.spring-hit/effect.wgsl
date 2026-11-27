// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, length: f32, direction: f32, frequency: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let t = clamp(frame.clip_time / params.length, 0.0, 1.0);
    let falloff = (1.0 - t) * (1.0 - t);
    let strength = params.amount / 100.0 * falloff;
    let angle = radians(params.direction);
    let axis = vec2<f32>(cos(angle), sin(angle)) * frame.size.y / frame.size;
    let ring = cos(frame.clip_time * params.frequency * 6.28318531);
    let look = (uv - 0.5) / (1.0 + strength * 0.22) + 0.5;
    return sample(look + axis * ring * strength * 0.05);
}
