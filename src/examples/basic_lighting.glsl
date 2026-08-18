// LearnOpenGL "Basic Lighting": per-fragment Phong lighting in world space.
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

    // Lighting is calculated in world space, so pass the world position of each
    // vertex to the fragment shader. The GPU interpolates it across triangles.
    fragment_position = (model * position).xyz;

    // The inverse-transpose normal matrix keeps normals perpendicular after a
    // non-uniform model scale. For this identity model it changes nothing, but
    // including it demonstrates the chapter's generally correct method.
    world_normal = mat3(transpose(inverse(model))) * normal0;
}
@end

@fs object_fs
layout(binding = 1) uniform object_fs_params {
    vec4 object_color;
    vec4 light_color;
    vec4 light_position;
    vec4 view_position;
};

in vec3 fragment_position;
in vec3 world_normal;
out vec4 frag_color;

void main() {
    vec3 normal = normalize(world_normal);

    // Ambient: a small constant approximation of indirect/scattered light.
    float ambient_strength = 0.1;
    vec3 ambient = ambient_strength * light_color.rgb;

    // Diffuse: brightest when the surface normal points directly at the light.
    vec3 light_direction = normalize(light_position.xyz - fragment_position);
    float diffuse_amount = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = diffuse_amount * light_color.rgb;

    // Specular: a shiny highlight where the reflected light points at the eye.
    float specular_strength = 0.5;
    vec3 view_direction = normalize(view_position.xyz - fragment_position);
    vec3 reflected_direction = reflect(-light_direction, normal);
    float specular_amount = pow(max(dot(view_direction, reflected_direction), 0.0), 32.0);
    vec3 specular = specular_strength * specular_amount * light_color.rgb;

    vec3 result = (ambient + diffuse + specular) * object_color.rgb;
    frag_color = vec4(result, 1.0);
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
