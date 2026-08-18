//------------------------------------------------------------------------------
// Shader code for the textured-cube example.
//------------------------------------------------------------------------------
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding=0) uniform vs_params {
    mat4 mvp;
};

in vec4 pos;
in vec4 color0;
in vec2 texcoord0;

out vec4 color;
out vec2 uv;

void main() {
    gl_Position = mvp * pos;
    color = color0;

    // The vertex coordinates cover 0..1. Multiplying them by five makes the
    // default repeating sampler show five copies of the checkerboard per face.
    uv = texcoord0 * 5.0;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec4 color;
in vec2 uv;
out vec4 frag_color;

void main() {
    // `tex` selects the image, `smp` supplies filtering/wrapping rules, and
    // `uv` selects the location to read. Tint the sampled texel by the
    // interpolated per-vertex colour.
    frag_color = texture(sampler2D(tex, smp), uv) * color;
}
@end

@program texcube vs fs
