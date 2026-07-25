//------------------------------------------------------------------------------
//  main.zig
//
//  Renders a rotating colored cube in a window.
//
//  Graphics concepts:
//    GPU          - Specialized processor for graphics. You send it data/commands,
//                   it draws pixels.
//    Shader       - Small program that runs on the GPU. Vertex shader runs once per
//                   vertex (point), fragment shader runs once per pixel.
//    Vertex       - A single point in 3D space. 7 floats each: x,y,z,r,g,b,a.
//    Vertex buffer - GPU memory holding vertex data. Sent once, reused every frame.
//    Index buffer  - List of vertex indices that assemble into triangles.
//                    Every 3 consecutive indices = 1 triangle (triangle list).
//    Pipeline     - GPU state controlling HOW to draw: which shader, vertex layout,
//                   depth testing, face culling. Created once at startup.
//    Uniform      - Value constant across all vertices/pixels in a draw call.
//                   The MVP matrix is sent as a uniform.
//    MVP matrix   - Model x View x Projection. Transforms vertices from object-local
//                   space into screen coordinates.
//      Model       - Rotates/translates the object in the world.
//      View        - Positions the camera (where you're looking from).
//      Projection  - Adds perspective (far things look smaller).
//    Pass         - A rendering pass: begin, apply state, draw, end.
//    Swapchain    - Queue of 2-3 framebuffers swapping each frame to avoid tearing.
//
//  Coordinate system: Right-handed, Y-up. +X=right, +Y=up, +Z=toward viewer.
//------------------------------------------------------------------------------

// Import the sokol Zig bindings module.
const sokol = @import("sokol");

// Shorthand aliases for sokol submodules.
const slog = sokol.log; // logging
const sg = sokol.gfx; // graphics/gpu commands (draw, makeBuffer, etc.)
const sapp = sokol.app; // windowing, events, frame timing
const sglue = sokol.glue; // bridge between sokol_app and sokol_gfx (swapchain, environment)
const sdtx = sokol.debugtext;

// 3D vector and 4x4 matrix types from a local math library.
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;

// Compiled shader generated from cube.glsl by sokol-shdc.
// Contains the shader binary for each GPU backend, plus Zig constants
// for uniform slot indices (UB_vs_params) and vertex attribute indices
// (ATTR_cube_position, ATTR_cube_color0).
const shd = @import("generated/cube_shader.zig");

// Global mutable state for the application.
// Zig globals in a struct act like C file-scope statics.
const state = struct {
    // Rotation angles around X and Y axes (in degrees). Incremented each frame.
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;

    // Pipeline: shader + GPU state (depth test, face culling, vertex layout).
    var pip: sg.Pipeline = .{};

    // Bindings: the vertex buffer and index buffer attached to the pipeline.
    var bind: sg.Bindings = .{};

    // What to do at the start of each rendering pass (clear the screen to a color).
    var pass_action: sg.PassAction = .{};

    // View matrix: positions the camera. Camera sits at (0, 1.5, 6) looking at
    // the origin (0,0,0) with Y pointing up. Computed once, never changes.
    const view: mat4 = mat4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, vec3.zero(), vec3.up());
};

