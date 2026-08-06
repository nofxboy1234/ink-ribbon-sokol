// LearnOpenGL "Multiple lights": add six independent light contributions.
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
    vec4 material_properties;       // x: shininess

    vec4 directional_direction;
    vec4 directional_ambient;
    vec4 directional_diffuse;
    vec4 directional_specular;

    // All four point lights use the same colors and attenuation values, so
    // only their positions need an array.
    vec4 point_positions[4];
    vec4 point_ambient;
    vec4 point_diffuse;
    vec4 point_specular;
    vec4 point_attenuation;         // x: constant, y: linear, z: quadratic

    vec4 spotlight_position;
    vec4 spotlight_direction;
    vec4 spotlight_ambient;
    vec4 spotlight_diffuse;
    vec4 spotlight_specular;
    vec4 spotlight_attenuation;
    vec4 spotlight_cutoffs;         // x: inner cosine, y: outer cosine

    vec4 view_position;
};

layout(binding = 0) uniform texture2D diffuse_texture;
layout(binding = 1) uniform texture2D specular_texture;
layout(binding = 0) uniform sampler texture_sampler;

in vec3 fragment_position;
in vec3 world_normal;
in vec2 uv;
out vec4 frag_color;

vec3 calculateDirectionalLight(
    vec3 normal, vec3 to_viewer, vec3 surface_color, vec3 specular_color
) {
    vec3 to_light = normalize(-directional_direction.xyz);
    float diffuse_amount = max(dot(normal, to_light), 0.0);
    vec3 reflected_light = reflect(-to_light, normal);
    float specular_amount = pow(
        max(dot(to_viewer, reflected_light), 0.0), material_properties.x
    );

    vec3 ambient = directional_ambient.rgb * surface_color;
    vec3 diffuse = directional_diffuse.rgb * diffuse_amount * surface_color;
    vec3 specular = directional_specular.rgb * specular_amount * specular_color;
    return ambient + diffuse + specular;
}

vec3 calculatePointLight(
    vec3 light_position, vec3 normal, vec3 to_viewer,
    vec3 surface_color, vec3 specular_color
) {
    vec3 to_light = normalize(light_position - fragment_position);
    float diffuse_amount = max(dot(normal, to_light), 0.0);
    vec3 reflected_light = reflect(-to_light, normal);
    float specular_amount = pow(
        max(dot(to_viewer, reflected_light), 0.0), material_properties.x
    );

    float distance_to_light = length(light_position - fragment_position);
    float attenuation = 1.0 / (
        point_attenuation.x +
        point_attenuation.y * distance_to_light +
        point_attenuation.z * distance_to_light * distance_to_light
    );

    vec3 ambient = point_ambient.rgb * surface_color;
    vec3 diffuse = point_diffuse.rgb * diffuse_amount * surface_color;
    vec3 specular = point_specular.rgb * specular_amount * specular_color;
    return (ambient + diffuse + specular) * attenuation;
}

vec3 calculateSpotlight(
    vec3 normal, vec3 to_viewer, vec3 surface_color, vec3 specular_color
) {
    vec3 to_light = normalize(spotlight_position.xyz - fragment_position);
    float diffuse_amount = max(dot(normal, to_light), 0.0);
    vec3 reflected_light = reflect(-to_light, normal);
    float specular_amount = pow(
        max(dot(to_viewer, reflected_light), 0.0), material_properties.x
    );

    float distance_to_light = length(spotlight_position.xyz - fragment_position);
    float attenuation = 1.0 / (
        spotlight_attenuation.x +
        spotlight_attenuation.y * distance_to_light +
        spotlight_attenuation.z * distance_to_light * distance_to_light
    );

    float theta = dot(to_light, normalize(-spotlight_direction.xyz));
    float epsilon = spotlight_cutoffs.x - spotlight_cutoffs.y;
    float intensity = clamp((theta - spotlight_cutoffs.y) / epsilon, 0.0, 1.0);

    vec3 ambient = spotlight_ambient.rgb * surface_color;
    vec3 diffuse = spotlight_diffuse.rgb * diffuse_amount * surface_color;
    vec3 specular = spotlight_specular.rgb * specular_amount * specular_color;
    return (ambient + diffuse + specular) * attenuation * intensity;
}

void main() {
    vec3 normal = normalize(world_normal);
    vec3 to_viewer = normalize(view_position.xyz - fragment_position);
    vec3 surface_color = texture(sampler2D(diffuse_texture, texture_sampler), uv).rgb;
    vec3 specular_color = texture(sampler2D(specular_texture, texture_sampler), uv).rgb;

    // THIS IS THE CHAPTER'S MAIN NEW IDEA:
    // each light independently returns a color contribution, and we add those
    // contributions together to get this fragment's final color.
    vec3 result = calculateDirectionalLight(
        normal, to_viewer, surface_color, specular_color
    );
    for (int index = 0; index < 4; index++) {
        result += calculatePointLight(
            point_positions[index].xyz,
            normal,
            to_viewer,
            surface_color,
            specular_color
        );
    }
    result += calculateSpotlight(
        normal, to_viewer, surface_color, specular_color
    );

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
