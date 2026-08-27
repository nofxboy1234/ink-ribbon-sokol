# Anti-Aliasing: LearnOpenGL mapped to Sokol + Zig

This is a standalone map of the
[LearnOpenGL Anti-Aliasing chapter](https://learnopengl.com/Advanced-OpenGL/Anti-Aliasing)
to this project.

Run it:

```bash
zig build run-anti-aliasing
```

| Key | Result                                            |
|-----|---------------------------------------------------|
| `1` | One sample per pixel: jagged edges remain         |
| `2` | Four samples per pixel: smoother MSAA edges       |

## The whole idea

A screen is a grid of square pixels, but triangle edges can cross that grid at
any angle. A single coverage test must make a hard yes/no choice:

```text
triangle edge  ╱       resulting pixels  ██
              ╱                         ██
             ╱                         ██
```

That staircase is **aliasing**. Anti-aliasing softens the boundary pixels so
the eye perceives a smoother edge.

## SSAA versus MSAA

**SSAA** renders the whole scene at a larger resolution and shrinks it. It
improves many details, but shades many more fragments.

**MSAA** stores several coverage samples inside each pixel, concentrating extra
work around polygon edges:

```text
one sample                 4x MSAA
┌─────────┐                ┌─────────┐
│    •    │                │ •     • │
│         │                │ •     • │
└─────────┘                └─────────┘
hard covered/not-covered   coverage can be 0/4, 1/4, 2/4, 3/4, or 4/4
```

If two of four samples are inside a triangle, roughly half of that triangle's
colour contributes to the final edge pixel. Depth and stencil coverage are
also tracked per sample. Basic MSAA does not normally mean running the fragment
shader four times for every pixel; sample shading is a separate feature.

## OpenGL to Sokol

| OpenGL                                | Sokol + Zig                                                                        |
|---------------------------------------|------------------------------------------------------------------------------------|
| `glfwWindowHint(GLFW_SAMPLES, 4)`     | `sapp.Desc.sample_count = 4`                                                       |
| `glEnable(GL_MULTISAMPLE)`            | No separate call; use matching multisampled targets and pipelines                  |
| Multisample framebuffer attachment    | `sg.Image` with `.usage.color_attachment = true` and `.sample_count = 4`           |
| Multisample renderbuffer              | Same attachment-image abstraction; Sokol chooses backend resources                 |
| `glTexImage2DMultisample`             | The same multisampled `sg.Image` description                                       |
| `glBlitFramebuffer` resolve           | Add `pass.attachments.resolves[0]`; Sokol resolves during `sg.endPass()`           |
| Ordinary resolved texture             | One-sample `sg.Image` with resolve and texture views                               |
| `sampler2DMS` / `texelFetch`          | Backend-sensitive custom sample access; this portable lesson resolves before use   |

## Simple window MSAA

For an ordinary scene drawn straight to the window, request the same sample
count from the app and every pipeline used in that pass:

```zig
sapp.run(.{
    .sample_count = 4,
    // ...
});

const pipeline = sg.makePipeline(.{
    .sample_count = 4,
    // ...
});
```

Mental model: the render target owns four sample slots, and the pipeline must
agree to write four samples. A mismatch is invalid.

## Offscreen MSAA used by this scene

The demo keeps the window single-sampled so it can show either path through
the same presentation pass.

Mode `1`:

```text
draw geometry → one-sample image → sample it on the window quad
```

Mode `2`:

```text
draw geometry → 4x MSAA image → resolve → one-sample image → window quad
```

The multisampled attachment is created with:

```zig
sg.makeImage(.{
    .usage = .{ .color_attachment = true },
    .sample_count = 4,
    // ...
});
```

It cannot be sampled as an ordinary `texture2D`. A separate one-sample image
receives the resolved result:

```zig
const resolve_image = sg.makeImage(.{
    .usage = .{ .resolve_attachment = true },
    .sample_count = 1,
    // ...
});
```

One image can have different **views**, each describing how it will be used:

```text
resolve image
├── resolve-attachment view: destination of the resolve operation
└── texture view:            sampled by the display shader afterward
```

The pass connects the two images:

```zig
pass.attachments.colors[0] = msaa_color_view;
pass.attachments.resolves[0] = resolve_view;
```

When `sg.endPass()` runs, Sokol asks the graphics backend to combine the four
stored samples into the ordinary resolve image. The next pass samples that
resolved texture just like the Framebuffers lesson.

## What MSAA does and does not fix

MSAA mainly smooths **polygon boundaries** produced by rasterization. It does
not automatically fix aliasing inside a polygon from textures, shader patterns,
specular highlights, or later post-processing. Those need techniques such as
mipmapping, filtering, temporal AA, or post-process AA.

More samples improve coverage precision but consume more attachment memory and
bandwidth. `4x` is a teaching choice, not a rule; query device support before
assuming every sample count and pixel format is available in production code.

The chapter briefly mentions custom algorithms that read individual samples
with `sampler2DMS`. That is an advanced, backend-sensitive path. The portable
Sokol approach demonstrated here resolves first and samples a normal texture.

## Source map

| Concept                      | Project location                                |
|------------------------------|-------------------------------------------------|
| Single-sample path           | `single_color_image` and `single_pipeline`      |
| Multisample storage          | `msaa_color_image` and `msaa_pipeline`          |
| Resolve destination          | `resolve_image`                                 |
| Attachment and texture views | `recreateTargets()`                             |
| Automatic resolve            | `offscreen_pass.attachments.resolves[0]`        |
| Compare modes                | `input()` and keys `1`/`2`                      |
| Display resolved result      | `display_pipeline`                              |
