// LearnOpenGL Advanced OpenGL / Cubemaps.
@header const m = @import("../cube_math.zig")
@ctype mat4 m.Mat4

// The object shader demonstrates an ordinary material, reflection, and
// refraction. All three modes share the same geometry and cubemap binding.
@vs object_vs
layout(binding=0) uniform object_vs_params {
    mat4 mvp;
    mat4 model;
};

in vec3 position;
in vec3 normal;
out vec3 world_position;
out vec3 world_normal;

void main() {
    vec4 position_world = model * vec4(position, 1.0);
    world_position = position_world.xyz;

    // This lesson only rotates the cube, so mat3(model) is sufficient. A
    // non-uniformly scaled model would need the inverse-transpose matrix.
    world_normal = mat3(model) * normal;
    gl_Position = mvp * vec4(position, 1.0);
}
@end

@fs object_fs
layout(binding=1) uniform object_fs_params {
    // xyz = camera world position, w = 0 ordinary, 1 reflection, 2 refraction
    vec4 camera_and_mode;
};
layout(binding=0) uniform textureCube environment_tex;
layout(binding=0) uniform sampler environment_smp;

in vec3 world_position;
in vec3 world_normal;
out vec4 frag_color;

void main() {
    vec3 normal = normalize(world_normal);
    int mode = int(camera_and_mode.w + 0.5);

    if (mode == 0) {
        // A deliberately simple material makes the non-environment-mapped
        // baseline easy to compare with the next two modes.
        vec3 colour = vec3(0.15) + abs(normal) * vec3(0.25, 0.55, 0.85);
        frag_color = vec4(colour, 1.0);
        return;
    }

    // I points from the camera toward this fragment.
    vec3 I = normalize(world_position - camera_and_mode.xyz);
    vec3 sample_direction;
    if (mode == 1) {
        sample_direction = reflect(I, normal);
    } else {
        // Air (1.00) into glass (1.52).
        sample_direction = refract(I, normal, 1.0 / 1.52);
    }
    frag_color = vec4(texture(samplerCube(environment_tex, environment_smp), sample_direction).rgb, 1.0);
}
@end

@program object object_vs object_fs

// The skybox cube is viewed from inside. Its local vertex position is already
// a direction from the cube centre and therefore doubles as its texture input.
@vs skybox_vs
layout(binding=0) uniform skybox_vs_params {
    mat4 view_projection;
};

in vec3 position;
out vec3 sample_direction;

void main() {
    sample_direction = position;
    vec4 pos = view_projection * vec4(position, 1.0);

    // z=w produces z/w=1 after perspective division, putting the skybox on
    // the far plane so that already-drawn scene geometry stays in front.
    gl_Position = pos.xyww;
}
@end

@fs skybox_fs
layout(binding=0) uniform textureCube environment_tex;
layout(binding=0) uniform sampler environment_smp;

in vec3 sample_direction;
out vec4 frag_color;

void main() {
    frag_color = texture(samplerCube(environment_tex, environment_smp), sample_direction);
}
@end

@program skybox skybox_vs skybox_fs
