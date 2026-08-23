@header const math = @import("../math.zig")
@ctype mat4 math.Mat4
@ctype vec3 math.Vec3
@ctype vec4 math.Vec4
@ctype vec2 math.Vec2

@block shadow_util
// 5x5 PCF (percentage-closer filtering): average shadow lookups over a
// neighborhood to soften shadow edges instead of a hard single sample.
float sample_shadow_pcf(texture2D tex, sampler smp, vec3 position) {
    vec2 size = vec2(textureSize(sampler2DShadow(tex, smp), 0));
    float result = 0.0;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            result += texture(sampler2DShadow(tex, smp), vec3(position.xy + vec2(x, y) / size, position.z));
        }
    }
    return result / 25.0;
}
@end

@vs shadow_vs
@glsl_options fixup_clipspace
layout(binding = 0) uniform shadow_vs_params {
    mat4 light_view_projection;
};

// Renders the scene from the sun's point of view into the shadow map.
// inst_* vectors are the instanced transform basis (rotation + scale axes).
layout(location = 0) in vec4 position;
layout(location = 1) in vec4 inst_x;
layout(location = 2) in vec4 inst_y;
layout(location = 3) in vec4 inst_z;

void main() {
    // Transform the local vertex into world space using the instanced basis.
    vec4 world_position = vec4(dot(position, inst_x), dot(position, inst_y), dot(position, inst_z), 1.0);
    gl_Position = light_view_projection * world_position;
}
@end

@fs shadow_fs
// Nothing to shade: only depth is written to the shadow map.
void main() {}
@end

@program shadow shadow_vs shadow_fs

@vs display_vs
layout(binding = 0) uniform display_vs_params {
    mat4 view_projection;
    mat4 light_view_projection;
};

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec4 inst_x;
layout(location = 3) in vec4 inst_y;
layout(location = 4) in vec4 inst_z;
layout(location = 5) in vec4 inst_color;

out vec3 color;
out float alpha;
out vec4 light_position;
out vec3 world_position;
out vec3 world_normal;

void main() {
    // Local -> world position/normal via the instanced basis (same as shadow_vs).
    vec4 wp = vec4(dot(position, inst_x), dot(position, inst_y), dot(position, inst_z), 1.0);
    vec4 local_normal = vec4(normal, 0.0);
    world_normal = vec3(dot(local_normal, inst_x), dot(local_normal, inst_y), dot(local_normal, inst_z));
    world_position = wp.xyz;
    color = inst_color.rgb;
    alpha = inst_color.a;
    // Where this fragment is from the light's point of view (for shadow lookup).
    light_position = light_view_projection * wp;
    #if !SOKOL_GLSL
        // Fix coordinate-system mismatch for non-GL backends.
        light_position.y = -light_position.y;
    #endif
    gl_Position = view_projection * wp;
}
@end

@fs display_fs
@include_block shadow_util
layout(binding = 1) uniform display_fs_params {
    vec3 light_direction;
    vec3 eye_position;
    vec4 indoor_light_0;
    vec4 indoor_light_1;
    vec4 indoor_light_2;
    vec4 indoor_light_3;
    vec4 indoor_light_4;
    vec4 indoor_light_5;
    vec4 indoor_light_6;
    vec4 indoor_light_7;
};

layout(binding = 0) uniform texture2D shadow_map;
layout(binding = 0) uniform sampler shadow_sampler;

in vec3 color;
in float alpha;
in vec4 light_position;
in vec3 world_position;
in vec3 world_normal;
out vec4 frag_color;

// Point-light contribution: falls off with squared distance inside the
// fixture's radius (stored in .w), scaled by how much the surface faces it.
float indoor_light(vec4 fixture, vec3 normal) {
    vec3 to_light = fixture.xyz - world_position;
    float distance_squared = dot(to_light, to_light);
    float radius_squared = fixture.w * fixture.w;
    float attenuation = max(1.0 - distance_squared / radius_squared, 0.0);
    attenuation *= attenuation;
    return max(dot(normal, normalize(to_light)), 0.0) * attenuation;
}

