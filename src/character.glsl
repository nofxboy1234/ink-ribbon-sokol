@header const math = @import("../math.zig")
@ctype mat4 math.Mat4
@ctype vec3 math.Vec3

@vs vs
layout(binding = 0) uniform vs_params {
    mat4 view_projection;
};

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec4 inst_x;
layout(location = 3) in vec4 inst_y;
layout(location = 4) in vec4 inst_z;
layout(location = 5) in vec4 inst_color;

out vec3 world_normal;
out vec3 color;

void main() {
    vec4 world_position = vec4(dot(position, inst_x), dot(position, inst_y), dot(position, inst_z), 1.0);
    vec4 local_normal = vec4(normal, 0.0);
    world_normal = vec3(dot(local_normal, inst_x), dot(local_normal, inst_y), dot(local_normal, inst_z));
    color = inst_color.rgb;
    gl_Position = view_projection * world_position;
}
@end

@fs fs
layout(binding = 1) uniform fs_params {
    vec3 light_direction;
};

in vec3 world_normal;
in vec3 color;
out vec4 frag_color;

void main() {
    float diffuse = max(dot(normalize(world_normal), normalize(light_direction)), 0.0);
    vec3 linear_color = color * (0.25 + 0.75 * diffuse);
    frag_color = vec4(pow(linear_color, vec3(1.0 / 2.2)), 1.0);
}
@end

@program character vs fs
