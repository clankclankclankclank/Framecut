// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, pivot: f32, warmth: f32, saturation: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let rgb = to_display(c.rgb);
    let grey = luma(rgb);
    let pivot = params.pivot / 100.0;
    let zones = smoothstep(pivot - 0.25, pivot + 0.25, grey);
    let chrome = mix(vec3<f32>(-0.06, 0.025, 0.09), vec3<f32>(0.1, 0.02, -0.07), zones);
    let graded = mix(vec3<f32>(grey), rgb, params.saturation / 100.0)
        + chrome * (params.warmth / 100.0) * smoothstep(0.0, 0.15, grey);
    return vec4<f32>(from_display(mix(rgb, graded, params.amount / 100.0)), c.a);
}
