@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs cube_vs
layout(binding = 0) uniform cube_vs_params {
    mat4 mvp;
};

in vec3 position;

// An interface block groups values travelling to the fragment shader.
out VS_OUT {
    vec3 local_position;
} vs_out;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    vs_out.local_position = position;
}
@end

@fs cube_fs
layout(binding = 1) uniform cube_fs_params {
    vec4 color;
    vec2 viewport_size;
    float split_enabled;
};

in VS_OUT {
    vec3 local_position;
} vs_out;

out vec4 frag_color;

void main() {
    // gl_FrontFacing is supplied by rasterization. Back faces are dark; this
    // matters when looking through an opening or from inside a mesh.
    vec3 result = gl_FrontFacing ? color.rgb : color.rgb * 0.25;

    // A subtle gradient proves that the interface-block value arrived.
    result *= 0.88 + 0.12 * (vs_out.local_position.y + 0.5);

    // F toggles the chapter's gl_FragCoord split-screen technique.
    if ((split_enabled > 0.5) && (gl_FragCoord.x >= viewport_size.x * 0.5)) {
        float gray = dot(result, vec3(0.2126, 0.7152, 0.0722));
        result = vec3(gray);
    }
    frag_color = vec4(result, 1.0);
}
@end

@vs marker_vs
in vec2 position;
out vec3 marker_color;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);

    // Every three vertices make one marker. sokol-shdc's portable spelling is
    // gl_VertexIndex; it becomes gl_VertexID in generated desktop GLSL.
    float marker_id = floor(float(gl_VertexIndex) / 3.0);
    marker_color = vec3(0.25 + marker_id * 0.12, 0.75, 1.0 - marker_id * 0.12);
}
@end

@fs marker_fs
in vec3 marker_color;
out vec4 frag_color;

void main() {
    frag_color = vec4(marker_color, 1.0);
}
@end

@program cubes cube_vs cube_fs
@program markers marker_vs marker_fs
