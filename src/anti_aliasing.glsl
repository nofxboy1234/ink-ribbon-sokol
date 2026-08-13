// LearnOpenGL Advanced OpenGL / Anti Aliasing.

// Pass 1 draws high-contrast, slanted geometry. Jagged edges are deliberately
// easy to see when the render target has only one coverage sample per pixel.
@vs scene_vs
layout(binding=0) uniform scene_vs_params {
    vec4 transform; // cos(angle), sin(angle), inverse aspect, unused
};

in vec2 position;

void main() {
    vec2 rotated = vec2(
        position.x * transform.x - position.y * transform.y,
        position.x * transform.y + position.y * transform.x
    );
    rotated.x *= transform.z;
    gl_Position = vec4(rotated, 0.0, 1.0);
}
@end

@fs scene_fs
out vec4 frag_color;

void main() {
    frag_color = vec4(0.2, 0.85, 0.35, 1.0);
}
@end

@program scene scene_vs scene_fs

// Pass 2 copies the ordinary, resolved texture to the window.
@vs display_vs
in vec2 position;
in vec2 texcoord0;
out vec2 uv;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = texcoord0;
}
@end

@fs display_fs
layout(binding=0) uniform texture2D scene_tex;
layout(binding=0) uniform sampler scene_smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(scene_tex, scene_smp), uv);
}
@end

@program display display_vs display_fs
