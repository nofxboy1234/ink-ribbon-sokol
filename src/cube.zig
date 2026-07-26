//------------------------------------------------------------------------------
// Spinning cube: a small sokol graphics walkthrough
//
// This example shows the basic path from CPU data to pixels:
//
//   CPU setup                           GPU work each frame
//   -----------------------------       --------------------------------------
//   create cube vertices/indices   ->   vertex shader transforms each vertex
//   create a graphics pipeline          triangles are assembled and rasterized
//   calculate a rotation matrix    ->   fragment shader colors covered pixels
//
// The mesh and pipeline are created once. Each frame only the rotation matrix
// changes, so the same GPU resources can be reused efficiently.
//
// Coordinate system: right-handed and Y-up. The cube is centered at the origin,
// spans from -1 to +1 on each axis, and the camera looks toward it from +Z.
//------------------------------------------------------------------------------

// The sokol-zig package provides portable windowing, graphics, logging, and
// helper modules. Sokol selects the platform backend (OpenGL, Metal, D3D11,
// WebGL, and so on) while this application code stays the same.
const sokol = @import("sokol");

// Short aliases keep graphics code readable.
const slog = sokol.log; // Sends sokol messages to the console.
const sg = sokol.gfx; // Portable GPU API: buffers, pipelines, passes, and draws.
const sapp = sokol.app; // Window, application lifecycle, and frame timing.
const sglue = sokol.glue; // Connects sapp's window/context to sokol_gfx.
const sdtx = sokol.debugtext; // Simple GPU-rendered text for the FPS display.

// The local math library supplies vectors and 4x4 transformation matrices.
const vec3 = @import("cube_math.zig").Vec3;
const mat4 = @import("cube_math.zig").Mat4;

// sokol-shdc generated this Zig module from src/cube.glsl. It contains:
//   - a shader variant for each graphics backend;
//   - typed uniform structs such as VsParams;
//   - constants identifying shader inputs and uniform binding slots.
const shd = @import("generated/cube_shader.zig");

//------------------------------------------------------------------------------
// Application state
//
// GPU objects are represented by small sokol handles. The backend owns their
// actual memory; these values identify which resources later commands should use.
//------------------------------------------------------------------------------
const state = struct {
    // Current model rotation around the X and Y axes, measured in degrees.
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;

    // A pipeline packages the shader and fixed rendering rules: vertex layout,
    // depth testing, face culling, blending, and render-target formats.
    var pip: sg.Pipeline = .{};

    // Bindings connect resources such as buffers and textures to shader inputs.
    // This example needs one vertex buffer and one index buffer.
    var bind: sg.Bindings = .{};

    // A pass action describes how render targets begin a pass. Here it clears the
    // previous frame before the new cube is drawn.
    var pass_action: sg.PassAction = .{};

    // The view matrix represents the camera. It sits at (0, 1.5, 6), looks at the
    // origin, and treats +Y as up. Because the camera never moves, compute it once.
    const view: mat4 = mat4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, vec3.zero(), vec3.up());
};

