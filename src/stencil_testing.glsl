// LearnOpenGL Advanced OpenGL / Stencil testing.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding=0) uniform vs_params {
    mat4 mvp;
};

in vec3 position;
in vec2 texcoord0;
out vec2 uv;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    uv = texcoord0;
}
@end

@fs textured_fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv);
}
@end

@fs outline_fs
in vec2 uv;
out vec4 frag_color;

void main() {
    // The solid teal colour used for the enlarged outline mesh.
    frag_color = vec4(0.04, 0.28, 0.26, 1.0);
}
@end

@program textured vs textured_fs
@program outline vs outline_fs
