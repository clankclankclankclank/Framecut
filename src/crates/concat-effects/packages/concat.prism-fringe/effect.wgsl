// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, focus: f32, angle: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let centre = sample(uv);
    let d = uv - vec2<f32>(0.5);
    let turn = radians(params.angle);
    let direction = vec2<f32>(cos(turn) * d.x - sin(turn) * d.y,
                              sin(turn) * d.x + cos(turn) * d.y);
    let shift = direction * (params.amount / 100.0) * 0.14
        * smoothstep(params.focus / 100.0, 1.0, length(d) * 1.41421356);
    let red = sample(uv + shift);
    let blue = sample(uv - shift);
    let r = mix(centre.r, red.r, red.a);
    let b = mix(centre.b, blue.b, blue.a);
    return vec4<f32>(r, centre.g, b, centre.a);
}