//------------------------------------------------------------------------------
// Initialization
//
// sokol_app calls init once after it has created the window and graphics context.
// This is where long-lived GPU resources are created.
// `export` gives the callback a stable C-visible symbol for native and WASM glue.
//------------------------------------------------------------------------------
export fn init() void {
    // Initialize the portable graphics layer. sokol_glue supplies the native
    // device/context created by sokol_app; sokol_log reports backend errors.
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // Initialize sokol_debugtext for the FPS counter. It supports eight font
    // slots; this demo places the built-in KC853 font in slot zero.
    sdtx.setup(.{
        // `init:` is a labeled expression block. It lets us prepare the fixed
        // array locally, then `break :init f` returns that array as the value of
        // the `.fonts` field.
        .fonts = init: {
            var f: [8]sdtx.FontDesc = @splat(.{});
            f[0] = sdtx.fontKc853();
            break :init f;
        },
        .logger = .{ .func = slog.func },
    });

    //--------------------------------------------------------------------------
    // Vertex buffer
    //
    // A vertex is one point supplied to the vertex shader. This buffer interleaves
    // two attributes for every vertex:
    //
    //   position: x, y, z       3 floats
    //   color:    r, g, b, a    4 floats
    //
    // "Interleaved" means position and color for vertex 0 are adjacent, followed
    // by position and color for vertex 1, and so on. makeBuffer copies this
    // immutable array into GPU-accessible memory.
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            // zig fmt: off
            // A geometric cube has only eight unique corners, but this array uses
            // 24 vertices: four for each face. Duplicating corners lets adjacent
            // faces give the same position a different color.
            //
            // Colors are stored directly in the mesh. There are no lights or
            // textures in this simple shader.

            // positions        colors
            // Face 1: red, facing -Z.
            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // bottom-left
             1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // bottom-right
             1.0,  1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // top-right
            -1.0,  1.0, -1.0, 1.0, 0.0, 0.0, 1.0, // top-left

            // Face 2: green, facing +Z.
            -1.0, -1.0,  1.0, 0.0, 1.0, 0.0, 1.0,
             1.0, -1.0,  1.0, 0.0, 1.0, 0.0, 1.0,
             1.0,  1.0,  1.0, 0.0, 1.0, 0.0, 1.0,
            -1.0,  1.0,  1.0, 0.0, 1.0, 0.0, 1.0,

            // Face 3: blue, facing -X.
            -1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0,  1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0,  1.0,  1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0, -1.0,  1.0, 0.0, 0.0, 1.0, 1.0,

            // Face 4: orange, facing +X.
             1.0, -1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
             1.0,  1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
             1.0,  1.0,  1.0, 1.0, 0.5, 0.0, 1.0,
             1.0, -1.0,  1.0, 1.0, 0.5, 0.0, 1.0,

            // Face 5: cyan, facing -Y (bottom).
            -1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,
            -1.0, -1.0,  1.0, 0.0, 0.5, 1.0, 1.0,
             1.0, -1.0,  1.0, 0.0, 0.5, 1.0, 1.0,
             1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,

            // Face 6: magenta, facing +Y (top).
            -1.0,  1.0, -1.0, 1.0, 0.0, 0.5, 1.0,
            -1.0,  1.0,  1.0, 1.0, 0.0, 0.5, 1.0,
             1.0,  1.0,  1.0, 1.0, 0.0, 0.5, 1.0,
             1.0,  1.0, -1.0, 1.0, 0.0, 0.5, 1.0,
            // zig fmt: on
        }),
    });

    //--------------------------------------------------------------------------
    // Index buffer
    //
    // GPUs render triangles. Each square face is split into two triangles, so the
    // cube has 6 faces * 2 triangles * 3 indices = 36 indices.
    //
    // An index refers to a vertex in the buffer above. Reusing indices avoids
    // repeating the two shared vertices along a face's diagonal.
    //
    // Vertex order is called winding. Viewed from the front, these triangles are
    // counter-clockwise; the pipeline can therefore discard clockwise back faces.
    state.bind.index_buffer = sg.makeBuffer(.{
        // Mark this buffer as indices rather than ordinary vertex data.
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

    //--------------------------------------------------------------------------
    // Graphics pipeline
    //
    // The pipeline tells the GPU how to interpret buffers and turn triangles into
    // pixels. It is created once because none of these rules change per frame.
    state.pip = sg.makePipeline(.{
        // queryBackend selects the shader variant for the active backend. The
        // vertex shader transforms positions and forwards colors; the fragment
        // shader writes that interpolated color for each covered pixel.
        .shader = sg.makeShader(shd.cubeShaderDesc(sg.queryBackend())),

        // Map bytes in vertex-buffer slot 0 to the shader's named attributes.
        // Because no offsets/stride are specified, sokol calculates the
        // interleaved FLOAT3 + FLOAT4 layout automatically.
        .layout = init: {
            // Another labeled block builds a temporary layout value and returns
            // it directly into the pipeline descriptor.
            var l = sg.VertexLayoutState{};
            // Position consumes three consecutive 32-bit floats.
            l.attrs[shd.ATTR_cube_position].format = .FLOAT3;
            // Color immediately follows and consumes four floats.
            l.attrs[shd.ATTR_cube_color0].format = .FLOAT4;
            break :init l;
        },

        // Match the u16 type used by the index array.
        .index_type = .UINT16,

        // The depth buffer stores how far away the nearest drawn surface is at
        // each pixel. LESS_EQUAL lets a new fragment pass if it is no farther
        // away, and write_enabled records its depth for later triangles.
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },

        // Skip triangles facing away from the camera. Their pixels cannot be seen
        // on this closed cube, so culling avoids unnecessary fragment work.
        .cull_mode = .BACK,

        // This pass writes to one color target: the window's back buffer.
        .color_count = 1,
        .colors = init: {
            // Sokol descriptors use fixed-size arrays for portability. Initialize
            // every possible target to defaults, customize target 0, and return it.
            var clrs: [8]sg.ColorTargetState = @splat(.{});

            // Alpha blending combines a new source color with the color already
            // in the framebuffer:
            //
            // result = source * source_alpha + destination * (1 - source_alpha)
            //
            // Every cube vertex currently has alpha 1, so it remains opaque; the
            // state is useful if those alpha values are changed later.
            clrs[0].blend = .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
            };
            break :init clrs;
        },
    });

    // Begin every display pass by replacing the old framebuffer contents with a
    // blue background. Without CLEAR, pixels not covered this frame could retain
    // stale or undefined data.
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.5, .b = 0.75, .a = 1 },
    };
}