//------------------------------------------------------------------------------
// Called once at startup by the sokol runtime (via sapp.run below).
// Sets up the GPU: buffers, shader, pipeline, clear color.
//------------------------------------------------------------------------------
export fn init() void {
    // Initialize sokol_gfx. Queries the window system (Metal/D3D/GL/Vulkan)
    // handles via sglue and routes log messages through sokol's logger.
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    sdtx.setup(.{
        .fonts = init: {
            var f: [8]sdtx.FontDesc = @splat(.{});
            f[0] = sdtx.fontKc853();
            break :init f;
        },
        .logger = .{ .func = slog.func },
    });

    //--- Vertex buffer -------------------------------------------------------
    // Upload cube geometry to GPU memory.
    // vertex_buffers is an array (sokol supports up to 8 vertex buffer slots).
    // Slot [0] is used because the shader only needs one vertex buffer.
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            // zig fmt: off
            // 24 vertices. Each vertex = 7 floats: x, y, z, r, g, b, a.
            // Colors are baked into the vertex data (no lighting/textures).
            // The cube spans from -1 to 1 on all axes, centered at origin.

            // positions        colors
            // Face 1: Red, facing -Z (visible from camera at z=6 looking inward)
            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // bottom-left
             1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // bottom-right
             1.0,  1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // top-right
            -1.0,  1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // top-left

            // Face 2: Green, facing +Z
            -1.0, -1.0,  1.0, 0.0, 1.0, 0.0, 1.0,
             1.0, -1.0,  1.0, 0.0, 1.0, 0.0, 1.0,
             1.0,  1.0,  1.0, 0.0, 1.0, 0.0, 1.0,
            -1.0,  1.0,  1.0, 0.0, 1.0, 0.0, 1.0,

            // Face 3: Blue, facing -X
            -1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0,  1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0,  1.0,  1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0, -1.0,  1.0, 0.0, 0.0, 1.0, 1.0,

            // Face 4: Orange, facing +X
             1.0, -1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
             1.0,  1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
             1.0,  1.0,  1.0, 1.0, 0.5, 0.0, 1.0,
             1.0, -1.0,  1.0, 1.0, 0.5, 0.0, 1.0,

            // Face 5: Cyan, facing -Y (bottom)
            -1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,
            -1.0, -1.0,  1.0, 0.0, 0.5, 1.0, 1.0,
             1.0, -1.0,  1.0, 0.0, 0.5, 1.0, 1.0,
             1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,

            // Face 6: Purple, facing +Y (top)
            -1.0,  1.0, -1.0, 1.0, 0.0, 0.5, 1.0,
            -1.0,  1.0,  1.0, 1.0, 0.0, 0.5, 1.0,
             1.0,  1.0,  1.0, 1.0, 0.0, 0.5, 1.0,
             1.0,  1.0, -1.0, 1.0, 0.0, 0.5, 1.0,
            // zig fmt: on
        }),
    });

    //--- Index buffer --------------------------------------------------------
    // 36 u16 indices forming 12 triangles (2 per face).
    // GPUs only draw triangles, so each square face is split into 2 triangles
    // along a diagonal. Every 3 consecutive indices = 1 triangle (triangle list).
    // Triangle 1: bottom-left -> bottom-right -> top-right (indices 0,1,2)
    // Triangle 2: bottom-left -> top-right -> top-left (indices 0,2,3)
    // Coincides share the common diagonal edge.
    // Winding: counter-clockwise = front face, clockwise = back face (culled).

    state.bind.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(&[_]u16{
            // zig fmt: off
            0,  1,  2,  0,  2,  3,   // Face 1: red, -Z
            6,  5,  4,  7,  6,  4,   // Face 2: green, +Z
            8,  9,  10, 8,  10, 11,  // Face 3: blue, -X
            14, 13, 12, 15, 14, 12,  // Face 4: orange, +X
            16, 17, 18, 16, 18, 19,  // Face 5: cyan, -Y (bottom)
            22, 21, 20, 23, 22, 20,  // Face 6: purple, +Y (top)
            // zig fmt: on
        }),
    });

    //--- Pipeline ------------------------------------------------------------
    // Create the rendering pipeline: the shader and all fixed-function GPU state.
    state.pip = sg.makePipeline(.{
        // Compile and load the right shader variant for the current GPU backend
        // (GL/Metal/D3D11/Vulkan). cubeShaderDesc() comes from the generated
        // cube.glsl.zig.
        .shader = sg.makeShader(shd.cubeShaderDesc(sg.queryBackend())),

        // Describe the vertex memory layout so the GPU knows which floats are
        // positions and which are colors.
        .layout = init: {
            var l = sg.VertexLayoutState{};
            // Attribute 0: position -- 3 floats (x, y, z)
            l.attrs[shd.ATTR_cube_position].format = .FLOAT3;
            // Attribute 1: color -- 4 floats (r, g, b, a)
            l.attrs[shd.ATTR_cube_color0].format = .FLOAT4;
            break :init l;
        },

        // Indices are 16-bit unsigned integers.
        .index_type = .UINT16,

        // Depth testing: closer pixels occlude farther ones.
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },

        // Cull back faces (triangles facing away from the camera).
        // Counter-clockwise = front, clockwise = back (discarded).
        .cull_mode = .BACK,

        // Alpha blending: color_count must be set (default is 0 = no color targets).
        // Blending is per-color-target, configured inside .colors[0].blend.
        // Standard alpha blending: result = src * src_alpha + dst * (1 - src_alpha).
        .color_count = 1,
        .colors = init: {
            var clrs: [8]sg.ColorTargetState = @splat(.{});
            clrs[0].blend = .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
            };
            break :init clrs;
        },
    });

    //--- Clear color ---------------------------------------------------------
    // At the start of each frame, clear the screen to this blue-purple color
    // before drawing the cube on top.
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.5, .b = 0.75, .a = 1 },
    };
}

