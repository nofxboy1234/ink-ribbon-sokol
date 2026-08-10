// LearnOpenGL Advanced OpenGL / Face culling.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding=0) uniform vs_params {
    mat4 mvp;
};

in vec3 position;
in vec3 color0;
out vec3 color;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    color = color0;
}
@end

@fs fs
in vec3 color;
out vec4 frag_color;

void main() {
    frag_color = vec4(color, 1.0);
}
@end

@program face_culling vs fs
