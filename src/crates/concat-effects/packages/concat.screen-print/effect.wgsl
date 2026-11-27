// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { amount: f32, pitch: f32, angle: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    let c = sample(uv);
    let d = (uv - vec2<f32>(0.5)) * frame.size;
    let t = radians(params.angle);
    let plane = vec2<f32>(cos(t) * d.x - sin(t) * d.y, sin(t) * d.x + cos(t) * d.y);
    let pitch = max(params.pitch * frame.size.y / 1080.0, 2.0);
    let dot_distance = length(fract(plane / pitch) - vec2<f32>(0.5));
    let coverage = 1.0 - clamp(luma(to_display(c.rgb)), 0.0, 1.0);
    let radius = sqrt(coverage) * 0.72;
    let ink = 1.0 - smoothstep(radius - 0.5 / pitch, radius + 0.5 / pitch, dot_distance);
    let print = mix(vec3<f32>(0.94, 0.85, 0.67), vec3<f32>(0.012, 0.03, 0.035), ink);
    return vec4<f32>(mix(c.rgb, print, params.amount / 100.0), c.a);
}