//------------------------------------------------------------------------------
// Called every frame (~60 times/sec) by the sokol runtime.
// Updates rotation, computes the MVP matrix (Model x View x Projection),
// and issues a draw call to render the cube.
//------------------------------------------------------------------------------
export fn frame() void {
    const frame_dt = sapp.frameDuration();
    // Get frame duration (in seconds) multiplied by 60 to normalize speed.
    // This makes rotation independent of framerate.
    const dt: f32 = @floatCast(frame_dt * 60);
    const fps: f64 = if (frame_dt > 0) 1.0 / frame_dt else 0;

    sdtx.canvas(sapp.widthf(), sapp.heightf());
    sdtx.pos(1, 1);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:.1}\nFrame: {d:.3}ms", .{ fps, frame_dt * 1000 });

    // Increment rotation angles. Y rotates twice as fast as X.
    state.rx += 1.0 * dt;
    state.ry += 2.0 * dt;

    // Compute the MVP (Model-View-Projection) matrix for the current frame.
    // This uniform is sent to the vertex shader to transform each vertex
    // from object-local space -> world space -> camera space -> screen space.
    const vs_params = computeVsParams(state.rx, state.ry);

    //--- Rendering pass ------------------------------------------------------
    // Begin a pass: clear the screen using state.pass_action, target the
    // swapchain (back buffer that gets swapped to the display each frame).
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    // Activate the pipeline (shader + GPU state).
    sg.applyPipeline(state.pip);

    // Bind the vertex buffer and index buffer so the GPU knows the geometry.
    sg.applyBindings(state.bind);

    // Send the MVP matrix uniform to the vertex shader.
    // UB_vs_params is the uniform block binding slot (layout(binding=0) in the GLSL).
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));

    // Draw 36 indices (= 12 triangles = 6 faces), starting at index 0, 1 instance.
    sg.draw(0, 36, 1);

    sdtx.draw();

    // End the pass and submit all commands to the GPU for execution.
    sg.endPass();
    sg.commit();
}

//------------------------------------------------------------------------------
// Called once when the window closes.
// Releases all GPU resources.
//------------------------------------------------------------------------------
export fn cleanup() void {
    sdtx.shutdown();
    sg.shutdown();
}

//------------------------------------------------------------------------------
// Program entry point.
// Opens a fullscreen borderless window with 4x MSAA (anti-aliasing), wires up
// the three callbacks (init, frame, cleanup), and enters the sokol event loop.
//------------------------------------------------------------------------------
pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .fullscreen = true,
        .sample_count = 4, // 4x multisampling for smoother edges
        .icon = .{ .sokol_default = true },
        .window_title = "ink-ribbon-sokol",
        .logger = .{ .func = slog.func },
    });
}

//------------------------------------------------------------------------------
// Build the MVP (Model-View-Projection) matrix each frame:
//   1. Build an X-axis rotation matrix
//   2. Build a Y-axis rotation matrix
//   3. Combine them: model = rx_rotation x ry_rotation
//   4. Build a perspective projection (60 degree field of view, matches screen aspect,
//      clipping range 0.01 to 10.0)
//   5. Combine: result = projection x view x model
//
// Returns a VsParams struct containing the final MVP matrix for the vertex shader.
// The uniforms block is sent to the vertex shader via sg.applyUniforms.
//------------------------------------------------------------------------------
fn computeVsParams(rx: f32, ry: f32) shd.VsParams {
    // Rotation matrix around the X axis.
    const rxm = mat4.rotate(rx, .{ .x = 1.0, .y = 0.0, .z = 0.0 });

    // Rotation matrix around the Y axis.
    const rym = mat4.rotate(ry, .{ .x = 0.0, .y = 1.0, .z = 0.0 });

    // Model matrix: combines both rotations (applied to the cube). The cube
    // is centered at the origin, so rotation spins it around its own center.
    const model = mat4.mul(rxm, rym);

    // Screen aspect ratio -- needed so the perspective projection doesn't stretch.
    const aspect = sapp.widthf() / sapp.heightf();

    // Perspective projection: 60 degree field of view, objects closer than 0.01 or
    // farther than 10.0 are clipped (not drawn).
    const proj = mat4.persp(60.0, aspect, 0.01, 10.0);

    // Combine: projection x view x model.
    //   model   -- rotates the cube (object -> world space)
    //   view    -- positions the camera (world -> camera/eye space)
    //   proj    -- applies perspective (camera -> screen/clip space)
    return shd.VsParams{ .mvp = mat4.mul(mat4.mul(proj, state.view), model) };
}
