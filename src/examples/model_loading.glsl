// LearnOpenGL Model Loading: imported position, normal, UV, and material maps.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding = 0) uniform vs_params {
    mat4 mvp;
    mat4 model;
};

in vec4 position;
in vec3 normal0;
in vec2 texcoord0;
out vec3 fragment_position;
out vec3 world_normal;
out vec2 uv;

void main() {
    gl_Position = mvp * position;
    fragment_position = (model * position).xyz;
    world_normal = mat3(transpose(inverse(model))) * normal0;
    uv = texcoord0;
}
@end

@fs fs
layout(binding = 1) uniform fs_params {
    vec4 light_position;
    vec4 view_position;
};

layout(binding = 0) uniform texture2D diffuse_texture;
layout(binding = 1) uniform texture2D specular_texture;
layout(binding = 0) uniform sampler texture_sampler;

in vec3 fragment_position;
in vec3 world_normal;
in vec2 uv;
out vec4 frag_color;

void main() {
    vec3 material_color = texture(sampler2D(diffuse_texture, texture_sampler), uv).rgb;
    vec3 specular_color = texture(sampler2D(specular_texture, texture_sampler), uv).rgb;
    vec3 normal = normalize(world_normal);
    vec3 to_light = normalize(light_position.xyz - fragment_position);
    vec3 to_viewer = normalize(view_position.xyz - fragment_position);

    vec3 ambient = 0.1 * material_color;
    float diffuse_amount = max(dot(normal, to_light), 0.0);
    vec3 diffuse = diffuse_amount * material_color;
    vec3 reflected_light = reflect(-to_light, normal);
    float specular_amount = pow(max(dot(to_viewer, reflected_light), 0.0), 32.0);
    vec3 specular = specular_amount * specular_color;
    frag_color = vec4(ambient + diffuse + specular, 1.0);
}
@end

@program model vs fs
