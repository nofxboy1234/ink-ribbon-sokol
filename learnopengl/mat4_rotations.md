## X-axis rotation

Rotation around X leaves the X component unchanged and mixes Y with Z:

```text
                    input x   input y   input z   input w
                       ↓         ↓         ↓         ↓

output x ←        │     1         0         0         0 │
output y ←        │     0       cos(θ)   -sin(θ)       0 │
output z ←        │     0       sin(θ)    cos(θ)       0 │
output w ←        │     0         0         0         1 │
```

This calculates:

```text
output.x = x
output.y = cos(θ)*y - sin(θ)*z
output.z = sin(θ)*y + cos(θ)*z
output.w = w
```

The X axis acts like the rod around which Y and Z rotate:

```text
                   +Y
                    ↑
                    │
                    │
                    ●──────→ +X  rotation axis
                   /
                 +Z

Y and Z rotate around X.
X remains unchanged.
```

At `90°`:

```text
cos(90°) = 0
sin(90°) = 1
```

The matrix becomes:

```text
                    input x   input y   input z   input w
                       ↓         ↓         ↓         ↓

output x ←        │     1         0         0         0 │
output y ←        │     0         0        -1         0 │
output z ←        │     0         1         0         0 │
output w ←        │     0         0         0         1 │
```

Its columns tell us:

```text
original X axis → +X
original Y axis → +Z
original Z axis → -Y
```

For example:

```text
input = (0, 1, 0)
```

becomes:

```text
output.x = 0
output.y = 0*1 - 1*0 = 0
output.z = 1*1 + 0*0 = 1
```

Therefore:

```text
(0, 1, 0) → (0, 0, 1)
```

## Y-axis rotation

Rotation around Y leaves the Y component unchanged and mixes X with Z:

```text
                    input x   input y   input z   input w
                       ↓         ↓         ↓         ↓

output x ←        │   cos(θ)      0       sin(θ)       0 │
output y ←        │     0         1         0          0 │
output z ←        │  -sin(θ)      0       cos(θ)       0 │
output w ←        │     0         0         0          1 │
```

This calculates:

```text
output.x =  cos(θ)*x + sin(θ)*z
output.y =  y
output.z = -sin(θ)*x + cos(θ)*z
output.w =  w
```

The Y axis acts like the rod around which X and Z rotate:

```text
                   +Y
                    ↑
                    │  rotation axis
                    │
                    ●──────→ +X
                   /
                 +Z

X and Z rotate around Y.
Y remains unchanged.
```

At `90°`:

```text
cos(90°) = 0
sin(90°) = 1
```

The matrix becomes:

```text
                    input x   input y   input z   input w
                       ↓         ↓         ↓         ↓

output x ←        │     0         0         1         0 │
output y ←        │     0         1         0         0 │
output z ←        │    -1         0         0         0 │
output w ←        │     0         0         0         1 │
```

Its columns tell us:

```text
original X axis → -Z
original Y axis → +Y
original Z axis → +X
```

For example:

```text
input = (1, 0, 0)
```

becomes:

```text
output.x = 0*1 + 1*0 = 0
output.y = 0
output.z = -1*1 + 0*0 = -1
```

Therefore:

```text
(1, 0, 0) → (0, 0, -1)
```

## Z-axis rotation

Rotation around Z leaves the Z component unchanged and mixes X with Y:

```text
                    input x   input y   input z   input w
                       ↓         ↓         ↓         ↓

output x ←        │   cos(θ)   -sin(θ)      0         0 │
output y ←        │   sin(θ)    cos(θ)      0         0 │
output z ←        │     0         0         1         0 │
output w ←        │     0         0         0         1 │
```

This calculates:

```text
output.x = cos(θ)*x - sin(θ)*y
output.y = sin(θ)*x + cos(θ)*y
output.z = z
output.w = w
```

The Z axis acts like the rod around which X and Y rotate:

```text
                   +Y
                    ↑
                    │
                    │
                    ●──────→ +X
                   /
                 +Z
                  ↻

X and Y rotate around Z.
Z remains unchanged.
```

At `90°`:

```text
cos(90°) = 0
sin(90°) = 1
```

The matrix becomes:

```text
                    input x   input y   input z   input w
                       ↓         ↓         ↓         ↓

output x ←        │     0        -1         0         0 │
output y ←        │     1         0         0         0 │
output z ←        │     0         0         1         0 │
output w ←        │     0         0         0         1 │
```

Its columns tell us:

```text
original X axis → +Y
original Y axis → -X
original Z axis → +Z
```

For example:

```text
input = (1, 0, 0)
```

becomes:

```text
output.x = 0*1 - 1*0 = 0
output.y = 1*1 + 0*0 = 1
output.z = 0
```

Therefore:

```text
(1, 0, 0) → (0, 1, 0)
```

## All three together

```text
X-axis rotation:
    X remains unchanged
    Y and Z are mixed

Y-axis rotation:
    Y remains unchanged
    X and Z are mixed

Z-axis rotation:
    Z remains unchanged
    X and Y are mixed
```

The general pattern is:

```text
rotation axis = unchanged component

other two axes = circular movement using sine and cosine
```

With the usual right-handed convention and positive rotation:

```text
+90° around X: +Y → +Z
+90° around Y: +Z → +X
+90° around Z: +X → +Y
```
