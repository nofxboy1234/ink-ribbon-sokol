// LearnOpenGL Advanced OpenGL / Depth testing.
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

@fs fs
// x: 0 for textured colour, 1 for the depth visualization
// y: projection near plane
// z: projection far plane
layout(binding=1) uniform fs_params {
    vec4 depth_options;
};

layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
out vec4 frag_color;

float linearize_depth(float depth, float near_plane, float far_plane) {
    // gl_FragCoord.z is in the depth buffer's 0..1 range. Convert it back
    // to NDC's -1..1 range, then undo the projection's non-linear mapping.
    float ndc_z = depth * 2.0 - 1.0;
    return (2.0 * near_plane * far_plane)
        / (far_plane + near_plane - ndc_z * (far_plane - near_plane));
}

void main() {
    if (depth_options.x > 0.5) {
        float linear_depth = linearize_depth(
            gl_FragCoord.z,
            depth_options.y,
            depth_options.z
        );
        float visible_depth = linear_depth / depth_options.z;
        frag_color = vec4(vec3(visible_depth), 1.0);
    } else {
        frag_color = texture(sampler2D(tex, smp), uv);
    }
}
@end

@program depth_testing vs fs
