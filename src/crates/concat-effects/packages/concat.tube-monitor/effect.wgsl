// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, curve: f32, scanlines: f32, tracking: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let original = sample(uv);
    let d = uv * 2.0 - 1.0;
    let bent = d * (1.0 + 0.18 * params.curve / 100.0 * dot(d, d));
    let position = bent * 0.5 + 0.5;
    let bar = fract(frame.clip_time * 0.23);
    let tear = exp(-abs(position.y - bar) * 66.0) * sin(frame.clip_time * 22.0);
    let x = position.x + tear * params.tracking * 0.0009;
    let c = sample(vec2<f32>(x, position.y));
    let scan = 1.0 - params.scanlines / 100.0 * (0.5 + 0.5 * cos(position.y * 1507.9645));
    let edge = 1.0 - smoothstep(0.97, 1.015, max(abs(bent.x), abs(bent.y)));
    let tint = vec3<f32>(0.93, 1.08, 0.97);
    return vec4<f32>(mix(original.rgb, c.rgb * tint * scan * edge, params.amount / 100.0), original.a);
}
