// LearnOpenGL "Lighting maps": diffuse and specular textures.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs object_vs
layout(binding = 0) uniform object_vs_params {
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

@fs object_fs
layout(binding = 1) uniform lighting_fs_params {
    vec4 material_properties; // x stores shininess
    vec4 light_position;
    vec4 light_ambient;
    vec4 light_diffuse;
    vec4 light_specular;
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
    vec3 normal = normalize(world_normal);
    vec3 light_direction = normalize(light_position.xyz - fragment_position);
    vec3 view_direction = normalize(view_position.xyz - fragment_position);
    vec3 reflected_direction = reflect(-light_direction, normal);

    // The diffuse map supplies a different wood/metal body color at every
    // fragment. Ambient uses the same surface color, as in the chapter.
    vec3 diffuse_sample = texture(sampler2D(diffuse_texture, texture_sampler), uv).rgb;
    vec3 ambient = light_ambient.rgb * diffuse_sample;

    float diffuse_amount = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = light_diffuse.rgb * diffuse_amount * diffuse_sample;

    // Bright texels in the specular map permit a highlight; black wood texels
    // suppress it. This makes the steel frame shinier than the wooden boards.
    float shininess = material_properties.x;
    float specular_amount = pow(max(dot(view_direction, reflected_direction), 0.0), shininess);
    vec3 specular_sample = texture(sampler2D(specular_texture, texture_sampler), uv).rgb;
    vec3 specular = light_specular.rgb * specular_amount * specular_sample;

    frag_color = vec4(ambient + diffuse + specular, 1.0);
}
@end

@vs lamp_vs
layout(binding = 2) uniform lamp_vs_params {
    mat4 mvp;
};

in vec4 position;

void main() {
    gl_Position = mvp * position;
}
@end

@fs lamp_fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0);
}
@end

@program object object_vs object_fs
@program lamp lamp_vs lamp_fs
