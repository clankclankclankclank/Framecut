// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, angle: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    if (params.amount == 0.0) { return sample(uv); }
    let angle = radians(params.angle);
    let direction = vec2<f32>(cos(angle), sin(angle)) * frame.size.y / frame.size;
    let delta = direction * params.amount * 0.0015;
    var sum = vec4<f32>(0.0);
    var weight = 0.0;
    for (var tap = -6; tap <= 6; tap++) {
        let w = f32(7 - abs(tap));
        let c = sample(uv + delta * f32(tap) / 6.0);
        sum += vec4<f32>(c.rgb * c.a, c.a) * w;
        weight += w;
    }
    return vec4<f32>(sum.rgb / max(sum.a, 1e-6), sum.a / weight);
}
