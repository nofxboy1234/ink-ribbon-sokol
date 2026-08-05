// LearnOpenGL "Materials": separate surface and light properties.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs object_vs
layout(binding = 0) uniform object_vs_params {
    mat4 mvp;
    mat4 model;
};

in vec4 position;
in vec3 normal0;
out vec3 fragment_position;
out vec3 world_normal;

void main() {
    gl_Position = mvp * position;
    fragment_position = (model * position).xyz;
    world_normal = mat3(transpose(inverse(model))) * normal0;
}
@end

@fs object_fs
// sokol-shdc turns this block into a typed Zig struct. Vec4 fields keep every
// member naturally 16-byte aligned on all supported graphics backends.
layout(binding = 1) uniform materials_fs_params {
    vec4 material_ambient;
    vec4 material_diffuse;
    vec4 material_specular;
    vec4 material_properties; // x stores shininess
    vec4 light_position;
    vec4 light_ambient;
    vec4 light_diffuse;
    vec4 light_specular;
    vec4 view_position;
};

in vec3 fragment_position;
in vec3 world_normal;
out vec4 frag_color;

void main() {
    vec3 normal = normalize(world_normal);
    vec3 light_direction = normalize(light_position.xyz - fragment_position);
    vec3 view_direction = normalize(view_position.xyz - fragment_position);
    vec3 reflected_direction = reflect(-light_direction, normal);

    // Each part of the light interacts with the matching part of the material.
    vec3 ambient = light_ambient.rgb * material_ambient.rgb;

    float diffuse_amount = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = light_diffuse.rgb * (diffuse_amount * material_diffuse.rgb);

    float shininess = material_properties.x;
    float specular_amount = pow(max(dot(view_direction, reflected_direction), 0.0), shininess);
    vec3 specular = light_specular.rgb * (specular_amount * material_specular.rgb);

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
