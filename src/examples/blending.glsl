// LearnOpenGL Advanced OpenGL / Blending.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs textured
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

// Opaque objects and blended windows both return the complete RGBA texel.
// Whether blending happens is pipeline state, not shader state.
@fs sampled
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv);
}
@end

// Grass is either visible or absent. Discarded fragments update neither the
// colour buffer nor the depth buffer, so the rectangular quad disappears.
@fs cutout
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    vec4 texel = texture(sampler2D(tex, smp), uv);
    if (texel.a < 0.1) {
        discard;
    }
    frag_color = texel;
}
@end

@program sampled textured sampled
@program cutout textured cutout