void main() {
    vec3 n = normalize(world_normal);
    vec3 l = normalize(light_direction); // direction from surface TOWARD the sun
    float n_dot_l = dot(n, l); // > 0 = surface faces the sun
    float intensity = 0.12; // faint ambient so shadows aren't pitch black
    float specular = 0.0;

    if (n_dot_l > 0.0) {
        // Project fragment into shadow-map UV space, add a small bias to the
        // depth to avoid acne (self-shadowing), then sample the PCF shadow.
        vec3 projected = light_position.xyz / light_position.w;
        float bias = max(0.0001 * (1.0 - n_dot_l), 0.00001);
        vec3 shadow_position = vec3((projected.xy + 1.0) * 0.5, projected.z + bias);
        float shadow = sample_shadow_pcf(shadow_map, shadow_sampler, shadow_position);
        intensity += n_dot_l * shadow;

        // Blinn-style specular highlight: how closely the reflected light
        // aligns with the view direction (raised to 16 = tight, shiny spot).
        vec3 view_direction = normalize(eye_position - world_position);
        vec3 reflected = reflect(-l, n);
        specular = pow(max(dot(reflected, view_direction), 0.0), 16.0) * n_dot_l * shadow;
    }

    // A small fixed fixture set is cheaper and easier to reason about than a
    // general light manager at this blockout stage. The w component is radius.
    float warm = indoor_light(indoor_light_0, n) + indoor_light(indoor_light_1, n)
        + indoor_light(indoor_light_2, n) + indoor_light(indoor_light_3, n)
        + indoor_light(indoor_light_4, n) + indoor_light(indoor_light_5, n)
        + indoor_light(indoor_light_6, n) + indoor_light(indoor_light_7, n);
    vec3 indoor_tint = vec3(1.0, 0.78, 0.52); // warm orange for interior lights

    vec3 linear_color = vec3(specular) + intensity * color + warm * indoor_tint * color;
    // Gamma-correct: convert linear lighting result back to display space.
    frag_color = vec4(pow(linear_color, vec3(1.0 / 2.2)), alpha);
}
@end

@program display display_vs display_fs

@vs route_vs
layout(binding = 0) uniform route_vs_params {
    mat4 view_projection;
};

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 inst_x;
layout(location = 2) in vec4 inst_y;
layout(location = 3) in vec4 inst_z;
layout(location = 4) in vec4 inst_color;

out vec4 color;

void main() {
    vec4 world_position = vec4(dot(position, inst_x), dot(position, inst_y), dot(position, inst_z), 1.0);
    color = inst_color;
    gl_Position = view_projection * world_position;
}
@end

@fs route_fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program route route_vs route_fs

@vs reticle_vs
@glsl_options fixup_clipspace
out vec2 uv;

void main() {
    vec2 positions[3] = vec2[3](
        vec2(-1.0, -1.0),
        vec2( 3.0, -1.0),
        vec2(-1.0,  3.0)
    );
    vec2 position = positions[gl_VertexIndex];
    uv = position * 0.5 + 0.5;
    gl_Position = vec4(position, 0.0, 1.0);
}
@end

@fs reticle_fs
layout(binding = 2) uniform reticle_fs_params {
    vec2 resolution;
    vec4 color;
    vec4 geometry; // inner gap, bar length, thickness, dot radius (pixels)
};

in vec2 uv;
out vec4 frag_color;

float box_mask(vec2 point, vec2 half_size) {
    vec2 delta = abs(point) - half_size;
    float distance = length(max(delta, 0.0)) + min(max(delta.x, delta.y), 0.0);
    return 1.0 - smoothstep(-0.5, 1.0, distance);
}

void main() {
    vec2 point = (uv - 0.5) * resolution;
    float gap = geometry.x;
    float length_px = geometry.y;
    float thickness = geometry.z;
    float dot_radius = geometry.w;
    float horizontal_offset = gap + length_px * 0.5;
    float vertical_offset = gap + length_px * 0.5;
    float mask = 1.0 - smoothstep(dot_radius - 0.75, dot_radius + 0.75, length(point));
    mask = max(mask, box_mask(point - vec2(-horizontal_offset, 0.0), vec2(length_px * 0.5, thickness * 0.5)));
    mask = max(mask, box_mask(point - vec2( horizontal_offset, 0.0), vec2(length_px * 0.5, thickness * 0.5)));
    mask = max(mask, box_mask(point - vec2(0.0, -vertical_offset), vec2(thickness * 0.5, length_px * 0.5)));
    frag_color = vec4(color.rgb, color.a * mask);
}
@end

@program reticle reticle_vs reticle_fs
