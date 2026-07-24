const std = @import("std");
const Build = std.Build;
const sokol = @import("sokol");
const cimgui = @import("cimgui");

const box3d_sources = &.{
    "aabb.c",
    "arena_allocator.c",
    "bitset.c",
    "block_allocator.c",
    "body.c",
    "broad_phase.c",
    "capsule.c",
    "compound.c",
    "constraint_graph.c",
    "contact.c",
    "contact_solver.c",
    "convex_manifold.c",
    "core.c",
    "distance.c",
    "distance_joint.c",
    "dynamic_tree.c",
    "height_field.c",
    "hull.c",
    "id_pool.c",
    "island.c",
    "joint.c",
    "manifold.c",
    "math_functions.c",
    "mesh.c",
    "mesh_contact.c",
    "motor_joint.c",
    "mover.c",
    "name_cache.c",
    "parallel_for.c",
    "parallel_joint.c",
    "physics_world.c",
    "prismatic_joint.c",
    "recording.c",
    "recording_replay.c",
    "revolute_joint.c",
    "scheduler.c",
    "sensor.c",
    "shape.c",
    "simd.c",
    "solver.c",
    "solver_set.c",
    "sphere.c",
    "spherical_joint.c",
    "table.c",
    "timer.c",
    "triangle_manifold.c",
    "types.c",
    "weld_joint.c",
    "wheel_joint.c",
    "world_snapshot.c",
};

const Options = struct {
    mod: *Build.Module,
    mod_lib: *Build.Module,
    dep_sokol: *Build.Dependency,
    box3d_lib: *Build.Step.Compile,
    cimgui_lib: *Build.Step.Compile,
    shdc_step: *Build.Step,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const requested_optimize = b.standardOptimizeOption(.{});
    // With this pinned Zig/Emscripten toolchain, non-ReleaseFast wasm objects
    // leave sokol_gfx_imgui's cross-object trace callbacks with invalid table
    // indices. Native builds still honor the requested optimization mode.
    const optimize: std.builtin.OptimizeMode =
        if (target.result.cpu.arch.isWasm()) .ReleaseFast else requested_optimize;

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
        .with_tracing = true,
    });
    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });
    const dep_box3d = b.dependency("box3d", .{});
    const cimgui_conf = cimgui.getConfig(false);
    const cimgui_lib = dep_cimgui.artifact(cimgui_conf.clib_name);
    const emsdk = dep_sokol.builder.dependency("emsdk", .{});
    const emsdk_install = sokol.emSdkInstallStep(b, emsdk, .{});
    b.step("install-emsdk", "Install Emscripten SDK").dependOn(emsdk_install);

    // sokol's optional ImGui implementations are C and need cimgui.h.
    dep_sokol.artifact("sokol_clib").root_module.addIncludePath(
        dep_cimgui.path(cimgui_conf.include_dir),
    );

    const box3d_lib = buildBox3d(b, dep_box3d, target, optimize);

    // Zig 0.17 no longer has @cImport. Generate regular Zig modules from the
    // public C APIs at build time with the compiler-matched translate-c tool.
    const box3d_bindings = translateCModule(b, .{
        .name = "box3d",
        .header = dep_box3d.path("include/box3d/box3d.h"),
        .include_dir = dep_box3d.path("include"),
        .target = target,
        .optimize = optimize,
        .system_include_dir = if (target.result.cpu.arch.isWasm())
            emsdk.path("upstream/emscripten/cache/sysroot/include")
        else
            null,
        .depends_on = if (target.result.cpu.arch.isWasm()) emsdk_install else null,
    });
    box3d_bindings.linkLibrary(box3d_lib);
    const cimgui_bindings = translateCModule(b, .{
        .name = "cimgui",
        .header = dep_cimgui.path(b.fmt("{s}/cimgui.h", .{cimgui_conf.include_dir})),
        .include_dir = dep_cimgui.path(cimgui_conf.include_dir),
        // As in dcimgui's own build, translating for the host avoids requiring
        // an installed Emscripten sysroot just to parse this platform-neutral API.
        .target = b.graph.host,
        .optimize = optimize,
    });
    cimgui_bindings.linkLibrary(cimgui_lib);

    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});
    const shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/box3d.glsl",
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
            .{ .name = "cimgui", .module = cimgui_bindings },
            .{ .name = "box3d", .module = box3d_bindings },
        },
    });

    const opts = Options{
        .mod = mod_exe,
        .mod_lib = mod_lib,
        .dep_sokol = dep_sokol,
        .box3d_lib = box3d_lib,
        .cimgui_lib = cimgui_lib,
        .shdc_step = shdc_step,
    };

    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, opts);
    } else {
        buildNative(b, opts);
    }
}

