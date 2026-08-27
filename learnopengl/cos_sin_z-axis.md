`cos` does not permanently belong to X, and `sin` does not permanently belong to Y.

More accurately:

> `cos` and `sin` produce two coordinates on the plane in which something is rotating.

For an ordinary 2D circle, that plane is XY:

```text
x = radius × cos(θ)
y = radius × sin(θ)
z = constant
```

```text
                  +Y
                   ↑
              ● (x,y)
            /  |
           /θ  |
          ●────┘────────→ +X

          Z does not change
```

In Zig:

```zig
const position = Vec3{
    .x = radius * std.math.cos(angle),
    .y = radius * std.math.sin(angle),
    .z = 0,
};
```

This is really a rotation around the Z axis.

## Rotating around Z: use the XY plane

The axis of rotation stays unchanged. The other two coordinates form the circle:

```text
rotation axis: Z
circle plane:  XY

x = r × cos(θ)
y = r × sin(θ)
z = constant
```

```text
viewed along Z:

       +Y
        ↑
     ↗  │
   ●    │
        └────────→ +X
```

## Rotating around Y: use the XZ plane

Y stays unchanged, while X and Z form the circle:

```text
rotation axis: Y
circle plane:  XZ

x = r × cos(θ)
y = constant
z = r × sin(θ)
```

```zig
const position = Vec3{
    .x = radius * std.math.cos(angle),
    .y = 0,
    .z = radius * std.math.sin(angle),
};
```

Viewed from above:

```text
                  +Z
                   ↑
              ● (x,z)
            /  |
           /θ  |
          ●────┘────────→ +X

          Y does not change
```

This is often used for a camera orbiting horizontally around an object:

```zig
const camera_position = Vec3{
    .x = target.x + radius * std.math.cos(angle),
    .y = target.y + camera_height,
    .z = target.z + radius * std.math.sin(angle),
};
```

## Rotating around X: use the YZ plane

X stays unchanged, while Y and Z form the circle:

```text
rotation axis: X
circle plane:  YZ

x = constant
y = r × cos(θ)
z = r × sin(θ)
```

```zig
const position = Vec3{
    .x = 0,
    .y = radius * std.math.cos(angle),
    .z = radius * std.math.sin(angle),
};
```

```text
viewed along X:

       +Z
        ↑
     ●  │
      \ │
       \│
        └────────→ +Y

        X does not change
```

## The general pattern

When rotating around one axis:

```text
the rotation axis stays constant
the other two axes use cos and sin
```

| Rotation around | Constant axis | Circle plane | Coordinates |
|---|---|---|---|
| Z | Z | XY | `x = r cos θ`, `y = r sin θ` |
| Y | Y | XZ | `x = r cos θ`, `z = r sin θ` |
| X | X | YZ | `y = r cos θ`, `z = r sin θ` |

The signs or placement of `sin` may change depending on:

- Which direction counts as positive rotation
- Whether the coordinate system is right-handed or left-handed
- Which direction the object initially points
- Which side of the rotation axis you are viewing from

## A useful mental model

Think of `cos` and `sin` as generating a rotating 2D arrow:

```text
(cos θ, sin θ)
```

You then decide which two 3D axes receive those two values:

```text
XY plane → (cos θ, sin θ, constant)
XZ plane → (cos θ, constant, sin θ)
YZ plane → (constant, cos θ, sin θ)
```

So Z is not missing. It participates whenever the circle lies in the XZ or YZ plane.
