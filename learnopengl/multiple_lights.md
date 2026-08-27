Implemented the LearnOpenGL Multiple Lights scene in Sokol + Zig.

Run it natively:

```bash
zig build run-multiple-lights
```

Or as WASM:

```bash
zig build run-multiple-lights -Dtarget=wasm32-emscripten
```

Main files:

- [multiple_lights.zig](/home/dylan/repos/ink-ribbon-sokol/src/examples/multiple_lights.zig)
- [multiple_lights.glsl](/home/dylan/repos/ink-ribbon-sokol/src/examples/multiple_lights.glsl)
- [generated shader](/home/dylan/repos/ink-ribbon-sokol/src/examples/generated/multiple_lights_shader.zig)

The build and ZLS configurations were updated as well.

## What is new in this lesson?

The individual light calculations are mostly familiar from the previous chapter. The important new idea is:

> Calculate the colour contributed by every light, then add all those contributions together.

This scene contains six lights:

```text
1 directional light
        +
4 point lights
        +
1 camera spotlight
        =
final fragment colour
```

Conceptually:

```zig
var result = directional_light_contribution;

for (point_lights) |point_light| {
    result += point_light_contribution;
}

result += spotlight_contribution;
```

This calculation happens for every generated fragment.

## The key shader code

The clearest demonstration of the chapter’s new concept is in [multiple_lights.glsl](/home/dylan/repos/ink-ribbon-sokol/src/examples/multiple_lights.glsl:136):

```glsl
vec3 result = calculateDirectionalLight(
    normal, to_viewer, surface_color, specular_color
);

for (int index = 0; index < 4; index++) {
    result += calculatePointLight(
        point_positions[index].xyz,
        normal,
        to_viewer,
        surface_color,
        specular_color
    );
}

result += calculateSpotlight(
    normal, to_viewer, surface_color, specular_color
);

frag_color = vec4(result, 1.0);
```

A simple diagram:

```text
directional contribution ──────┐
                               │
point light 0 contribution ────┤
point light 1 contribution ────┤
point light 2 contribution ────┼──► add together ──► final colour
point light 3 contribution ────┤
                               │
spotlight contribution ────────┘
```

If two lights illuminate the same fragment, both contributions are added, making that fragment brighter.

## Separate lighting functions

The shader keeps each kind of lighting in a separate function:

```glsl
calculateDirectionalLight(...)
calculatePointLight(...)
calculateSpotlight(...)
```

They can be found in [multiple_lights.glsl](/home/dylan/repos/ink-ribbon-sokol/src/examples/multiple_lights.glsl:63).

This is primarily code organization. Putting all six calculations directly inside `main()` would quickly become difficult to read.

### Directional-light function

```glsl
vec3 calculateDirectionalLight(...)
```

It uses one direction for every fragment:

```glsl
vec3 to_light = normalize(-directional_direction.xyz);
```

There is no light position and no distance attenuation. It represents something extremely far away, such as the sun.

### Point-light function

```glsl
vec3 calculatePointLight(...)
```

It receives one of the four light positions:

```glsl
vec3 to_light =
    normalize(light_position - fragment_position);
```

It also calculates distance attenuation:

```glsl
float attenuation = 1.0 / (
    constant +
    linear * distance_to_light +
    quadratic * distance_to_light * distance_to_light
);
```

The same function is called four times, once per point light.

### Spotlight function

```glsl
vec3 calculateSpotlight(...)
```

This combines:

- A world-space position
- A direction
- Distance attenuation
- An inner cone
- An outer cone

The spotlight is attached to the static camera, so it acts like a flashlight.

## The point-light array

The four positions are declared in Zig in [multiple_lights.zig](/home/dylan/repos/ink-ribbon-sokol/src/examples/multiple_lights.zig:62):

```zig
const point_light_positions = [_]vec3{
    .{ .x = 0.7, .y = 0.2, .z = 2.0 },
    .{ .x = 2.3, .y = -3.3, .z = -4.0 },
    .{ .x = -4.0, .y = 2.0, .z = -12.0 },
    .{ .x = 0.0, .y = 0.0, .z = -3.0 },
};
```

These are the exact positions from the chapter.

They are converted into the shader’s four-element `vec4` array by:

```zig
fn pointPositionsForShader() [4][4]f32
```

The result is included in one Sokol uniform block:

```zig
.point_positions = pointPositionsForShader(),
```

## OpenGL → Sokol mapping

### Setting individual uniforms

LearnOpenGL uses calls resembling:

```cpp
shader.setVec3("pointLights[0].position", position);
shader.setFloat("pointLights[0].constant", 1.0f);
```

This implementation puts the related values into a generated Zig structure:

```zig
const lighting = shd.LightingFsParams{
    .point_positions = pointPositionsForShader(),
    .point_ambient = .{ 0.05, 0.05, 0.05, 1.0 },
    .point_diffuse = .{ 0.8, 0.8, 0.8, 1.0 },
    .point_specular = .{ 1.0, 1.0, 1.0, 1.0 },
    .point_attenuation = .{ 1.0, 0.09, 0.032, 0.0 },
    // ...
};
```

Then the entire block is uploaded together:

```zig
sg.applyUniforms(
    shd.UB_lighting_fs_params,
    sg.asRange(&lighting),
);
```

Therefore:

```text
many glUniform... calls
          ↓
one typed Sokol uniform block
          ↓
sg.applyUniforms(...)
```

### GLSL struct arrays

LearnOpenGL uses:

```glsl
PointLight pointLights[4];
```

The Sokol shader uses:

```glsl
vec4 point_positions[4];
```

The four lights share the same colours and attenuation values, so those values only need to be stored once. Only their positions differ.

This represents the same scene with less duplicated uniform data.

### Selecting a shader

```cpp
lightingShader.use();
```

maps to:

```zig
sg.applyPipeline(state.object_pipeline);
```

### Binding geometry and textures

OpenGL VAO and texture binding maps approximately to:

```zig
sg.applyBindings(state.bind);
```

### Drawing each crate

```cpp
glDrawArrays(GL_TRIANGLES, 0, 36);
```

maps to:

```zig
sg.draw(0, 36, 1);
```

The example draws ten cubes. Before each draw, it uploads that cube’s model and MVP matrices:

```zig
sg.applyUniforms(
    shd.UB_object_vs_params,
    sg.asRange(&object_params),
);

sg.draw(0, 36, 1);
```

### Drawing the point-light markers

Four small white cubes show the point-light positions:

```zig
for (state.point_light_positions) |position| {
    const model = mat4.mul(
        mat4.translate(position),
        uniformScale(0.2),
    );

    sg.applyUniforms(...);
    sg.draw(0, 36, 1);
}
```

The directional light has no marker because it has no position. The spotlight has no marker because it is attached to the camera.

## CPU and GPU responsibilities

The Zig code on the CPU:

```text
defines light properties
defines light positions
builds camera/model matrices
uploads uniforms
issues draw commands
```

The fragment shader on the GPU:

```text
samples the material textures
calculates directional lighting
calculates all four point lights
calculates the spotlight
adds the six contributions
outputs the final fragment colour
```

Sokol does not automatically calculate lighting. It manages the GPU resources and commands; the lighting equations remain shader code.

## Verification

Completed successfully:

- Native test suite
- Complete WASM build
- WebGL runtime test in Chrome
- Visual inspection against the chapter’s combined-lights frame
- Static ZLS configuration validation

The scene uses the chapter’s original light properties, positions, crate arrangement, attenuation values, and spotlight cutoffs. Reference: [LearnOpenGL — Multiple lights](https://learnopengl.com/Lighting/Multiple-lights).
