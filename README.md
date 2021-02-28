# Comparing Anti-Aliasing Techniques

View on ShaderToy.com:
https://www.shadertoy.com/view/4dGXW1

# Authors:

- Jason Doucette - https://www.shadertoy.com/user/JasonD        
- Michael Pohoreski - https://www.shadertoy.com/user/MichaelPohoreski

# Algorithms:

```
  Methods:                       # Samples:
  ----------------------------------------------
  1. none                        1
  2. nVidia Quincunx             2
  3. standard 2x2 supersample    4
  4. 3Dfx rotated grid           4
  5. standard NxN supersample    4^2 (*N^2 set in #define METHOD_NXN_N     below)
  6. random supersample static   8^2 (*N^2 set in #define METHOD_RND_NXN_N below)
  7. random supersample dynamic  8^2 (*N^2 set in #define METHOD_RND_NXN_N below)
```

# Control

Mouse click and move:
left/right = move split screen (AA methods: left to right)
up/down = change zoom factor
