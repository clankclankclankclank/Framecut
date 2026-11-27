// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { feather: f32, centre_x: f32, centre_y: f32 }

fn transition(uv: vec2<f32>, progress: f32) -> vec4<f32> {
    let centre = vec2<f32>(params.centre_x, params.centre_y) / 100.0;
    let aspect = frame.size / frame.size.y;
    let max_distance = length(max(centre, 1.0 - centre) * aspect);
    let feather = params.feather / 100.0 * 0.4;
    let radius = mix(-feather, max_distance + feather, smoothstep(0.0, 1.0, progress));
    let distance = length((uv - centre) * aspect);
    let weight = 1.0 - smoothstep(radius - feather, radius + feather, distance);
    let a = from_at(uv);
    let b = to_at(uv);
    let mixed = mix(vec4<f32>(a.rgb * a.a, a.a), vec4<f32>(b.rgb * b.a, b.a), weight);
    return vec4<f32>(mixed.rgb / max(mixed.a, 1e-6), mixed.a);
}
