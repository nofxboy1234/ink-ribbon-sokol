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
    advanced_data_mod: *Build.Module,
    advanced_glsl_mod: *Build.Module,
    geometry_shader_mod: *Build.Module,
    instancing_mod: *Build.Module,
    anti_aliasing_mod: *Build.Module,
    basic_lighting_mod: *Build.Module,
    box3d_mod: *Build.Module,
    character_mod: *Build.Module,
    colors_mod: *Build.Module,
    cube_mod: *Build.Module,
    depth_testing_mod: *Build.Module,
    stencil_testing_mod: *Build.Module,
    blending_mod: *Build.Module,
    face_culling_mod: *Build.Module,
    framebuffers_mod: *Build.Module,
    cubemaps_mod: *Build.Module,
    light_casters_directional_mod: *Build.Module,
    light_casters_point_mod: *Build.Module,
    light_casters_spotlight_mod: *Build.Module,
    lighting_maps_mod: *Build.Module,
    materials_mod: *Build.Module,
    model_loading_mod: *Build.Module,
    multiple_lights_mod: *Build.Module,
    triangle_mod: *Build.Module,
    texcube_mod: *Build.Module,
    mod_lib: *Build.Module,
    dep_sokol: *Build.Dependency,
    box3d_lib: *Build.Step.Compile,
    cimgui_lib: *Build.Step.Compile,
    cgltf_lib: *Build.Step.Compile,
    box3d_shdc_step: *Build.Step,
    character_shdc_step: *Build.Step,
    basic_lighting_shdc_step: *Build.Step,
    colors_shdc_step: *Build.Step,
    cube_shdc_step: *Build.Step,
    depth_testing_shdc_step: *Build.Step,
    stencil_testing_shdc_step: *Build.Step,
    blending_shdc_step: *Build.Step,
    face_culling_shdc_step: *Build.Step,
    framebuffers_shdc_step: *Build.Step,
    cubemaps_shdc_step: *Build.Step,
    advanced_data_shdc_step: *Build.Step,
    advanced_glsl_shdc_step: *Build.Step,
    geometry_shader_shdc_step: *Build.Step,
    instancing_shdc_step: *Build.Step,
    anti_aliasing_shdc_step: *Build.Step,
    light_casters_shdc_step: *Build.Step,
    lighting_maps_shdc_step: *Build.Step,
    materials_shdc_step: *Build.Step,
    model_loading_shdc_step: *Build.Step,
    multiple_lights_shdc_step: *Build.Step,
    triangle_shdc_step: *Build.Step,
    texcube_shdc_step: *Build.Step,
    emsdk_install: *Build.Step,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const requested_optimize = b.standardOptimizeOption(.{});
    // Non-ReleaseFast wasm objects still leave sokol_gfx_imgui's cross-object
    // trace callbacks with invalid table indices under Emscripten 6.0.0.
    // Native builds continue to honor the requested optimization mode.
    const optimize: std.builtin.OptimizeMode =
        if (target.result.cpu.arch.isWasm()) .fast else requested_optimize;

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
    const cgltf_lib = buildCgltf(
        b,
        b.path(".toolchain/deps/cgltf"),
        b.path(".toolchain/deps/stb"),
        target,
        optimize,
    );

    // Zig 0.17 no longer has @cImport. These regular Zig modules are generated
    // from the pinned public C headers by toolchain/bootstrap.sh via translate-c.
    const box3d_bindings = b.createModule(.{
        .root_source_file = b.path("src/generated/box3d.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    box3d_bindings.linkLibrary(box3d_lib);
    const cimgui_bindings = b.createModule(.{
        .root_source_file = b.path("src/examples/generated/cimgui.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    cimgui_bindings.linkLibrary(cimgui_lib);
    const cgltf_bindings = b.createModule(.{
        .root_source_file = b.path("src/examples/generated/cgltf.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    cgltf_bindings.linkLibrary(cgltf_lib);
    const model_image_bindings = b.createModule(.{
        .root_source_file = b.path("src/examples/generated/model_image.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    model_image_bindings.linkLibrary(cgltf_lib);

    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});
    const advanced_data_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/advanced_data.glsl",
        .output = "src/examples/generated/advanced_data_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const advanced_glsl_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/advanced_glsl.glsl",
        .output = "src/examples/generated/advanced_glsl_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const geometry_shader_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/geometry_shader.glsl",
        .output = "src/examples/generated/geometry_shader_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const instancing_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/instancing.glsl",
        .output = "src/examples/generated/instancing_shader.zig",
        .slang = .{ .glsl410 = true, .glsl300es = true, .hlsl5 = true, .metal_macos = true, .wgsl = true },
        .reflection = true,
    });
    const anti_aliasing_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/anti_aliasing.glsl",
        .output = "src/examples/generated/anti_aliasing_shader.zig",
        .slang = .{ .glsl410 = true, .glsl300es = true, .hlsl5 = true, .metal_macos = true, .wgsl = true },
        .reflection = true,
    });
    const box3d_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/box3d.glsl",
        .output = "src/examples/generated/box3d_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const character_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/character.glsl",
        .output = "src/generated/character_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const basic_lighting_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/basic_lighting.glsl",
        .output = "src/examples/generated/basic_lighting_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const colors_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/colors.glsl",
        .output = "src/examples/generated/colors_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const materials_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/materials.glsl",
        .output = "src/examples/generated/materials_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const depth_testing_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/depth_testing.glsl",
        .output = "src/examples/generated/depth_testing_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const stencil_testing_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/stencil_testing.glsl",
        .output = "src/examples/generated/stencil_testing_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const blending_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/blending.glsl",
        .output = "src/examples/generated/blending_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const face_culling_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/face_culling.glsl",
        .output = "src/examples/generated/face_culling_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const framebuffers_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/framebuffers.glsl",
        .output = "src/examples/generated/framebuffers_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const cubemaps_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/cubemaps.glsl",
        .output = "src/examples/generated/cubemaps_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const lighting_maps_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/lighting_maps.glsl",
        .output = "src/examples/generated/lighting_maps_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const multiple_lights_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/multiple_lights.glsl",
        .output = "src/examples/generated/multiple_lights_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const model_loading_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/model_loading.glsl",
        .output = "src/examples/generated/model_loading_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const light_casters_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/light_casters.glsl",
        .output = "src/examples/generated/light_casters_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const cube_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/cube.glsl",
        .output = "src/examples/generated/cube_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const triangle_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/triangle.glsl",
        .output = "src/examples/generated/triangle_shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl5 = true,
            .metal_macos = true,
            .wgsl = true,
        },
        .reflection = true,
    });
    const texcube_shdc_step = try sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = "src/examples/texcube.glsl",
        .output = "src/examples/generated/texcube_shader.zig",
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
        .root_source_file = b.path("src/examples/root.zig"),
        .target = target,
    });
    const math_mod = b.createModule(.{
        .root_source_file = b.path("src/math.zig"),
        .target = target,
        .optimize = optimize,
    });

    const advanced_data_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/advanced_data.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const advanced_glsl_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/advanced_glsl.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const geometry_shader_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/geometry_shader.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const instancing_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/instancing.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const anti_aliasing_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/anti_aliasing.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });

    const box3d_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/box3d.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "cimgui", .module = cimgui_bindings },
            .{ .name = "box3d", .module = box3d_bindings },
            .{ .name = "math", .module = math_mod },
        },
    });
    const character_mod = b.createModule(.{
        .root_source_file = b.path("src/character.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "box3d", .module = box3d_bindings },
            .{ .name = "cgltf", .module = cgltf_bindings },
        },
    });
    character_mod.addAnonymousImport("level_glb", .{
        .root_source_file = b.path("level/level.glb"),
    });
    const basic_lighting_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/basic_lighting.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const cube_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/cube.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const colors_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/colors.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const depth_testing_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/depth_testing.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "model_image", .module = model_image_bindings },
        },
    });
    const stencil_testing_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/stencil_testing.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "model_image", .module = model_image_bindings },
        },
    });
    const blending_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/blending.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "model_image", .module = model_image_bindings },
        },
    });
    const face_culling_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/face_culling.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const framebuffers_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/framebuffers.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "model_image", .module = model_image_bindings },
        },
    });
    const cubemaps_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/cubemaps.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "model_image", .module = model_image_bindings },
        },
    });
    const materials_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/materials.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const lighting_maps_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/lighting_maps.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const light_casters_directional_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/light_casters_directional.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const light_casters_point_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/light_casters_point.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const light_casters_spotlight_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/light_casters_spotlight.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const multiple_lights_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/multiple_lights.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const model_loading_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/model_loading.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "cgltf", .module = cgltf_bindings },
            .{ .name = "model_image", .module = model_image_bindings },
        },
    });
    const triangle_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/triangle.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });
    const texcube_mod = b.createModule(.{
        .root_source_file = b.path("src/examples/texcube.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ink_ribbon_sokol", .module = mod_lib },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });

    const opts = Options{
        .advanced_data_mod = advanced_data_mod,
        .advanced_glsl_mod = advanced_glsl_mod,
        .geometry_shader_mod = geometry_shader_mod,
        .instancing_mod = instancing_mod,
        .anti_aliasing_mod = anti_aliasing_mod,
        .basic_lighting_mod = basic_lighting_mod,
        .box3d_mod = box3d_mod,
        .character_mod = character_mod,
        .colors_mod = colors_mod,
        .cube_mod = cube_mod,
        .depth_testing_mod = depth_testing_mod,
        .stencil_testing_mod = stencil_testing_mod,
        .blending_mod = blending_mod,
        .face_culling_mod = face_culling_mod,
        .framebuffers_mod = framebuffers_mod,
        .cubemaps_mod = cubemaps_mod,
        .light_casters_directional_mod = light_casters_directional_mod,
        .light_casters_point_mod = light_casters_point_mod,
        .light_casters_spotlight_mod = light_casters_spotlight_mod,
        .lighting_maps_mod = lighting_maps_mod,
        .materials_mod = materials_mod,
        .model_loading_mod = model_loading_mod,
        .multiple_lights_mod = multiple_lights_mod,
        .triangle_mod = triangle_mod,
        .texcube_mod = texcube_mod,
        .mod_lib = mod_lib,
        .dep_sokol = dep_sokol,
        .box3d_lib = box3d_lib,
        .cimgui_lib = cimgui_lib,
        .cgltf_lib = cgltf_lib,
        .box3d_shdc_step = box3d_shdc_step,
        .character_shdc_step = character_shdc_step,
        .basic_lighting_shdc_step = basic_lighting_shdc_step,
        .colors_shdc_step = colors_shdc_step,
        .cube_shdc_step = cube_shdc_step,
        .depth_testing_shdc_step = depth_testing_shdc_step,
        .stencil_testing_shdc_step = stencil_testing_shdc_step,
        .blending_shdc_step = blending_shdc_step,
        .face_culling_shdc_step = face_culling_shdc_step,
        .framebuffers_shdc_step = framebuffers_shdc_step,
        .cubemaps_shdc_step = cubemaps_shdc_step,
        .advanced_data_shdc_step = advanced_data_shdc_step,
        .advanced_glsl_shdc_step = advanced_glsl_shdc_step,
        .geometry_shader_shdc_step = geometry_shader_shdc_step,
        .instancing_shdc_step = instancing_shdc_step,
        .anti_aliasing_shdc_step = anti_aliasing_shdc_step,
        .light_casters_shdc_step = light_casters_shdc_step,
        .lighting_maps_shdc_step = lighting_maps_shdc_step,
        .materials_shdc_step = materials_shdc_step,
        .model_loading_shdc_step = model_loading_shdc_step,
        .multiple_lights_shdc_step = multiple_lights_shdc_step,
        .triangle_shdc_step = triangle_shdc_step,
        .texcube_shdc_step = texcube_shdc_step,
        .emsdk_install = emsdk_install,
    };

    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, opts);
    } else {
        buildNative(b, opts);
    }
}