const TranslateCOptions = struct {
    name: []const u8,
    header: Build.LazyPath,
    include_dir: Build.LazyPath,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    system_include_dir: ?Build.LazyPath = null,
    depends_on: ?*Build.Step = null,
};

fn translateCModule(b: *Build, opts: TranslateCOptions) *Build.Module {
    const run = b.addSystemCommand(&.{ b.graph.zig_exe, "translate-c" });
    run.setName(b.fmt("translate-c {s}", .{opts.name}));
    run.addArgs(&.{
        "--global-cache-dir",
        b.graph.global_cache_root.path.?,
    });
    run.addArg("-target");
    run.addArg(opts.target.query.zigTriple(b.allocator) catch @panic("OOM"));
    run.addArg(b.fmt("-O{t}", .{opts.optimize}));
    run.addArg("-lc");
    run.addArg("-I");
    run.addDirectoryArg(opts.include_dir);
    if (opts.system_include_dir) |include_dir| {
        run.addArg("-isystem");
        run.addDirectoryArg(include_dir);
    }
    if (opts.depends_on) |dependency| {
        run.step.dependOn(dependency);
    }
    run.addFileArg(opts.header);
    const output = run.captureStdOut(.{
        .basename = b.fmt("{s}.zig", .{opts.name}),
    });

    return b.createModule(.{
        .root_source_file = output,
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
    });
}

fn buildBox3d(
    b: *Build,
    dep_box3d: *Build.Dependency,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(dep_box3d.path("include"));
    mod.addIncludePath(dep_box3d.path("src"));

    var flags: std.ArrayList([]const u8) = .empty;
    flags.append(b.allocator, "-std=gnu17") catch @panic("OOM");
    if (target.result.os.tag != .windows and target.result.os.tag != .emscripten) {
        flags.append(b.allocator, "-ffp-contract=off") catch @panic("OOM");
    }
    if (target.result.cpu.arch.isWasm()) {
        flags.append(b.allocator, "-DBOX3D_DISABLE_SIMD") catch @panic("OOM");
        flags.append(b.allocator, "-fno-sanitize=undefined") catch @panic("OOM");
    }
    if (optimize != .Debug) {
        flags.append(b.allocator, "-DNDEBUG") catch @panic("OOM");
    }
    mod.addCSourceFiles(.{
        .root = dep_box3d.path("src"),
        .files = box3d_sources,
        .flags = flags.items,
    });
    if (target.result.os.tag == .linux) {
        mod.linkSystemLibrary("m", .{});
    }

    return b.addLibrary(.{
        .name = "box3d",
        .linkage = .static,
        .root_module = mod,
    });
}

fn buildNative(b: *Build, opts: Options) void {
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
    exe_tests.step.dependOn(opts.shdc_step);
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
    const emsdk_include = emsdk.path("upstream/emscripten/cache/sysroot/include");

    // C/C++ dependencies need Emscripten's libc headers, and must wait for the
    // SDK install driven by sokol before compiling.
    const sokol_clib = opts.dep_sokol.artifact("sokol_clib");
    const cimgui_clib = opts.cimgui_lib;
    cimgui_clib.root_module.addSystemIncludePath(emsdk_include);
    cimgui_clib.step.dependOn(&sokol_clib.step);
    opts.box3d_lib.root_module.addSystemIncludePath(emsdk_include);
    opts.box3d_lib.step.dependOn(&sokol_clib.step);

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
