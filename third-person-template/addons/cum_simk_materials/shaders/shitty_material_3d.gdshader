shader_type spatial;
render_mode diffuse_lambert_wrap, cull_disabled;

#include "shitty_material_3d_utils.gdshaderinc"

group_uniforms texture;
uniform bool use_albedo_texture = true;
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 uv_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv_offset = vec3(0.0, 0.0, 0.0);
uniform float uv_rotation : hint_range(0.0, 360.0) = 0.0;
uniform float metalness : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

group_uniforms decal;
uniform bool use_decal = false;
uniform sampler2D decal_texture : source_color, filter_nearest;
uniform float decal_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float decal_scale : hint_range(0.1, 100.0) = 1.0;

group_uniforms grain;
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.003;
uniform float grain_size : hint_range(1.0, 10.0) = 1.0;
uniform float grain_fps : hint_range(1.0, 60.0) = 4.0;
uniform float grain_threshold : hint_range(0.0, 1.0) = 0.2;

group_uniforms color;
uniform float wash_out : hint_range(0.0, 1.0) = 0.75;

group_uniforms chromatic_aberration;
uniform float aberration_strength : hint_range(0.0, 0.1) = 0.05;

group_uniforms lighting;
uniform float light_bands : hint_range(1.0, 16.0) = 16.0;
uniform float dither_size : hint_range(1.0, 4.0) = 1.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    float rad = radians(uv_rotation);
    vec2 sin_cos = vec2(sin(rad), cos(rad));
    mat2 rotation_matrix = mat2(vec2(sin_cos.y, -sin_cos.x), vec2(sin_cos.x, sin_cos.y));
    vec2 rotated_uv = (UV - 0.5) * rotation_matrix + 0.5;
    
    vec2 mapped_uv = rotated_uv * uv_scale.xy + uv_offset.xy;
    
    vec3 base_color;
    
    if (use_albedo_texture) {
        vec2 center_dist = SCREEN_UV - 0.5;
        vec2 aberration = center_dist * aberration_strength;
        
        float r = texture(albedo_texture, mapped_uv + aberration).r;
        float g = texture(albedo_texture, mapped_uv).g;
        float b = texture(albedo_texture, mapped_uv - aberration).b;
        base_color = vec3(r, g, b) * albedo_color.rgb * COLOR.rgb;
    } else {
        base_color = albedo_color.rgb * COLOR.rgb;
    }
    
    if (use_decal) {
        // Apply independent scale to decal UVs
        vec2 decal_uv = rotated_uv * decal_scale + uv_offset.xy;
        vec4 decal_tex = texture(decal_texture, decal_uv);
        base_color = mix(base_color, decal_tex.rgb, decal_tex.a * decal_intensity);
    }
    
    float res_lum = dot(base_color, vec3(0.299, 0.587, 0.114));
    vec3 final_color = mix(base_color, vec3(res_lum), wash_out);

    float snapped_time = floor(TIME * grain_fps) / grain_fps;
    vec2 grain_uv = floor((SCREEN_UV * VIEWPORT_SIZE) / grain_size);
    
    float mask = get_grain_mask(res_lum, grain_threshold);
    ALBEDO = apply_grain(final_color, grain_uv, snapped_time, grain_intensity, mask);

    ROUGHNESS = roughness;
    METALLIC = metalness;
}

void light() {
    vec2 dither_uv = floor((SCREEN_UV * VIEWPORT_SIZE) / dither_size);
    float dither_val = get_dither_4x4(dither_uv);
    
    float shadow_factor = clamp(dot(NORMAL, LIGHT) * ATTENUATION, 0.0, 1.0);
    float final_diffuse = floor(shadow_factor * light_bands + dither_val - 0.25) / light_bands;
    final_diffuse = clamp(final_diffuse, 0.0, 1.0);
    
    float snapped_time = floor(TIME * grain_fps) / grain_fps;
    vec2 grain_uv = floor((SCREEN_UV * VIEWPORT_SIZE) / grain_size);
    
    float mask = get_grain_mask(final_diffuse, grain_threshold);
    vec3 shadow_grain = apply_grain(vec3(0.0), grain_uv, snapped_time, grain_intensity, mask);
    
    vec3 ambient_contribution = shadow_color.rgb * (1.0 - final_diffuse);
    
    DIFFUSE_LIGHT += (LIGHT_COLOR * final_diffuse) + ambient_contribution + shadow_grain;
}