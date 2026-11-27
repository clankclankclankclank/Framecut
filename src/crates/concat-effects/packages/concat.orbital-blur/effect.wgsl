// SPDX-License-Identifier: AGPL-3.0-or-later

struct Params { spin: f32, zoom: f32, centre_x: f32, centre_y: f32 }

fn effect(uv: vec2<f32>) -> vec4<f32> {
    if (params.spin == 0.0 && params.zoom == 0.0) { return sample(uv); }
    let centre = vec2<f32>(params.centre_x, params.centre_y) / 100.0;
    let d = (uv - centre) * frame.size;
    var sum = vec4<f32>(0.0);
    for (var tap = 0; tap < 16; tap++) {
        let t = f32(tap) / 15.0 - 0.5;
        let angle = radians(params.spin) * t;
        let cs = vec2<f32>(cos(angle), sin(angle));
        let ray = vec2<f32>(d.x * cs.x - d.y * cs.y, d.x * cs.y + d.y * cs.x);
        let c = sample(centre + ray / frame.size * (1.0 + t * params.zoom / 100.0));
        sum += vec4<f32>(c.rgb * c.a, c.a);
    }
    return vec4<f32>(sum.rgb / max(sum.a, 1e-6), sum.a / 16.0);
}
