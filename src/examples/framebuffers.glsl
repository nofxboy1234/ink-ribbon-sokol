// LearnOpenGL Advanced OpenGL / Framebuffers.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

// First pass: draw the ordinary 3D scene into an offscreen colour image.
@vs scene_vs
layout(binding=0) uniform scene_vs_params {
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

@fs scene_fs
layout(binding=0) uniform texture2D object_tex;
layout(binding=0) uniform sampler object_smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(object_tex, object_smp), uv);
}
@end

@program scene scene_vs scene_fs

// Second pass: draw one full-screen quad and sample the completed first pass.
// post_options.x chooses the effect; .y and .z contain one texture pixel in UV
// units, allowing the 3x3 kernels to sample the eight neighbouring pixels.
@vs screen_vs
in vec2 position;
in vec2 texcoord0;
out vec2 uv;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = texcoord0;
}
@end

@fs screen_fs
layout(binding=0) uniform screen_fs_params {
    vec4 post_options;
};
layout(binding=0) uniform texture2D scene_tex;
layout(binding=0) uniform sampler scene_smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    vec3 center = texture(sampler2D(scene_tex, scene_smp), uv).rgb;
    int effect = int(post_options.x + 0.5);

    // 0: no post-processing.
    if (effect == 0) {
        frag_color = vec4(center, 1.0);
        return;
    }

    // 1: inversion. Each channel becomes its distance from white.
    if (effect == 1) {
        frag_color = vec4(vec3(1.0) - center, 1.0);
        return;
    }

    // 2: weighted grayscale. Human vision is most sensitive to green.
    if (effect == 2) {
        float brightness = dot(center, vec3(0.2126, 0.7152, 0.0722));
        frag_color = vec4(vec3(brightness), 1.0);
        return;
    }

    vec2 pixel = post_options.yz;
    vec3 top_left     = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2(-1.0,  1.0)).rgb;
    vec3 top          = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2( 0.0,  1.0)).rgb;
    vec3 top_right    = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2( 1.0,  1.0)).rgb;
    vec3 left         = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2(-1.0,  0.0)).rgb;
    vec3 right        = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2( 1.0,  0.0)).rgb;
    vec3 bottom_left  = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2(-1.0, -1.0)).rgb;
    vec3 bottom       = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2( 0.0, -1.0)).rgb;
    vec3 bottom_right = texture(sampler2D(scene_tex, scene_smp), uv + pixel * vec2( 1.0, -1.0)).rgb;

    vec3 result;
    if (effect == 3) {
        // Sharpen kernel:
        // -1 -1 -1
        // -1  9 -1
        // -1 -1 -1
        result = center * 9.0 - top_left - top - top_right - left - right
               - bottom_left - bottom - bottom_right;
    } else if (effect == 4) {
        // Gaussian-like blur kernel:
        // 1 2 1
        // 2 4 2  / 16
        // 1 2 1
        result = (top_left + top * 2.0 + top_right
                + left * 2.0 + center * 4.0 + right * 2.0
                + bottom_left + bottom * 2.0 + bottom_right) / 16.0;
    } else {
        // Edge-detection kernel:
        //  1  1  1
        //  1 -8  1
        //  1  1  1
        result = top_left + top + top_right + left + right
               + bottom_left + bottom + bottom_right - center * 8.0;
    }
    frag_color = vec4(result, 1.0);
}
@end

@program screen screen_vs screen_fs
