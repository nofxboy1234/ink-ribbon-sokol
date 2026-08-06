// LearnOpenGL "Light casters": a smooth-edged flashlight/spotlight.
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
    vec4 material_properties; // x: shininess
    vec4 light_position;
    vec4 light_direction;
    vec4 light_ambient;
    vec4 light_diffuse;
    vec4 light_specular;
    vec4 attenuation_terms;   // x: constant, y: linear, z: quadratic
    vec4 spotlight_cutoffs;   // x: cos(inner angle), y: cos(outer angle)
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
    // This points from the fragment back toward the flashlight.
    vec3 to_light = normalize(light_position.xyz - fragment_position);
    vec3 to_viewer = normalize(view_position.xyz - fragment_position);
    vec3 reflected_light = reflect(-to_light, normal);

    vec3 diffuse_sample = texture(sampler2D(diffuse_texture, texture_sampler), uv).rgb;
    vec3 specular_sample = texture(sampler2D(specular_texture, texture_sampler), uv).rgb;

    vec3 ambient = light_ambient.rgb * diffuse_sample;
    float diffuse_amount = max(dot(normal, to_light), 0.0);
    vec3 diffuse = light_diffuse.rgb * diffuse_amount * diffuse_sample;

    float shininess = material_properties.x;
    float specular_amount = pow(max(dot(to_viewer, reflected_light), 0.0), shininess);
    vec3 specular = light_specular.rgb * specular_amount * specular_sample;

    // A point/spot light becomes weaker as its distance d increases:
    //               1
    //   ---------------------------
    //   constant + linear*d + quadratic*d*d
    float distance_to_light = length(light_position.xyz - fragment_position);
    float attenuation = 1.0 / (
        attenuation_terms.x +
        attenuation_terms.y * distance_to_light +
        attenuation_terms.z * distance_to_light * distance_to_light
    );

    // Both vectors point away from the flashlight here, so their dot product
    // measures how close this fragment is to the middle of its cone.
    float theta = dot(to_light, normalize(-light_direction.xyz));
    float epsilon = spotlight_cutoffs.x - spotlight_cutoffs.y;
    float intensity = clamp((theta - spotlight_cutoffs.y) / epsilon, 0.0, 1.0);

    // The cone affects direct light. Ambient remains as the faint illumination
    // outside the beam, matching the final LearnOpenGL example.
    ambient *= attenuation;
    diffuse *= attenuation * intensity;
    specular *= attenuation * intensity;
    frag_color = vec4(ambient + diffuse + specular, 1.0);
}
@end

@program object object_vs object_fs
