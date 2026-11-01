shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D texture_grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_dirt : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_rock : source_color, filter_linear_mipmap, repeat_enable;

uniform vec4 grass_tint : source_color = vec4(0.52, 0.62, 0.40, 1.0);
uniform vec4 dirt_tint : source_color = vec4(0.72, 0.58, 0.42, 1.0);
uniform vec4 path_tint : source_color = vec4(0.75, 0.62, 0.46, 1.0);

uniform float uv_scale_grass : hint_range(1.0, 100.0) = 38.0;
uniform float uv_scale_dirt : hint_range(1.0, 100.0) = 30.0;
uniform float uv_scale_rock : hint_range(1.0, 100.0) = 28.0;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.88;

// Procedural pseudo-noise hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(100.0);
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    // Sample texture layers with independent UV tiling
    vec4 col_grass = texture(texture_grass, world_pos * (uv_scale_grass * 0.01)) * grass_tint;
    vec4 col_dirt = texture(texture_dirt, world_pos * (uv_scale_dirt * 0.01)) * dirt_tint;
    vec4 col_rock = texture(texture_rock, world_pos * (uv_scale_rock * 0.01)) * path_tint;
    
    // Low-frequency noise for organic dirt/soil patches and forest clearings
    float patch_noise = fbm(world_pos * 0.045 + vec2(42.0, 18.0));
    float patch_mask = smoothstep(0.40, 0.70, patch_noise) * 0.55;
    
    // High-frequency detail noise to break edge repetition and add soil texture
    float detail_noise = fbm(world_pos * 0.28);
    
    // Organic trail / path: natural winding forest dirt & mud trail
    // Center follows a natural curve through the terrain perturbed by multi-octave noise
    float trail_center_x = sin(world_pos.y * 0.08) * 4.5 + cos(world_pos.y * 0.035) * 3.5 - 2.0;
    float trail_noise = fbm(world_pos * 0.12) * 2.2;
    float dist_to_trail = abs(world_pos.x - (trail_center_x + trail_noise));
    // Soft, natural falloff into dark mud and damp earth (no hard checkered edges)
    float trail_mask = 1.0 - smoothstep(1.4, 3.4, dist_to_trail);
    
    // Trail composition: dark moist mud along edges, natural packed dirt along center
    vec3 mud_color = col_dirt.rgb * 0.82;
    vec3 trail_core = mix(col_dirt.rgb, col_rock.rgb, 0.65);
    float core_factor = 1.0 - smoothstep(0.6, 2.2, dist_to_trail);
    vec3 path_composite = mix(mud_color, trail_core, core_factor);
    
    // Blend: Base rich olive grass -> Earth clearings -> Organic dirt trail
    vec3 blended = mix(col_grass.rgb, col_dirt.rgb, patch_mask);
    blended = mix(blended, path_composite, trail_mask * 0.85);
    
    // Natural micro-variation shading for rich dark forest floor
    blended *= (0.92 + 0.16 * detail_noise);
    
    ALBEDO = blended;
    ROUGHNESS = roughness_val;
    SPECULAR = 0.05;
}
