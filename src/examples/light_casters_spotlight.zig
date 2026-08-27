const sokol = @import("sokol");
const lesson = @import("light_casters.zig");

export fn init() void {
    lesson.init();
}

export fn frame() void {
    lesson.frame(.spotlight);
}

export fn cleanup() void {
    lesson.cleanup();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "LearnOpenGL Spotlight — Sokol + Zig",
        .logger = .{ .func = sokol.log.func },
    });
}
