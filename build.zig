const std = @import("std");
const Build = std.Build;
const sokol = @import("sokol");

const Options = struct {
    mod: *Build.Module,
    mod_lib: *Build.Module,
    dep_sokol: *Build.Dependency,
    shdc_step: *Build.Step,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const emsdk_install = sokol.emSdkInstallStep(b, dep_sokol.builder.dependency("emsdk", .{}), .{});
    b.step("install-emsdk", "Install Emscripten SDK").dependOn(emsdk_install);

    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});
    const shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/cube.glsl",
        .output = "src/shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });

    const mod_lib = b.addModule("ink_ribbon_sokol", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const mod_exe = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });

    const opts = Options{ .mod = mod_exe, .mod_lib = mod_lib, .dep_sokol = dep_sokol, .shdc_step = shdc_step };

    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, opts);
    } else {
        try buildNative(b, opts);
    }
}

fn buildNative(b: *Build, opts: Options) !void {
    const exe = b.addExecutable(.{
        .name = "ink_ribbon_sokol",
        .root_module = opts.mod,
    });
    exe.step.dependOn(opts.shdc_step);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = opts.mod_lib,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = opts.mod,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}

fn buildWeb(b: *Build, opts: Options) !void {
    const lib = b.addLibrary(.{
        .name = "ink_ribbon_sokol",
        .root_module = opts.mod,
    });
    lib.step.dependOn(opts.shdc_step);

    const emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = lib,
        .target = opts.mod.resolved_target.?,
        .optimize = opts.mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&link_step.step);

    const run = sokol.emRunStep(b, .{ .name = "ink_ribbon_sokol", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run the app").dependOn(&run.step);
}
