@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs house_vs
in vec2 position;
in vec3 color0;
out vec3 color;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    color = color0;
}
@end

@fs color_fs
in vec3 color;
out vec4 frag_color;

void main() {
    frag_color = vec4(color, 1.0);
}
@end

@vs mesh_vs
layout(binding = 0) uniform mesh_vs_params {
    mat4 mvp;
    float explode_distance;
};

in vec3 position;
in vec3 normal;
out vec3 color;

void main() {
    // Every corner of one cube face has the same face normal. Moving all of
    // them by the same vector keeps the face together while separating faces.
    vec3 exploded_position = position + normal * explode_distance;
    gl_Position = mvp * vec4(exploded_position, 1.0);
    color = 0.35 + 0.65 * abs(normal);
}
@end

@vs line_vs
layout(binding = 0) uniform line_vs_params {
    mat4 mvp;
};

in vec3 position;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
}
@end

@fs line_fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0, 0.75, 0.1, 1.0);
}
@end

@program houses house_vs color_fs
@program mesh mesh_vs color_fs
@program normal_lines line_vs line_fs
