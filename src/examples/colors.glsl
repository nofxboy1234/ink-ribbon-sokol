// LearnOpenGL "Colors" scene, expressed in sokol-shdc's shader format.
// sokol-shdc translates this source into GLSL, HLSL, Metal, and WGSL variants.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

in vec4 position;

void main() {
    gl_Position = mvp * position;
}
@end

@fs object_fs
layout(binding = 1) uniform object_fs_params {
    vec4 object_color;
    vec4 light_color;
};

out vec4 frag_color;

void main() {
    // Component-wise multiplication describes which parts of the incoming
    // light the object reflects. The next LearnOpenGL chapter adds direction.
    frag_color = vec4(light_color.rgb * object_color.rgb, 1.0);
}
@end

@fs lamp_fs
out vec4 frag_color;

void main() {
    // The lamp marker stays visibly white and is not shaded by itself.
    frag_color = vec4(1.0);
}
@end

@program object vs object_fs
@program lamp vs lamp_fs