//------------------------------------------------------------------------------
// Frame rendering
//
// sokol_app calls frame repeatedly. A frame records GPU commands in this order:
// begin a pass, apply pipeline/resources/uniforms, draw, end, then commit.
// Like init and cleanup, it is exported for sokol's platform glue.
//------------------------------------------------------------------------------
export fn frame() void {
    // Frame duration is real elapsed time in seconds. Multiplying by 60 expresses
    // it relative to an ideal 60 Hz frame: about 1.0 at 60 Hz, 2.0 at 30 Hz.
    const frame_dt = sapp.frameDuration();
    const dt: f32 = @floatCast(frame_dt * 60);

    // FPS is the reciprocal of seconds per frame. Guard zero to avoid division
    // by zero during unusual startup/timing conditions.
    const fps: f64 = if (frame_dt > 0) 1.0 / frame_dt else 0;

    // Prepare a screen-sized text canvas and queue a white performance readout.
    // sdtx.draw below turns this queued text into GPU draw commands.
    sdtx.canvas(sapp.widthf(), sapp.heightf());
    sdtx.pos(1, 1);
    sdtx.color3b(255, 255, 255);
    sdtx.print("FPS: {d:.1}\nFrame: {d:.3}ms", .{ fps, frame_dt * 1000 });

    // Advance both angles using elapsed time rather than a fixed amount per
    // frame. This keeps rotation speed consistent across different refresh rates.
    // Y rotates twice as quickly as X.
    state.rx += 1.0 * dt;
    state.ry += 2.0 * dt;

    // Build the current model-view-projection matrix. A uniform is a small value
    // shared by all shader invocations in one draw call; unlike vertex data, it
    // does not vary from vertex to vertex.
    const vs_params = computeVsParams(state.rx, state.ry);

    // Begin the on-screen render pass. A swapchain manages displayable images:
    // the GPU renders into a back buffer while another image may be on screen,
    // then the completed image is presented.
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });

    // Select the shaders and fixed graphics state created during init.
    sg.applyPipeline(state.pip);

    // Connect the cube's vertex and index buffers to that pipeline.
    sg.applyBindings(state.bind);

    // Upload the matrix to the binding slot generated from cube.glsl's
    // `vs_params` block. sg.asRange describes the struct's address and byte size.
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));

    // Consume 36 indices starting at index 0. Instance count 1 means draw one
    // copy of the mesh. The GPU assembles 12 triangles and rasterizes them.
    sg.draw(0, 36, 1);

    // Draw the queued FPS text in the same pass so it appears over the cube.
    sdtx.draw();

    // Finish recording this pass, then submit the complete frame to the backend.
    sg.endPass();
    sg.commit();
}

//------------------------------------------------------------------------------
// Cleanup
//
// sokol_app calls cleanup once as the program exits. Shut helpers down before the
// graphics device they use. Sokol releases the buffers and pipeline with sg.
//------------------------------------------------------------------------------
export fn cleanup() void {
    sdtx.shutdown();
    sg.shutdown();
}

//------------------------------------------------------------------------------
// Entry point
//------------------------------------------------------------------------------
pub fn main() void {
    // sokol_app owns the platform-specific event loop. The application supplies
    // lifecycle callbacks and a portable window description.
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        // Fullscreen uses the current display rather than a normal window.
        .fullscreen = true,
        // Four samples per pixel provide multisample anti-aliasing (MSAA), which
        // smooths jagged triangle edges before the image is presented.
        .sample_count = 4,
        .icon = .{ .sokol_default = true },
        .window_title = "ink-ribbon-sokol",
        .logger = .{ .func = slog.func },
    });
}

//------------------------------------------------------------------------------
// Transform construction
//
// A vertex begins in model/local space: coordinates relative to the cube's own
// center. Three transformations move it toward the final screen:
//
//   model       rotates the cube in the 3D world
//   view        expresses the world relative to the camera
//   projection  applies perspective and maps the view into GPU clip space
//
// The combined MVP matrix lets the vertex shader perform all three with one
// matrix-vector multiplication.
//------------------------------------------------------------------------------
fn computeVsParams(rx: f32, ry: f32) shd.VsParams {
    // Rotate around the X axis (tilting the cube forward/backward).
    const rxm = mat4.rotate(rx, .{ .x = 1.0, .y = 0.0, .z = 0.0 });

    // Rotate around the Y axis (turning the cube left/right).
    const rym = mat4.rotate(ry, .{ .x = 0.0, .y = 1.0, .z = 0.0 });

    // Combine the rotations into the model transform. Because the cube is
    // centered at the origin and has no translation, it spins around its center.
    const model = mat4.mul(rxm, rym);

    // Aspect ratio is framebuffer width divided by height. The projection uses
    // it to keep circles and squares from stretching when the window is not square.
    const aspect = sapp.widthf() / sapp.heightf();

    // Perspective makes distant geometry appear smaller. The field of view is
    // 60 degrees; geometry nearer than 0.01 or farther than 10 is clipped.
    const proj = mat4.persp(60.0, aspect, 0.01, 10.0);

    // Package the combined matrix in the exact uniform struct generated by
    // sokol-shdc. Matrix order follows this math library's multiplication
    // convention and matches the shader's `gl_Position = mvp * position`.
    return shd.VsParams{ .mvp = mat4.mul(mat4.mul(proj, state.view), model) };
}
