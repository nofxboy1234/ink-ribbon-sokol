@vs index_vs
in vec2 position;
in vec3 color0;
out vec3 color;

void main() {
    // sokol-shdc's portable spelling for OpenGL's gl_InstanceID.
    int column = gl_InstanceIndex % 10;
    int row = gl_InstanceIndex / 10;
    vec2 offset = vec2(-0.9 + float(column) * 0.2,
                       -0.9 + float(row) * 0.2);
    gl_Position = vec4(position + offset, 0.0, 1.0);
    color = color0;
}
@end

@vs buffer_vs
in vec2 position;
in vec3 color0;
in vec2 instance_offset;
in vec3 instance_color;
in float instance_scale;
out vec3 color;

void main() {
    gl_Position = vec4(position * instance_scale + instance_offset, 0.0, 1.0);
    color = color0 * instance_color;
}
@end

@fs fs
in vec3 color;
out vec4 frag_color;

void main() {
    frag_color = vec4(color, 1.0);
}
@end

@program index_grid index_vs fs
@program buffer_grid buffer_vs fs