fn buildCgltf(
    b: *Build,
    cgltf_root: Build.LazyPath,
    stb_root: Build.LazyPath,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(cgltf_root);
    mod.addIncludePath(stb_root);
    mod.addIncludePath(b.path("src/examples/c"));
    mod.addCSourceFile(.{ .file = b.path("src/examples/c/cgltf.c"), .flags = &.{"-std=c99"} });
    mod.addCSourceFile(.{ .file = b.path("src/examples/c/model_image.c"), .flags = &.{"-std=c99"} });
    return b.addLibrary(.{ .name = "cgltf", .linkage = .static, .root_module = mod });
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
    if (optimize != .debug) {
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
    const advanced_data_exe = b.addExecutable(.{
        .name = "ink_ribbon_advanced_data",
        .root_module = opts.advanced_data_mod,
    });
    advanced_data_exe.step.dependOn(opts.advanced_data_shdc_step);
    b.installArtifact(advanced_data_exe);

    const advanced_glsl_exe = b.addExecutable(.{
        .name = "ink_ribbon_advanced_glsl",
        .root_module = opts.advanced_glsl_mod,
    });
    advanced_glsl_exe.step.dependOn(opts.advanced_glsl_shdc_step);
    b.installArtifact(advanced_glsl_exe);

    const geometry_shader_exe = b.addExecutable(.{
        .name = "ink_ribbon_geometry_shader",
        .root_module = opts.geometry_shader_mod,
    });
    geometry_shader_exe.step.dependOn(opts.geometry_shader_shdc_step);
    b.installArtifact(geometry_shader_exe);

    const instancing_exe = b.addExecutable(.{
        .name = "ink_ribbon_instancing",
        .root_module = opts.instancing_mod,
    });
    instancing_exe.step.dependOn(opts.instancing_shdc_step);
    b.installArtifact(instancing_exe);

    const anti_aliasing_exe = b.addExecutable(.{
        .name = "ink_ribbon_anti_aliasing",
        .root_module = opts.anti_aliasing_mod,
    });
    anti_aliasing_exe.step.dependOn(opts.anti_aliasing_shdc_step);
    b.installArtifact(anti_aliasing_exe);

    const basic_lighting_exe = b.addExecutable(.{
        .name = "ink_ribbon_basic_lighting",
        .root_module = opts.basic_lighting_mod,
    });
    basic_lighting_exe.step.dependOn(opts.basic_lighting_shdc_step);
    b.installArtifact(basic_lighting_exe);

    const box3d_exe = b.addExecutable(.{
        .name = "ink_ribbon_box3d",
        .root_module = opts.box3d_mod,
    });
    box3d_exe.step.dependOn(opts.box3d_shdc_step);
    b.installArtifact(box3d_exe);

    const character_exe = b.addExecutable(.{
        .name = "ink_ribbon_character",
        .root_module = opts.character_mod,
    });
    character_exe.step.dependOn(opts.character_shdc_step);
    b.installArtifact(character_exe);

    const colors_exe = b.addExecutable(.{
        .name = "ink_ribbon_colors",
        .root_module = opts.colors_mod,
    });
    colors_exe.step.dependOn(opts.colors_shdc_step);
    b.installArtifact(colors_exe);

    const depth_testing_exe = b.addExecutable(.{
        .name = "ink_ribbon_depth_testing",
        .root_module = opts.depth_testing_mod,
    });
    depth_testing_exe.step.dependOn(opts.depth_testing_shdc_step);
    b.installArtifact(depth_testing_exe);

    const stencil_testing_exe = b.addExecutable(.{
        .name = "ink_ribbon_stencil_testing",
        .root_module = opts.stencil_testing_mod,
    });
    stencil_testing_exe.step.dependOn(opts.stencil_testing_shdc_step);
    b.installArtifact(stencil_testing_exe);

    const blending_exe = b.addExecutable(.{
        .name = "ink_ribbon_blending",
        .root_module = opts.blending_mod,
    });
    blending_exe.step.dependOn(opts.blending_shdc_step);
    b.installArtifact(blending_exe);

    const face_culling_exe = b.addExecutable(.{
        .name = "ink_ribbon_face_culling",
        .root_module = opts.face_culling_mod,
    });
    face_culling_exe.step.dependOn(opts.face_culling_shdc_step);
    b.installArtifact(face_culling_exe);

    const framebuffers_exe = b.addExecutable(.{
        .name = "ink_ribbon_framebuffers",
        .root_module = opts.framebuffers_mod,
    });
    framebuffers_exe.step.dependOn(opts.framebuffers_shdc_step);
    b.installArtifact(framebuffers_exe);

    const cubemaps_exe = b.addExecutable(.{
        .name = "ink_ribbon_cubemaps",
        .root_module = opts.cubemaps_mod,
    });
    cubemaps_exe.step.dependOn(opts.cubemaps_shdc_step);
    b.installArtifact(cubemaps_exe);

    const materials_exe = b.addExecutable(.{
        .name = "ink_ribbon_materials",
        .root_module = opts.materials_mod,
    });
    materials_exe.step.dependOn(opts.materials_shdc_step);
    b.installArtifact(materials_exe);

    const lighting_maps_exe = b.addExecutable(.{
        .name = "ink_ribbon_lighting_maps",
        .root_module = opts.lighting_maps_mod,
    });
    lighting_maps_exe.step.dependOn(opts.lighting_maps_shdc_step);
    b.installArtifact(lighting_maps_exe);

    const light_casters_directional_exe = b.addExecutable(.{
        .name = "ink_ribbon_light_casters_directional",
        .root_module = opts.light_casters_directional_mod,
    });
    light_casters_directional_exe.step.dependOn(opts.light_casters_shdc_step);
    b.installArtifact(light_casters_directional_exe);
    const light_casters_point_exe = b.addExecutable(.{
        .name = "ink_ribbon_light_casters_point",
        .root_module = opts.light_casters_point_mod,
    });
    light_casters_point_exe.step.dependOn(opts.light_casters_shdc_step);
    b.installArtifact(light_casters_point_exe);
    const light_casters_spotlight_exe = b.addExecutable(.{
        .name = "ink_ribbon_light_casters_spotlight",
        .root_module = opts.light_casters_spotlight_mod,
    });
    light_casters_spotlight_exe.step.dependOn(opts.light_casters_shdc_step);
    b.installArtifact(light_casters_spotlight_exe);

    const multiple_lights_exe = b.addExecutable(.{
        .name = "ink_ribbon_multiple_lights",
        .root_module = opts.multiple_lights_mod,
    });
    multiple_lights_exe.step.dependOn(opts.multiple_lights_shdc_step);
    b.installArtifact(multiple_lights_exe);

    const model_loading_exe = b.addExecutable(.{
        .name = "ink_ribbon_model_loading",
        .root_module = opts.model_loading_mod,
    });
    model_loading_exe.step.dependOn(opts.model_loading_shdc_step);
    b.installArtifact(model_loading_exe);

    const cube_exe = b.addExecutable(.{
        .name = "ink_ribbon_cube",
        .root_module = opts.cube_mod,
    });
    cube_exe.step.dependOn(opts.cube_shdc_step);
    b.installArtifact(cube_exe);

    const triangle_exe = b.addExecutable(.{
        .name = "ink_ribbon_triangle",
        .root_module = opts.triangle_mod,
    });
    triangle_exe.step.dependOn(opts.triangle_shdc_step);
    b.installArtifact(triangle_exe);

    const texcube_exe = b.addExecutable(.{
        .name = "ink_ribbon_texcube",
        .root_module = opts.texcube_mod,
    });
    texcube_exe.step.dependOn(opts.texcube_shdc_step);
    b.installArtifact(texcube_exe);

    const run_box3d_cmd = b.addRunArtifact(box3d_exe);
    run_box3d_cmd.step.dependOn(&box3d_exe.step);
    b.step("run-box3d", "Run the Box3D example").dependOn(&run_box3d_cmd.step);
    b.step("run", "Run the Box3D example").dependOn(&run_box3d_cmd.step);

    const run_character_cmd = b.addRunArtifact(character_exe);
    run_character_cmd.step.dependOn(&character_exe.step);
    b.step("run-character", "Run the character mover scene").dependOn(&run_character_cmd.step);

    const run_advanced_data_cmd = b.addRunArtifact(advanced_data_exe);
    run_advanced_data_cmd.step.dependOn(&advanced_data_exe.step);
    b.step("run-advanced-data", "Run the LearnOpenGL Advanced Data example").dependOn(&run_advanced_data_cmd.step);

    const run_advanced_glsl_cmd = b.addRunArtifact(advanced_glsl_exe);
    run_advanced_glsl_cmd.step.dependOn(&advanced_glsl_exe.step);
    b.step("run-advanced-glsl", "Run the LearnOpenGL Advanced GLSL example").dependOn(&run_advanced_glsl_cmd.step);

    const run_geometry_shader_cmd = b.addRunArtifact(geometry_shader_exe);
    run_geometry_shader_cmd.step.dependOn(&geometry_shader_exe.step);
    b.step("run-geometry-shader", "Run the LearnOpenGL Geometry Shader ideas example").dependOn(&run_geometry_shader_cmd.step);

    const run_instancing_cmd = b.addRunArtifact(instancing_exe);
    run_instancing_cmd.step.dependOn(&instancing_exe.step);
    b.step("run-instancing", "Run the LearnOpenGL Instancing example").dependOn(&run_instancing_cmd.step);

    const run_anti_aliasing_cmd = b.addRunArtifact(anti_aliasing_exe);
    run_anti_aliasing_cmd.step.dependOn(&anti_aliasing_exe.step);
    b.step("run-anti-aliasing", "Run the LearnOpenGL Anti-Aliasing example").dependOn(&run_anti_aliasing_cmd.step);

    const run_basic_lighting_cmd = b.addRunArtifact(basic_lighting_exe);
    run_basic_lighting_cmd.step.dependOn(&basic_lighting_exe.step);
    b.step("run-basic-lighting", "Run the LearnOpenGL Basic Lighting example").dependOn(&run_basic_lighting_cmd.step);

    const run_colors_cmd = b.addRunArtifact(colors_exe);
    run_colors_cmd.step.dependOn(&colors_exe.step);
    b.step("run-colors", "Run the LearnOpenGL Colors example").dependOn(&run_colors_cmd.step);

    const run_depth_testing_cmd = b.addRunArtifact(depth_testing_exe);
    run_depth_testing_cmd.step.dependOn(&depth_testing_exe.step);
    b.step("run-depth-testing", "Run the LearnOpenGL Depth Testing example").dependOn(&run_depth_testing_cmd.step);

    const run_stencil_testing_cmd = b.addRunArtifact(stencil_testing_exe);
    run_stencil_testing_cmd.step.dependOn(&stencil_testing_exe.step);
    b.step("run-stencil-testing", "Run the LearnOpenGL Stencil Testing example").dependOn(&run_stencil_testing_cmd.step);

    const run_blending_cmd = b.addRunArtifact(blending_exe);
    run_blending_cmd.step.dependOn(&blending_exe.step);
    b.step("run-blending", "Run the LearnOpenGL Blending example").dependOn(&run_blending_cmd.step);

    const run_face_culling_cmd = b.addRunArtifact(face_culling_exe);
    run_face_culling_cmd.step.dependOn(&face_culling_exe.step);
    b.step("run-face-culling", "Run the LearnOpenGL Face Culling example").dependOn(&run_face_culling_cmd.step);

    const run_framebuffers_cmd = b.addRunArtifact(framebuffers_exe);
    run_framebuffers_cmd.step.dependOn(&framebuffers_exe.step);
    b.step("run-framebuffers", "Run the LearnOpenGL Framebuffers example").dependOn(&run_framebuffers_cmd.step);

    const run_cubemaps_cmd = b.addRunArtifact(cubemaps_exe);
    run_cubemaps_cmd.step.dependOn(&cubemaps_exe.step);
    b.step("run-cubemaps", "Run the LearnOpenGL Cubemaps example").dependOn(&run_cubemaps_cmd.step);

    const run_materials_cmd = b.addRunArtifact(materials_exe);
    run_materials_cmd.step.dependOn(&materials_exe.step);
    b.step("run-materials", "Run the LearnOpenGL Materials example").dependOn(&run_materials_cmd.step);

    const run_lighting_maps_cmd = b.addRunArtifact(lighting_maps_exe);
    run_lighting_maps_cmd.step.dependOn(&lighting_maps_exe.step);
    b.step("run-lighting-maps", "Run the LearnOpenGL Lighting Maps example").dependOn(&run_lighting_maps_cmd.step);

    const run_light_casters_directional_cmd = b.addRunArtifact(light_casters_directional_exe);
    run_light_casters_directional_cmd.step.dependOn(&light_casters_directional_exe.step);
    b.step("run-light-casters-directional", "Run the LearnOpenGL Directional Light example").dependOn(&run_light_casters_directional_cmd.step);
    const run_light_casters_point_cmd = b.addRunArtifact(light_casters_point_exe);
    run_light_casters_point_cmd.step.dependOn(&light_casters_point_exe.step);
    b.step("run-light-casters-point", "Run the LearnOpenGL Point Light example").dependOn(&run_light_casters_point_cmd.step);
    const run_light_casters_spotlight_cmd = b.addRunArtifact(light_casters_spotlight_exe);
    run_light_casters_spotlight_cmd.step.dependOn(&light_casters_spotlight_exe.step);
    b.step("run-light-casters-spotlight", "Run the LearnOpenGL Spotlight example").dependOn(&run_light_casters_spotlight_cmd.step);
    b.step("run-light-casters", "Run the LearnOpenGL Spotlight example").dependOn(&run_light_casters_spotlight_cmd.step);

    const run_multiple_lights_cmd = b.addRunArtifact(multiple_lights_exe);
    run_multiple_lights_cmd.step.dependOn(&multiple_lights_exe.step);
    b.step("run-multiple-lights", "Run the LearnOpenGL Multiple Lights example").dependOn(&run_multiple_lights_cmd.step);

    const run_model_loading_cmd = b.addRunArtifact(model_loading_exe);
    run_model_loading_cmd.step.dependOn(&model_loading_exe.step);
    b.step("run-model-loading", "Run the LearnOpenGL Model Loading example").dependOn(&run_model_loading_cmd.step);

    const run_cube_cmd = b.addRunArtifact(cube_exe);
    run_cube_cmd.step.dependOn(&cube_exe.step);
    b.step("run-cube", "Run the spinning cube example").dependOn(&run_cube_cmd.step);

    const run_triangle_cmd = b.addRunArtifact(triangle_exe);
    run_triangle_cmd.step.dependOn(&triangle_exe.step);
    b.step("run-triangle", "Run the triangle example").dependOn(&run_triangle_cmd.step);

    const run_texcube_cmd = b.addRunArtifact(texcube_exe);
    run_texcube_cmd.step.dependOn(&texcube_exe.step);
    b.step("run-texcube", "Run the textured cube example").dependOn(&run_texcube_cmd.step);

    const mod_tests = b.addTest(.{
        .root_module = opts.mod_lib,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const box3d_tests = b.addTest(.{
        .root_module = opts.box3d_mod,
    });
    box3d_tests.step.dependOn(opts.box3d_shdc_step);
    const run_box3d_tests = b.addRunArtifact(box3d_tests);

    const character_tests = b.addTest(.{
        .root_module = opts.character_mod,
    });
    character_tests.step.dependOn(opts.character_shdc_step);
    const run_character_tests = b.addRunArtifact(character_tests);

    const advanced_data_tests = b.addTest(.{
        .root_module = opts.advanced_data_mod,
    });
    advanced_data_tests.step.dependOn(opts.advanced_data_shdc_step);
    const run_advanced_data_tests = b.addRunArtifact(advanced_data_tests);

    const advanced_glsl_tests = b.addTest(.{
        .root_module = opts.advanced_glsl_mod,
    });
    advanced_glsl_tests.step.dependOn(opts.advanced_glsl_shdc_step);
    const run_advanced_glsl_tests = b.addRunArtifact(advanced_glsl_tests);

    const geometry_shader_tests = b.addTest(.{
        .root_module = opts.geometry_shader_mod,
    });
    geometry_shader_tests.step.dependOn(opts.geometry_shader_shdc_step);
    const run_geometry_shader_tests = b.addRunArtifact(geometry_shader_tests);

    const instancing_tests = b.addTest(.{ .root_module = opts.instancing_mod });
    instancing_tests.step.dependOn(opts.instancing_shdc_step);
    const run_instancing_tests = b.addRunArtifact(instancing_tests);

    const anti_aliasing_tests = b.addTest(.{ .root_module = opts.anti_aliasing_mod });
    anti_aliasing_tests.step.dependOn(opts.anti_aliasing_shdc_step);
    const run_anti_aliasing_tests = b.addRunArtifact(anti_aliasing_tests);

    const basic_lighting_tests = b.addTest(.{
        .root_module = opts.basic_lighting_mod,
    });
    basic_lighting_tests.step.dependOn(opts.basic_lighting_shdc_step);
    const run_basic_lighting_tests = b.addRunArtifact(basic_lighting_tests);

    const cube_tests = b.addTest(.{
        .root_module = opts.cube_mod,
    });
    cube_tests.step.dependOn(opts.cube_shdc_step);
    const run_cube_tests = b.addRunArtifact(cube_tests);

    const colors_tests = b.addTest(.{
        .root_module = opts.colors_mod,
    });
    colors_tests.step.dependOn(opts.colors_shdc_step);
    const run_colors_tests = b.addRunArtifact(colors_tests);

    const depth_testing_tests = b.addTest(.{ .root_module = opts.depth_testing_mod });
    depth_testing_tests.step.dependOn(opts.depth_testing_shdc_step);
    const run_depth_testing_tests = b.addRunArtifact(depth_testing_tests);

    const stencil_testing_tests = b.addTest(.{ .root_module = opts.stencil_testing_mod });
    stencil_testing_tests.step.dependOn(opts.stencil_testing_shdc_step);
    const run_stencil_testing_tests = b.addRunArtifact(stencil_testing_tests);

    const blending_tests = b.addTest(.{ .root_module = opts.blending_mod });
    blending_tests.step.dependOn(opts.blending_shdc_step);
    const run_blending_tests = b.addRunArtifact(blending_tests);

    const face_culling_tests = b.addTest(.{ .root_module = opts.face_culling_mod });
    face_culling_tests.step.dependOn(opts.face_culling_shdc_step);
    const run_face_culling_tests = b.addRunArtifact(face_culling_tests);

    const framebuffers_tests = b.addTest(.{ .root_module = opts.framebuffers_mod });
    framebuffers_tests.step.dependOn(opts.framebuffers_shdc_step);
    const run_framebuffers_tests = b.addRunArtifact(framebuffers_tests);

    const cubemaps_tests = b.addTest(.{ .root_module = opts.cubemaps_mod });
    cubemaps_tests.step.dependOn(opts.cubemaps_shdc_step);
    const run_cubemaps_tests = b.addRunArtifact(cubemaps_tests);

    const materials_tests = b.addTest(.{
        .root_module = opts.materials_mod,
    });
    materials_tests.step.dependOn(opts.materials_shdc_step);
    const run_materials_tests = b.addRunArtifact(materials_tests);

    const lighting_maps_tests = b.addTest(.{
        .root_module = opts.lighting_maps_mod,
    });
    lighting_maps_tests.step.dependOn(opts.lighting_maps_shdc_step);
    const run_lighting_maps_tests = b.addRunArtifact(lighting_maps_tests);

    const light_casters_directional_tests = b.addTest(.{ .root_module = opts.light_casters_directional_mod });
    light_casters_directional_tests.step.dependOn(opts.light_casters_shdc_step);
    const run_light_casters_directional_tests = b.addRunArtifact(light_casters_directional_tests);
    const light_casters_point_tests = b.addTest(.{ .root_module = opts.light_casters_point_mod });
    light_casters_point_tests.step.dependOn(opts.light_casters_shdc_step);
    const run_light_casters_point_tests = b.addRunArtifact(light_casters_point_tests);
    const light_casters_spotlight_tests = b.addTest(.{ .root_module = opts.light_casters_spotlight_mod });
    light_casters_spotlight_tests.step.dependOn(opts.light_casters_shdc_step);
    const run_light_casters_spotlight_tests = b.addRunArtifact(light_casters_spotlight_tests);

    const multiple_lights_tests = b.addTest(.{ .root_module = opts.multiple_lights_mod });
    multiple_lights_tests.step.dependOn(opts.multiple_lights_shdc_step);
    const run_multiple_lights_tests = b.addRunArtifact(multiple_lights_tests);

    const model_loading_tests = b.addTest(.{ .root_module = opts.model_loading_mod });
    model_loading_tests.step.dependOn(opts.model_loading_shdc_step);
    const run_model_loading_tests = b.addRunArtifact(model_loading_tests);

    const triangle_tests = b.addTest(.{
        .root_module = opts.triangle_mod,
    });
    triangle_tests.step.dependOn(opts.triangle_shdc_step);
    const run_triangle_tests = b.addRunArtifact(triangle_tests);

    const texcube_tests = b.addTest(.{
        .root_module = opts.texcube_mod,
    });
    texcube_tests.step.dependOn(opts.texcube_shdc_step);
    const run_texcube_tests = b.addRunArtifact(texcube_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_advanced_data_tests.step);
    test_step.dependOn(&run_advanced_glsl_tests.step);
    test_step.dependOn(&run_geometry_shader_tests.step);
    test_step.dependOn(&run_instancing_tests.step);
    test_step.dependOn(&run_anti_aliasing_tests.step);
    test_step.dependOn(&run_basic_lighting_tests.step);
    test_step.dependOn(&run_box3d_tests.step);
    test_step.dependOn(&run_character_tests.step);
    test_step.dependOn(&run_colors_tests.step);
    test_step.dependOn(&run_cube_tests.step);
    test_step.dependOn(&run_depth_testing_tests.step);
    test_step.dependOn(&run_stencil_testing_tests.step);
    test_step.dependOn(&run_blending_tests.step);
    test_step.dependOn(&run_face_culling_tests.step);
    test_step.dependOn(&run_framebuffers_tests.step);
    test_step.dependOn(&run_cubemaps_tests.step);
    test_step.dependOn(&run_lighting_maps_tests.step);
    test_step.dependOn(&run_light_casters_directional_tests.step);
    test_step.dependOn(&run_light_casters_point_tests.step);
    test_step.dependOn(&run_light_casters_spotlight_tests.step);
    test_step.dependOn(&run_multiple_lights_tests.step);
    test_step.dependOn(&run_model_loading_tests.step);
    test_step.dependOn(&run_materials_tests.step);
    test_step.dependOn(&run_triangle_tests.step);
    test_step.dependOn(&run_texcube_tests.step);
}

fn buildWeb(b: *Build, opts: Options) !void {
    const advanced_data_lib = b.addLibrary(.{
        .name = "ink_ribbon_advanced_data",
        .root_module = opts.advanced_data_mod,
    });
    advanced_data_lib.step.dependOn(opts.advanced_data_shdc_step);

    const advanced_glsl_lib = b.addLibrary(.{
        .name = "ink_ribbon_advanced_glsl",
        .root_module = opts.advanced_glsl_mod,
    });
    advanced_glsl_lib.step.dependOn(opts.advanced_glsl_shdc_step);

    const geometry_shader_lib = b.addLibrary(.{
        .name = "ink_ribbon_geometry_shader",
        .root_module = opts.geometry_shader_mod,
    });
    geometry_shader_lib.step.dependOn(opts.geometry_shader_shdc_step);

    const instancing_lib = b.addLibrary(.{
        .name = "ink_ribbon_instancing",
        .root_module = opts.instancing_mod,
    });
    instancing_lib.step.dependOn(opts.instancing_shdc_step);

    const anti_aliasing_lib = b.addLibrary(.{
        .name = "ink_ribbon_anti_aliasing",
        .root_module = opts.anti_aliasing_mod,
    });
    anti_aliasing_lib.step.dependOn(opts.anti_aliasing_shdc_step);

    const basic_lighting_lib = b.addLibrary(.{
        .name = "ink_ribbon_basic_lighting",
        .root_module = opts.basic_lighting_mod,
    });
    basic_lighting_lib.step.dependOn(opts.basic_lighting_shdc_step);
    const box3d_lib = b.addLibrary(.{
        .name = "ink_ribbon_box3d",
        .root_module = opts.box3d_mod,
    });
    box3d_lib.step.dependOn(opts.box3d_shdc_step);
    const character_lib = b.addLibrary(.{
        .name = "ink_ribbon_character",
        .root_module = opts.character_mod,
    });
    character_lib.step.dependOn(opts.character_shdc_step);
    const colors_lib = b.addLibrary(.{
        .name = "ink_ribbon_colors",
        .root_module = opts.colors_mod,
    });
    colors_lib.step.dependOn(opts.colors_shdc_step);
    const depth_testing_lib = b.addLibrary(.{
        .name = "ink_ribbon_depth_testing",
        .root_module = opts.depth_testing_mod,
    });
    depth_testing_lib.step.dependOn(opts.depth_testing_shdc_step);
    const stencil_testing_lib = b.addLibrary(.{
        .name = "ink_ribbon_stencil_testing",
        .root_module = opts.stencil_testing_mod,
    });
    stencil_testing_lib.step.dependOn(opts.stencil_testing_shdc_step);
    const blending_lib = b.addLibrary(.{
        .name = "ink_ribbon_blending",
        .root_module = opts.blending_mod,
    });
    blending_lib.step.dependOn(opts.blending_shdc_step);
    const face_culling_lib = b.addLibrary(.{
        .name = "ink_ribbon_face_culling",
        .root_module = opts.face_culling_mod,
    });
    face_culling_lib.step.dependOn(opts.face_culling_shdc_step);
    const framebuffers_lib = b.addLibrary(.{
        .name = "ink_ribbon_framebuffers",
        .root_module = opts.framebuffers_mod,
    });
    framebuffers_lib.step.dependOn(opts.framebuffers_shdc_step);
    const cubemaps_lib = b.addLibrary(.{
        .name = "ink_ribbon_cubemaps",
        .root_module = opts.cubemaps_mod,
    });
    cubemaps_lib.step.dependOn(opts.cubemaps_shdc_step);
    const materials_lib = b.addLibrary(.{
        .name = "ink_ribbon_materials",
        .root_module = opts.materials_mod,
    });
    materials_lib.step.dependOn(opts.materials_shdc_step);
    const lighting_maps_lib = b.addLibrary(.{
        .name = "ink_ribbon_lighting_maps",
        .root_module = opts.lighting_maps_mod,
    });
    lighting_maps_lib.step.dependOn(opts.lighting_maps_shdc_step);
    const light_casters_directional_lib = b.addLibrary(.{
        .name = "ink_ribbon_light_casters_directional",
        .root_module = opts.light_casters_directional_mod,
    });
    light_casters_directional_lib.step.dependOn(opts.light_casters_shdc_step);
    const light_casters_point_lib = b.addLibrary(.{
        .name = "ink_ribbon_light_casters_point",
        .root_module = opts.light_casters_point_mod,
    });
    light_casters_point_lib.step.dependOn(opts.light_casters_shdc_step);
    const light_casters_spotlight_lib = b.addLibrary(.{
        .name = "ink_ribbon_light_casters_spotlight",
        .root_module = opts.light_casters_spotlight_mod,
    });
    light_casters_spotlight_lib.step.dependOn(opts.light_casters_shdc_step);
    const multiple_lights_lib = b.addLibrary(.{
        .name = "ink_ribbon_multiple_lights",
        .root_module = opts.multiple_lights_mod,
    });
    multiple_lights_lib.step.dependOn(opts.multiple_lights_shdc_step);
    const model_loading_lib = b.addLibrary(.{
        .name = "ink_ribbon_model_loading",
        .root_module = opts.model_loading_mod,
    });
    model_loading_lib.step.dependOn(opts.model_loading_shdc_step);
    const cube_lib = b.addLibrary(.{
        .name = "ink_ribbon_cube",
        .root_module = opts.cube_mod,
    });
    cube_lib.step.dependOn(opts.cube_shdc_step);
    const triangle_lib = b.addLibrary(.{
        .name = "ink_ribbon_triangle",
        .root_module = opts.triangle_mod,
    });
    triangle_lib.step.dependOn(opts.triangle_shdc_step);
    const texcube_lib = b.addLibrary(.{
        .name = "ink_ribbon_texcube",
        .root_module = opts.texcube_mod,
    });
    texcube_lib.step.dependOn(opts.texcube_shdc_step);

    const emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});

    const advanced_data_link_step = try sokol.emLinkStep(b, .{
        .lib_main = advanced_data_lib,
        .target = opts.advanced_data_mod.resolved_target.?,
        .optimize = opts.advanced_data_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&advanced_data_link_step.step);

    const advanced_glsl_link_step = try sokol.emLinkStep(b, .{
        .lib_main = advanced_glsl_lib,
        .target = opts.advanced_glsl_mod.resolved_target.?,
        .optimize = opts.advanced_glsl_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&advanced_glsl_link_step.step);

    const geometry_shader_link_step = try sokol.emLinkStep(b, .{
        .lib_main = geometry_shader_lib,
        .target = opts.geometry_shader_mod.resolved_target.?,
        .optimize = opts.geometry_shader_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&geometry_shader_link_step.step);

    const instancing_link_step = try sokol.emLinkStep(b, .{
        .lib_main = instancing_lib,
        .target = opts.instancing_mod.resolved_target.?,
        .optimize = opts.instancing_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&instancing_link_step.step);

    const anti_aliasing_link_step = try sokol.emLinkStep(b, .{
        .lib_main = anti_aliasing_lib,
        .target = opts.anti_aliasing_mod.resolved_target.?,
        .optimize = opts.anti_aliasing_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&anti_aliasing_link_step.step);
    const emsdk_include = emsdk.path("upstream/emscripten/cache/sysroot/include");

    // C/C++ dependencies need Emscripten's libc headers, and must wait for the
    // SDK install driven by sokol before compiling.
    const sokol_clib = opts.dep_sokol.artifact("sokol_clib");
    const cimgui_clib = opts.cimgui_lib;
    sokol_clib.step.dependOn(opts.emsdk_install);
    cimgui_clib.root_module.addSystemIncludePath(emsdk_include);
    cimgui_clib.step.dependOn(&sokol_clib.step);
    opts.box3d_lib.root_module.addSystemIncludePath(emsdk_include);
    opts.box3d_lib.step.dependOn(&sokol_clib.step);
    opts.cgltf_lib.root_module.addSystemIncludePath(emsdk_include);
    opts.cgltf_lib.step.dependOn(&sokol_clib.step);

    const box3d_link_step = try sokol.emLinkStep(b, .{
        .lib_main = box3d_lib,
        .target = opts.box3d_mod.resolved_target.?,
        .optimize = opts.box3d_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&box3d_link_step.step);

    const character_link_step = try sokol.emLinkStep(b, .{
        .lib_main = character_lib,
        .target = opts.character_mod.resolved_target.?,
        .optimize = opts.character_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&character_link_step.step);

    const basic_lighting_link_step = try sokol.emLinkStep(b, .{
        .lib_main = basic_lighting_lib,
        .target = opts.basic_lighting_mod.resolved_target.?,
        .optimize = opts.basic_lighting_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&basic_lighting_link_step.step);

    const colors_link_step = try sokol.emLinkStep(b, .{
        .lib_main = colors_lib,
        .target = opts.colors_mod.resolved_target.?,
        .optimize = opts.colors_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&colors_link_step.step);

    const depth_testing_link_step = try sokol.emLinkStep(b, .{
        .lib_main = depth_testing_lib,
        .target = opts.depth_testing_mod.resolved_target.?,
        .optimize = opts.depth_testing_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&depth_testing_link_step.step);

    const stencil_testing_link_step = try sokol.emLinkStep(b, .{
        .lib_main = stencil_testing_lib,
        .target = opts.stencil_testing_mod.resolved_target.?,
        .optimize = opts.stencil_testing_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&stencil_testing_link_step.step);

    const blending_link_step = try sokol.emLinkStep(b, .{
        .lib_main = blending_lib,
        .target = opts.blending_mod.resolved_target.?,
        .optimize = opts.blending_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&blending_link_step.step);

    const face_culling_link_step = try sokol.emLinkStep(b, .{
        .lib_main = face_culling_lib,
        .target = opts.face_culling_mod.resolved_target.?,
        .optimize = opts.face_culling_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&face_culling_link_step.step);

    const framebuffers_link_step = try sokol.emLinkStep(b, .{
        .lib_main = framebuffers_lib,
        .target = opts.framebuffers_mod.resolved_target.?,
        .optimize = opts.framebuffers_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&framebuffers_link_step.step);

    const cubemaps_link_step = try sokol.emLinkStep(b, .{
        .lib_main = cubemaps_lib,
        .target = opts.cubemaps_mod.resolved_target.?,
        .optimize = opts.cubemaps_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        // Six 2048x2048 RGBA faces occupy 96 MiB after JPEG decoding. Leave
        // room for the packed upload buffer, one decoded face, and WebGL.
        .extra_args = &.{ "-sINITIAL_MEMORY=201326592", "-sALLOW_MEMORY_GROWTH=1" },
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&cubemaps_link_step.step);

    const materials_link_step = try sokol.emLinkStep(b, .{
        .lib_main = materials_lib,
        .target = opts.materials_mod.resolved_target.?,
        .optimize = opts.materials_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&materials_link_step.step);

    const lighting_maps_link_step = try sokol.emLinkStep(b, .{
        .lib_main = lighting_maps_lib,
        .target = opts.lighting_maps_mod.resolved_target.?,
        .optimize = opts.lighting_maps_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&lighting_maps_link_step.step);

    const light_casters_directional_link_step = try sokol.emLinkStep(b, .{
        .lib_main = light_casters_directional_lib,
        .target = opts.light_casters_directional_mod.resolved_target.?,
        .optimize = opts.light_casters_directional_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&light_casters_directional_link_step.step);
    const light_casters_point_link_step = try sokol.emLinkStep(b, .{
        .lib_main = light_casters_point_lib,
        .target = opts.light_casters_point_mod.resolved_target.?,
        .optimize = opts.light_casters_point_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&light_casters_point_link_step.step);
    const light_casters_spotlight_link_step = try sokol.emLinkStep(b, .{
        .lib_main = light_casters_spotlight_lib,
        .target = opts.light_casters_spotlight_mod.resolved_target.?,
        .optimize = opts.light_casters_spotlight_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&light_casters_spotlight_link_step.step);

    const multiple_lights_link_step = try sokol.emLinkStep(b, .{
        .lib_main = multiple_lights_lib,
        .target = opts.multiple_lights_mod.resolved_target.?,
        .optimize = opts.multiple_lights_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&multiple_lights_link_step.step);

    const model_loading_link_step = try sokol.emLinkStep(b, .{
        .lib_main = model_loading_lib,
        .target = opts.model_loading_mod.resolved_target.?,
        .optimize = opts.model_loading_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        // The asynchronous fetch buffers and cgltf scene allocations need
        // more than Emscripten's small default heap during loading.
        .extra_args = &.{ "-sINITIAL_MEMORY=67108864", "-sALLOW_MEMORY_GROWTH=1" },
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    const install_model_gltf = b.addInstallFileWithDir(b.path("src/examples/assets/backpack/backpack.gltf"), .{ .custom = "web" }, "backpack.gltf");
    const install_model_vertices = b.addInstallFileWithDir(b.path("src/examples/assets/backpack/vertices.bin"), .{ .custom = "web" }, "vertices.bin");
    const install_model_diffuse = b.addInstallFileWithDir(b.path("src/examples/assets/backpack/diffuse.png"), .{ .custom = "web" }, "diffuse.png");
    const install_model_specular = b.addInstallFileWithDir(b.path("src/examples/assets/backpack/specular.png"), .{ .custom = "web" }, "specular.png");
    model_loading_link_step.step.dependOn(&install_model_gltf.step);
    model_loading_link_step.step.dependOn(&install_model_vertices.step);
    model_loading_link_step.step.dependOn(&install_model_diffuse.step);
    model_loading_link_step.step.dependOn(&install_model_specular.step);
    b.getInstallStep().dependOn(&model_loading_link_step.step);

    const cube_link_step = try sokol.emLinkStep(b, .{
        .lib_main = cube_lib,
        .target = opts.cube_mod.resolved_target.?,
        .optimize = opts.cube_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&cube_link_step.step);

    const triangle_link_step = try sokol.emLinkStep(b, .{
        .lib_main = triangle_lib,
        .target = opts.triangle_mod.resolved_target.?,
        .optimize = opts.triangle_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&triangle_link_step.step);

    const texcube_link_step = try sokol.emLinkStep(b, .{
        .lib_main = texcube_lib,
        .target = opts.texcube_mod.resolved_target.?,
        .optimize = opts.texcube_mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&texcube_link_step.step);

    const run_advanced_data = sokol.emRunStep(b, .{ .name = "ink_ribbon_advanced_data", .emsdk = emsdk });
    run_advanced_data.step.dependOn(&advanced_data_link_step.step);
    b.step("run-advanced-data", "Run the LearnOpenGL Advanced Data example").dependOn(&run_advanced_data.step);

    const run_advanced_glsl = sokol.emRunStep(b, .{ .name = "ink_ribbon_advanced_glsl", .emsdk = emsdk });
    run_advanced_glsl.step.dependOn(&advanced_glsl_link_step.step);
    b.step("run-advanced-glsl", "Run the LearnOpenGL Advanced GLSL example").dependOn(&run_advanced_glsl.step);

    const run_geometry_shader = sokol.emRunStep(b, .{ .name = "ink_ribbon_geometry_shader", .emsdk = emsdk });
    run_geometry_shader.step.dependOn(&geometry_shader_link_step.step);
    b.step("run-geometry-shader", "Run the LearnOpenGL Geometry Shader ideas example").dependOn(&run_geometry_shader.step);

    const run_instancing = sokol.emRunStep(b, .{ .name = "ink_ribbon_instancing", .emsdk = emsdk });
    run_instancing.step.dependOn(&instancing_link_step.step);
    b.step("run-instancing", "Run the LearnOpenGL Instancing example").dependOn(&run_instancing.step);

    const run_anti_aliasing = sokol.emRunStep(b, .{ .name = "ink_ribbon_anti_aliasing", .emsdk = emsdk });
    run_anti_aliasing.step.dependOn(&anti_aliasing_link_step.step);
    b.step("run-anti-aliasing", "Run the LearnOpenGL Anti-Aliasing example").dependOn(&run_anti_aliasing.step);

    const run_box3d = sokol.emRunStep(b, .{ .name = "ink_ribbon_box3d", .emsdk = emsdk });
    run_box3d.step.dependOn(&box3d_link_step.step);
    b.step("run-box3d", "Run the Box3D example").dependOn(&run_box3d.step);
    b.step("run", "Run the Box3D example").dependOn(&run_box3d.step);

    const run_character = sokol.emRunStep(b, .{ .name = "ink_ribbon_character", .emsdk = emsdk });
    run_character.step.dependOn(&character_link_step.step);
    b.step("run-character", "Run the character mover scene").dependOn(&run_character.step);

    const run_basic_lighting = sokol.emRunStep(b, .{ .name = "ink_ribbon_basic_lighting", .emsdk = emsdk });
    run_basic_lighting.step.dependOn(&basic_lighting_link_step.step);
    b.step("run-basic-lighting", "Run the LearnOpenGL Basic Lighting example").dependOn(&run_basic_lighting.step);

    const run_colors = sokol.emRunStep(b, .{ .name = "ink_ribbon_colors", .emsdk = emsdk });
    run_colors.step.dependOn(&colors_link_step.step);
    b.step("run-colors", "Run the LearnOpenGL Colors example").dependOn(&run_colors.step);

    const run_depth_testing = sokol.emRunStep(b, .{ .name = "ink_ribbon_depth_testing", .emsdk = emsdk });
    run_depth_testing.step.dependOn(&depth_testing_link_step.step);
    b.step("run-depth-testing", "Run the LearnOpenGL Depth Testing example").dependOn(&run_depth_testing.step);

    const run_stencil_testing = sokol.emRunStep(b, .{ .name = "ink_ribbon_stencil_testing", .emsdk = emsdk });
    run_stencil_testing.step.dependOn(&stencil_testing_link_step.step);
    b.step("run-stencil-testing", "Run the LearnOpenGL Stencil Testing example").dependOn(&run_stencil_testing.step);

    const run_blending = sokol.emRunStep(b, .{ .name = "ink_ribbon_blending", .emsdk = emsdk });
    run_blending.step.dependOn(&blending_link_step.step);
    b.step("run-blending", "Run the LearnOpenGL Blending example").dependOn(&run_blending.step);

    const run_face_culling = sokol.emRunStep(b, .{ .name = "ink_ribbon_face_culling", .emsdk = emsdk });
    run_face_culling.step.dependOn(&face_culling_link_step.step);
    b.step("run-face-culling", "Run the LearnOpenGL Face Culling example").dependOn(&run_face_culling.step);

    const run_framebuffers = sokol.emRunStep(b, .{ .name = "ink_ribbon_framebuffers", .emsdk = emsdk });
    run_framebuffers.step.dependOn(&framebuffers_link_step.step);
    b.step("run-framebuffers", "Run the LearnOpenGL Framebuffers example").dependOn(&run_framebuffers.step);

    const run_cubemaps = sokol.emRunStep(b, .{ .name = "ink_ribbon_cubemaps", .emsdk = emsdk });
    run_cubemaps.step.dependOn(&cubemaps_link_step.step);
    b.step("run-cubemaps", "Run the LearnOpenGL Cubemaps example").dependOn(&run_cubemaps.step);

    const run_materials = sokol.emRunStep(b, .{ .name = "ink_ribbon_materials", .emsdk = emsdk });
    run_materials.step.dependOn(&materials_link_step.step);
    b.step("run-materials", "Run the LearnOpenGL Materials example").dependOn(&run_materials.step);

    const run_lighting_maps = sokol.emRunStep(b, .{ .name = "ink_ribbon_lighting_maps", .emsdk = emsdk });
    run_lighting_maps.step.dependOn(&lighting_maps_link_step.step);
    b.step("run-lighting-maps", "Run the LearnOpenGL Lighting Maps example").dependOn(&run_lighting_maps.step);

    const run_light_casters_directional = sokol.emRunStep(b, .{ .name = "ink_ribbon_light_casters_directional", .emsdk = emsdk });
    run_light_casters_directional.step.dependOn(&light_casters_directional_link_step.step);
    b.step("run-light-casters-directional", "Run the LearnOpenGL Directional Light example").dependOn(&run_light_casters_directional.step);
    const run_light_casters_point = sokol.emRunStep(b, .{ .name = "ink_ribbon_light_casters_point", .emsdk = emsdk });
    run_light_casters_point.step.dependOn(&light_casters_point_link_step.step);
    b.step("run-light-casters-point", "Run the LearnOpenGL Point Light example").dependOn(&run_light_casters_point.step);
    const run_light_casters_spotlight = sokol.emRunStep(b, .{ .name = "ink_ribbon_light_casters_spotlight", .emsdk = emsdk });
    run_light_casters_spotlight.step.dependOn(&light_casters_spotlight_link_step.step);
    b.step("run-light-casters-spotlight", "Run the LearnOpenGL Spotlight example").dependOn(&run_light_casters_spotlight.step);
    b.step("run-light-casters", "Run the LearnOpenGL Spotlight example").dependOn(&run_light_casters_spotlight.step);

    const run_multiple_lights = sokol.emRunStep(b, .{ .name = "ink_ribbon_multiple_lights", .emsdk = emsdk });
    run_multiple_lights.step.dependOn(&multiple_lights_link_step.step);
    b.step("run-multiple-lights", "Run the LearnOpenGL Multiple Lights example").dependOn(&run_multiple_lights.step);

    const run_model_loading = sokol.emRunStep(b, .{ .name = "ink_ribbon_model_loading", .emsdk = emsdk });
    run_model_loading.step.dependOn(&model_loading_link_step.step);
    b.step("run-model-loading", "Run the LearnOpenGL Model Loading example").dependOn(&run_model_loading.step);

    const run_cube = sokol.emRunStep(b, .{ .name = "ink_ribbon_cube", .emsdk = emsdk });
    run_cube.step.dependOn(&cube_link_step.step);
    b.step("run-cube", "Run the spinning cube example").dependOn(&run_cube.step);

    const run_triangle = sokol.emRunStep(b, .{ .name = "ink_ribbon_triangle", .emsdk = emsdk });
    run_triangle.step.dependOn(&triangle_link_step.step);
    b.step("run-triangle", "Run the triangle example").dependOn(&run_triangle.step);

    const run_texcube = sokol.emRunStep(b, .{ .name = "ink_ribbon_texcube", .emsdk = emsdk });
    run_texcube.step.dependOn(&texcube_link_step.step);
    b.step("run-texcube", "Run the textured cube example").dependOn(&run_texcube.step);
}
