// LearnOpenGL Advanced OpenGL / Anti Aliasing.
//
// This file contains two small shader programs, one for each render pass:
//
//   scene   : turn rectangle vertices into green pixels in an offscreen image
//   display : read that completed image and copy it onto the window
//
// MSAA itself is not implemented by shader code. The rasterizer performs its
// extra coverage tests because Zig configured a multisampled image and pipeline.

// PASS 1: draw high-contrast, slanted geometry. Jagged edges are deliberately
// easy to see when the render target has only one coverage sample per pixel.
@vs scene_vs
layout(binding=0) uniform scene_vs_params {
    // x = cos(angle), y = sin(angle), z = height/width, w = unused.
    // A vec4 is used because shader uniform layouts prefer aligned 16-byte data.
    vec4 transform;
};

// `position` comes from SceneVertex.position in vertex-buffer slot 0.
in vec2 position;

void main() {
    // Standard 2D rotation. Cosine and sine mix the old X and Y contributions
    // into a new position around the origin (the rectangle's center).
    vec2 rotated = vec2(
        position.x * transform.x - position.y * transform.y,
        position.x * transform.y + position.y * transform.x
    );
    // Clip space maps to a rectangular window. Correct X for its aspect ratio
    // so resizing the window does not distort the rectangle.
    rotated.x *= transform.z;
    // The vertex shader's required output is a clip-space vec4. This scene is
    // flat at Z=0, and W=1 means this is an ordinary position.
    gl_Position = vec4(rotated, 0.0, 1.0);
}
@end

// Rasterization happens between scene_vs and scene_fs. It decides which pixel
// samples the two triangles cover. With MSAA it tests four places per pixel.
@fs scene_fs
out vec4 frag_color;

void main() {
    // Every covered fragment uses the same opaque green RGBA color.
    frag_color = vec4(0.2, 0.85, 0.35, 1.0);
}
@end

@program scene scene_vs scene_fs

// PASS 2: copy the ordinary one-sample texture to the window. In MSAA mode this
// texture contains the result of resolving the four samples from pass 1.
@vs display_vs
// These inputs describe two triangles covering all of clip space.
in vec2 position;
in vec2 texcoord0;
// `out` sends the UV through rasterization to display_fs as its matching `in`.
out vec2 uv;

void main() {
    // These positions are already in clip space, so no camera or matrix is used.
    gl_Position = vec4(position, 0.0, 1.0);
    // Pass the texture coordinate through unchanged. The rasterizer interpolates
    // it across the full-screen triangles.
    uv = texcoord0;
}
@end

@fs display_fs
// An image stores texels; a sampler defines how coordinates read those texels.
// Sokol binds both using the generated VIEW_ and SMP_ slot constants.
layout(binding=0) uniform texture2D scene_tex;
layout(binding=0) uniform sampler scene_smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    // Look up the offscreen color at this screen position and output it. The
    // shader does not know whether that texture came from mode 1 or an MSAA
    // resolve; both are ordinary texture2D images by this stage.
    frag_color = texture(sampler2D(scene_tex, scene_smp), uv);
}
@end

@program display display_vs display_fs
