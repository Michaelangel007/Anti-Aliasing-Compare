// Anti-Aliasing Tests - rev. 25
// May 21 - 22, 2016
//
// Authors: 
//   Jason Doucette:    https://www.shadertoy.com/user/JasonD        
//                      http://xona.com/jason/
//   Michael Pohoreski: https://www.shadertoy.com/user/MichaelPohoreski
//
// Methods:                     # Samples:
// ----------------------------------------------
// 1. none                      1
// 2. standard 2x2 supersample  4
// 3. 3Dfx rotated grid         4
// 4. nVidia Quincunx           5 (actually 2, since 4 of the 5 samples is used for 4 pixels)
// 5. standard NxN supersample  N^2 (set in #define N_NXN  below)
// 6. random supersample        N^2 (set in #define N_RAND below)
#define N_NXN  4 // See Note 5.
#define N_RAND 8 // See Note 6.
//  8x 8 =   64 samples
// 16x16 =  256 samples
// 32x32 = 1024 samples


// ---- SETTINGS --------------------------------


#define CIRCLE_PERCENTAGE_OF_SCREEN 0.95
#define FULL_CIRCLE 1 // either full circle, or 1/8th mirrored
#define MIN_ZOOM 1.0
#define MAX_ZOOM 8.0
//#define SHOW_ANTI_ALIASING_NAMES
//#define DEBUG_SHOW_ALPHABET
//#define DEBUG_DISABLE_TEXT
//#define DISABLE_RND_TEMPORAL_COHERENCE

// ---- GLOBALS --------------------------------

    // quantized zoom:
    float ZOOM;

    // ORIGINAL positions BEFORE zoom:
    vec2 origM; // 0..1
    vec2 origP; // 0..1

    // MODIFIED based on zoom, used in many functions:
    vec2  res; // resolution
    vec2  mou; // mouse coordinates


// ---- CONSTANTS --------------------------------



// ---- 8< ---- GLSL NUMBER PRINTING ---- @P_Malin ---- 8< ----
// Creative Commons CC0 1.0 Universal (CC-0) 
// https://www.shadertoy.com/view/4sBSWW

const vec2 gvFontSize = vec2(8.0, 15.0); // Multiples of 4x5 work best

float DigitBin(const in int x)
{
    if (x < 10)
        return // originals:
           x==0 ? 480599.0
          :x==1 ? 139810.0
          :x==2 ? 476951.0
          :x==3 ? 476999.0
          :x==4 ? 350020.0
          :x==5 ? 464711.0
          :x==6 ? 464727.0
          :x==7 ? 476228.0
          :x==8 ? 481111.0
          :       481095.0;
#ifndef DEBUG_DISABLE_TEXT
    else
    if (x < 78)
        return // Glyphs added by Michael Pohoreski
           x==42 ?  21072.0 // *
          :x==61 ?  61680.0 // =
          :x==65 ? 434073.0 // A
          :x==66 ? 497559.0 // B
          :x==67 ? 921886.0 // C
          :x==68 ? 498071.0 // D
          :x==69 ? 988959.0 // E
          :x==70 ? 988945.0 // F
          :x==71 ? 925086.0 // G
          :x==72 ? 630681.0 // H
          :x==73 ? 467495.0 // I
          :x==74 ? 559239.0 // J
          :x==75 ? 611161.0 // K
          :x==76 ?  69919.0 // L
          :        653721.0;// M
    else
    if (x < 91)
        return // Glyphs added by Michael Pohoreski
           x==78 ? 638361.0 // N
          :x==79 ? 432534.0 // O
          :x==80 ? 497425.0 // P
          :x==81 ? 432606.0 // Q
          :x==82 ? 497561.0 // R
          :x==83 ? 923271.0 // S
          :x==84 ? 467490.0 // T
          :x==85 ? 629142.0 // U
          :x==86 ? 349474.0 // V
          :x==87 ? 629241.0 // W
          :x==88 ? 628377.0 // X
          :x==89 ? 348706.0 // Y
          :        475671.0;// Z
#endif
    return 0.0;
}

// ---- 8< -------- 8< -------- 8< -------- 8< ----

#ifndef DEBUG_DISABLE_TEXT
vec2 gvPrintCharXY = vec2( 0.0, 0.0 );
vec3 Char(  vec3 backgroundColor, vec3 textColor, vec2 fragCoord, float fValue )
{
    vec2 vStringCharCoords = (fragCoord.xy - gvPrintCharXY) / gvFontSize;
    if ((vStringCharCoords.y < 0.0) || (vStringCharCoords.y >= 1.0)) return backgroundColor;
    if ( vStringCharCoords.x < 0.0)                                  return backgroundColor;

    float fCharBin = (vStringCharCoords.x < 1.0) ? DigitBin(int(fValue)) : 0.0;

    // Auto-Advance cursor one glyph plus 1 pixel padding
    // thus characters are spaced 9 pixels apart
    float fAdvance = false
        || (fValue == 42.) // *
        || (fValue == 73.) // I
        || (fValue == 84.) // T
        || (fValue == 86.) // V
        || (fValue == 89.) // Y
        ? 0.0 // glyph width has no padding
        : 1.0; 
    gvPrintCharXY.x += gvFontSize.x + fAdvance;
        
    float a = floor(mod((fCharBin / pow(2.0, floor(fract(vStringCharCoords.x) * 4.0) + (floor(vStringCharCoords.y * 5.0) * 4.0))), 2.0));
    return mix( backgroundColor, textColor, a );
}

vec3 Char4( vec3 backgroundColor, vec3 textColor, vec2 fragCoord, float fChars  )
{
    vec2 vStringCharCoords = (fragCoord.xy - gvPrintCharXY) / gvFontSize;
    if ((vStringCharCoords.y < 0.0) || (vStringCharCoords.y >= 1.0)) return backgroundColor;
    if ( vStringCharCoords.x < 0.0)                                  return backgroundColor;

    float a = 0.0;
    float fAdvance = false ? 1.0 : 0.0;

    for( int i = 0; i < 4; i++ )
    {
        int   nChar    = int( mod( fChars, 64.0 ) );
        float fCharBin = (vStringCharCoords.x < 1.0) ? DigitBin(nChar) : 0.0;

        gvPrintCharXY.x += gvFontSize.x + fAdvance;
        
        a = floor(mod((fCharBin / pow(2.0, floor(fract(vStringCharCoords.x) * 4.0) + (floor(vStringCharCoords.y * 5.0) * 4.0))), 2.0));

    }
    return mix( backgroundColor, textColor, a );
}
#endif

// ---- UTILITY --------------------------------

vec2 rotateX( vec2 p, float angleRadians )
{
    float s = sin( angleRadians );
    float c = cos( angleRadians );
    mat2  m = mat2( c, -s, 
                    s,  c );
    return m * p; // vec2
}

// De facto "noise"
float noise( vec2 location ) {
    return 
        fract(
            sin(
                dot(
                    location.xy, vec2(12.9898, 78.233)
                )
            ) * 43758.5453
        );
}


// ---- PATTERNS TO ANTI-ALIAS --------------------------------

vec3 patternSet_circleWithSpokes( vec2 uv )
{    
    #if FULL_CIRCLE
        // full circle
        vec2 p = (2.*uv - 1.) / CIRCLE_PERCENTAGE_OF_SCREEN;
    #else   
        // 1/8th circle, shown twice via split screen down diagonal
        // this is to aid the number of near horizontal and vertical lines.
        if (uv.x > uv.y) 
            uv = 1.0 - uv;

        vec2 p = uv / CIRCLE_PERCENTAGE_OF_SCREEN;        
    #endif
    
    // quick semi-distance to circle formula:
    float g = dot( p, p );
    
    float quarterTime = iGlobalTime * 0.25;

    float dt = sin(quarterTime) * 0.05;
    bool insideCircle = 
        ((g <  1.0    ) && (g >  0.85   )) ||
        ((g <  0.6    ) && (g >  0.5    )) ||
        ((g < (0.2+dt)) && (g > (0.1+dt)));
    
    const float PI = 3.1415962; // atan(1.) * 4.;
    bool insideSpokes = mod(atan(p.y, p.x) + quarterTime/10., PI/8.) < 0.15;
    
    float v = mod(float(insideCircle) *  1.0 + 
                  float(insideSpokes) * (1. - g), 
                  1.333);

    return vec3(v,v,v);
}

vec3 patternSet_checker(vec2 uv)
{
    // Be Square or be Incorrect - correct for aspect ratio
    uv.xy *= vec2( iResolution.x/iResolution.y, 1.0 );

    float quarterTime = iGlobalTime * 0.25;
    float distortTime = quarterTime + uv.y * 3.;
    
    float angle = -distortTime * 0.1;
    
    // translate
    uv.xy -= vec2(0.5);
    // rotate
   	vec2 p = rotateX( uv, angle );
    // translate back
    p += vec2(0.5);
    
    const float NUM_CELLS  = 8.0;

    // checkerboard
    float checkerboard = (
        mod(floor(p.x*NUM_CELLS),2.0) == mod(floor(p.y*NUM_CELLS),2.0) 
            ? 1.0
            : 0.0);  
    return vec3(checkerboard);
}

vec3 patternSet_3Dchecker(vec2 uv)
{
    // SOURCE:
    // Space Harrier
    // https://www.shadertoy.com/view/XdVSzm
    // by: JasonD
    
    // center point on screen
    vec2 center = vec2(0.5, 0.5);
    
    // distance from center
    vec2 dCenter = center - uv.xy;
    
    float X_INV_SCALE = 1.5;
    float Z_INV_SCALE = 0.6;
    
    // 3D perspective: 1/Z = constant
    float zCamera = 1.0 / dCenter.y;
    float xCamera = X_INV_SCALE * dCenter.x * zCamera;
    float yCamera = Z_INV_SCALE * zCamera;

    // static texture coordinates
    uv.xy = vec2(xCamera, yCamera);

    // textured
    float checkerboard = (
        mod(floor(uv.x), 2.0) == mod(floor(uv.y), 2.0) 
            ? 1.0
            : 0.0);  
    return vec3(checkerboard);
   
}

//vec3 color1(vec2 p) { return patternSet_circleWithSpokes( p ); }
//vec3 color2(vec2 p) { return patternSet_checker         ( p ); }
//vec3 color3(vec2 p) { return patternSet_3Dchecker       ( p ); }

vec3 pixelSet(vec2 uv)
{
    // our position (already quantized):
    vec2 p = uv.xy / res.xy;
    
    // get slow time:
    float tDistort = iGlobalTime * 0.35 + 
        dot( 
            origP, 
            vec2(0.05, 0.35) // NOTE: changing X vs. Y will change the angle of the swipe fade
        );
    float t = mod(tDistort, 9.0 ); // 0.0..9.0, wraps
    float f = smoothstep(0.0, 1.0, fract(tDistort)); // change from linear to smooth

    // Smooth fade between the patterns
    // NOTE: I am aware that some if-statements can be removed.
    //       As is, it shows the different states more clearly.
/*
    // Original
         if (t < 1.0) return color1(p);
    else if (t < 2.0) return color1(p);
    else if (t < 3.0) return mix(color1(p), color2(p), f);
    else if (t < 4.0) return color2(p);
    else if (t < 5.0) return color2(p);
    else if (t < 6.0) return mix(color2(p), color3(p), f);
	else if (t < 7.0) return color3(p);
	else if (t < 8.0) return color3(p);
	else              return mix(color3(p), color1(p), f);

         if (t < 1.0) return     patternSet_circleWithSpokes(p);
    else if (t < 2.0) return     patternSet_circleWithSpokes(p);
    else if (t < 3.0) return mix(patternSet_circleWithSpokes(p), patternSet_checker(p), f);
    else if (t < 4.0) return     patternSet_checker(p);
    else if (t < 5.0) return     patternSet_checker(p);
    else if (t < 6.0) return mix(patternSet_checker(p), patternSet_3Dchecker(p), f);
    else if (t < 7.0) return     patternSet_3Dchecker(p);
    else if (t < 8.0) return     patternSet_3Dchecker(p);
    else              return mix(patternSet_3Dchecker(p), patternSet_circleWithSpokes(p), f);
*/
    // Optimized    
         if (t < 2.0) return     patternSet_circleWithSpokes(p);
    else if (t < 3.0) return mix(patternSet_circleWithSpokes(p), patternSet_checker(p), f);
    else if (t < 5.0) return                                     patternSet_checker(p);
    else if (t < 6.0) return mix(patternSet_checker(p), patternSet_3Dchecker(p), f);
    else if (t < 8.0) return                            patternSet_3Dchecker(p);
    else              return mix(patternSet_3Dchecker(p), patternSet_circleWithSpokes(p), f);
}


// ---- 2X2 AA --------------------------------
vec3 aa_2x2( vec2 uv )
{
    // fragCoord = pixel, not normalized
    vec2 d = vec2( 0.25, 0.25 );
   
    return vec3(
        pixelSet(uv + vec2(+d.x, +d.y)) +
        pixelSet(uv + vec2(-d.x, +d.y)) +
        pixelSet(uv + vec2(+d.x, -d.y)) +
        pixelSet(uv + vec2(-d.x, -d.y))
    ) / 4.0; // average
}

#if 0 // inlined in main()
// ---- 3DFX AA --------------------------------
vec3 aa_3dfx( vec2 uv )
{
    // fragCoord = pixel, not normalized
    //vec2 p = vec2( 0.25, 0.25 );

    // rotate
    
    // 3Dfx rotation angle is such that the four points are equi-distant
    // from each other in orthogonal directions.  Thus, when a near
    // horizontal or near vertical plane moves through the pixel,
    // instead of seeing 2 steps (as in a 2x2 AA), you will see 4 steps,
    // which is the maximum when only sampling each pixel 4 times.
    // This angle turns out to be the angle in a right triangle 
    // such that oppsite = 2x length of adjacent.

    // normal 2x2:

    //   x   |   x --------- both are passed over at the (nearly) same time 
    //       |               with a (near) horizontal line
    // ------+------
    //       |    
    //   x   |   x 

    // 3Dfx:
    
    //     x-|- - - - - - - -}
    //       |               } dy = constant
    //       |   x- - - -}- -}
    // ------+------     } dy
    //   x - | - - - - - }- - -}
    //       |                 } dy
    //       | x - - - - - - - }
    
    // the angle is:
    //
    //    x
    //   /|
    //  / x
    // /  |
    // x--x
    //
    // tan( angle ) =    opp / adj
    // tan( angle ) =      1 / 2
    //      angle   = atan(1 / 2)
    //float rad = atan(0.5); // 26.5650512 degrees = 0.46364760900080611621425623146121 
    
    vec2 q = rotateX( vec2(0.25), 0.463647609 );
    
    // before: (x,y) = 0.25, 0.25
    // after:  (x,y) = 0.11218413712, 0.33528304367
    //               =     small    ,     large
    //float small = q.x;
    //float large = q.y;
    
    // 4 dots, rotated 26.5 degrees clockwise:
    // 1. -small, +large
    // 2. +large, +small
    // 3. +small, -large
    // 4. -large, -small
    
    return vec3(
        pixelSet(uv + vec2(-q.x, +q.y)) +
        pixelSet(uv + vec2(+q.y, +q.x)) +
        pixelSet(uv + vec2(+q.x, -q.y)) +
        pixelSet(uv + vec2(-q.y, -q.x))
    ) / 4.0; // average
}

// ---- QUINCUNX AA --------------------------------
vec3 aa_quincunx( vec2 uv )
{
    // fragCoord = pixel, not normalized
    vec2 d = vec2( 0.5, 0.5 );
   
    // Weightings
    // quincunx = 1/8th power for four corners that are shared with other pixels
    //          = 1/2   power for one center
    //          = TOTAL of 100%
    return vec3(
        pixelSet(uv + vec2(+d.x, +d.y)) * 0.125 +
        pixelSet(uv + vec2(-d.x, +d.y)) * 0.125 +
        pixelSet(uv + vec2(+d.x, -d.y)) * 0.125 +
        pixelSet(uv + vec2(-d.x, -d.y)) * 0.125 +
        pixelSet(uv + vec2(   0,    0)) * 0.500
    );
}

// ---- NxN --------------------------------
vec3 aa_nxn( vec2 uv )
{
    // fragCoord = pixel, not normalized
    
    vec3 c = vec3(0.0,0.0,0.0);
    #define oon 1. / float(N_NXN)
    for (int i=0; i<N_NXN; i++) {
        for (int j=0; j<N_NXN; j++) {
            
            // TODO: could be optimized with additions of a single constant delta applied to both x and y.
            
            // perfect grid
            float n1 = float(i) * oon; // this could be optimized outside the loop
            float n2 = float(j) * oon;
            
            vec2 offset = vec2(n1, n2) - vec2(0.5, 0.5);
            c += pixelSet(uv + offset);
        }
    }
    return c / float(N_NXN * N_NXN);
}

// ---- RANDOM AA --------------------------------
vec3 aa_random( vec2 uv )
{
    // fragCoord = pixel, not normalized
    
    float t = iGlobalTime;
    
    vec3 c = vec3(0.0,0.0,0.0);
    for (int i=0; i<N_RAND; i++) {
        for (int j=0; j<N_RAND; j++) {
            
            // noise
            float t1 = t * float(i); // this could be optimized outside the loop
            float t2 = t * float(j);
            float n1 = noise( uv + vec2(t1, -t2));
            float n2 = noise( uv + vec2(t2, -t1));
            
            vec2 offset = vec2(n1, n2) - vec2(0.5, 0.5);
            c += pixelSet(uv + offset);
        }
    }
   
    return c / float(N_RAND * N_RAND);
}
#endif


// ---- TEXT --------------------------------

vec3 drawTitle( in vec2 fragCoord, 
               float mx0, 
               float mx1, 
               float mx2, 
               float mx3, 
               float mx4)
{
    vec3 color = vec3( 1.0 ); // background white

    // colors for text
    vec3 blue = vec3( 0.0, 0.5, 1.0 );

    float scale  = iResolution.x;
    float center = (mx1 - mx0) * 0.5 * scale;

#ifndef DISABLE_DEBUG_TEXT
#ifndef SHOW_ANTI_ALIASING_NAMES
    const float charWidth = gvFontSize.x + 1.; // 9 pixels wide = 1 char
    gvPrintCharXY.y = iResolution.y - gvFontSize.y - 1.;
    gvPrintCharXY.x = mx0*scale - center - charWidth * 4. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 79. ); // O

    gvPrintCharXY.x = mx1*scale - center - charWidth * 3. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord,  2. ); // 2
    color = Char( color, blue, fragCoord, 42. ); // *

    gvPrintCharXY.x = mx2*scale - center - charWidth * 4. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord,  3. ); // 3
    color = Char( color, blue, fragCoord, 68. ); // D

    gvPrintCharXY.x = mx3*scale - center - charWidth * 8. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord, 81. ); // Q
    color = Char( color, blue, fragCoord, 88. ); // X

    const float numChars = (N_RAND >= 10 ? 5. : 3.);
    gvPrintCharXY.x = mx4*scale - center - charWidth * numChars / 2.; // x/2 = center on x chars

    float nr1, nr2;
    
    nr1 = float(N_NXN / 10);        // 10's digit
    nr2 = float(N_NXN) - nr1 * 10.; //  1's digit
                   color = Char( color, blue, fragCoord, nr2 ); // N2
    color = Char( color, blue, fragCoord, 42. ); // *

    gvPrintCharXY.x = mx4*scale + center - charWidth * numChars / 2.; // x/2 = center on x chars
    //                          ^ 
    //                       positive, to show on the other side of the line

    nr2 = float(N_RAND) - nr1 * 10.; //  1's digit

    color = Char( color, blue, fragCoord, 82. ); // R
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 68. ); // D

#else    
//#ifdef SHOW_ANTI_ALIASING_NAMES
    const float charWidth = gvFontSize.x + 1.; // 9 pixels wide = 1 char
    gvPrintCharXY.y = iResolution.y - gvFontSize.y - 1.;
    gvPrintCharXY.x = mx0*scale - center - charWidth * 4. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 79. ); // O
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 69. ); // E

    gvPrintCharXY.x = mx1*scale - center - charWidth * 3. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord,  2. ); // 2
    color = Char( color, blue, fragCoord, 42. ); // *
    color = Char( color, blue, fragCoord,  2. ); // 2

    gvPrintCharXY.x = mx2*scale - center - charWidth * 4. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord,  3. ); // 3
    color = Char( color, blue, fragCoord, 68. ); // D
    color = Char( color, blue, fragCoord, 70. ); // F
    color = Char( color, blue, fragCoord, 88. ); // X

    gvPrintCharXY.x = mx3*scale - center - charWidth * 8. / 2.; // x/2 = center on x chars
    color = Char( color, blue, fragCoord, 81. ); // Q
    color = Char( color, blue, fragCoord, 85. ); // U
    color = Char( color, blue, fragCoord, 73. ); // I
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 67. ); // C
    color = Char( color, blue, fragCoord, 85. ); // U
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 88. ); // X
    
    {
        // this one is odd, since we change the number of characters drawn
        // in the case that N_RAND is a single or double digit number.
        const float numChars = (N_RAND >= 10 ? 5. : 3.);
        gvPrintCharXY.x = mx4*scale - center - charWidth * numChars / 2.; // x/2 = center on x chars
        
        float nr1 = float(N_NXN / 10);        // 10's digit
        float nr2 = float(N_NXN) - nr1 * 10.; //  1's digit
    
    if (nr1 != 0.) color = Char( color, blue, fragCoord, nr1 ); // N1
                   color = Char( color, blue, fragCoord, nr2 ); // N2
                   color = Char( color, blue, fragCoord, 42. ); // *
    if (nr1 != 0.) color = Char( color, blue, fragCoord, nr1 ); // N1
                   color = Char( color, blue, fragCoord, nr2 ); // N2
    }

    {
        // this one is odd, since we change the number of characters drawn
        // in the case that N_RAND is a single or double digit number.
        const float numChars = (N_RAND >= 10 ? 9. : 7.);
        gvPrintCharXY.x = mx4*scale + center - charWidth * numChars / 2.; // x/2 = center on x chars
        //                          ^ 
        //                       positive, to show on the other side of the line
        
        float nr1 = float(N_RAND / 10);        // 10's digit
        float nr2 = float(N_RAND) - nr1 * 10.; //  1's digit
    
                   color = Char( color, blue, fragCoord, 82. ); // R
                   color = Char( color, blue, fragCoord, 78. ); // N
                   color = Char( color, blue, fragCoord, 68. ); // D
                   color = Char( color, blue, fragCoord, 32. ); // space = undefined = blank
    if (nr1 != 0.) color = Char( color, blue, fragCoord, nr1 ); // N1
                   color = Char( color, blue, fragCoord, nr2 ); // N2
                   color = Char( color, blue, fragCoord, 42. ); // *
    if (nr1 != 0.) color = Char( color, blue, fragCoord, nr1 ); // N1
                   color = Char( color, blue, fragCoord, nr2 ); // N2
    }
    
#endif
    
#ifdef DEBUG_SHOW_ALPHABET
    
    gvPrintCharXY = vec2( 1.0, iResolution.y - gvFontSize.y );

    color = Char( color, blue, fragCoord, 65. ); // A
    color = Char( color, blue, fragCoord, 66. ); // B
    color = Char( color, blue, fragCoord, 67. ); // C
    color = Char( color, blue, fragCoord, 68. ); // D
    color = Char( color, blue, fragCoord, 69. ); // E
    color = Char( color, blue, fragCoord, 70. ); // F
    color = Char( color, blue, fragCoord, 71. ); // G
    color = Char( color, blue, fragCoord, 72. ); // H
    color = Char( color, blue, fragCoord, 73. ); // I
    color = Char( color, blue, fragCoord, 74. ); // J
    color = Char( color, blue, fragCoord, 75. ); // K
    color = Char( color, blue, fragCoord, 76. ); // L
    color = Char( color, blue, fragCoord, 77. ); // M
    color = Char( color, blue, fragCoord, 78. ); // N
    color = Char( color, blue, fragCoord, 79. ); // O
    color = Char( color, blue, fragCoord, 80. ); // P
    color = Char( color, blue, fragCoord, 81. ); // Q
    color = Char( color, blue, fragCoord, 82. ); // R
    color = Char( color, blue, fragCoord, 83. ); // S
    color = Char( color, blue, fragCoord, 84. ); // T
    color = Char( color, blue, fragCoord, 85. ); // U
    color = Char( color, blue, fragCoord, 86. ); // V
    color = Char( color, blue, fragCoord, 87. ); // W
    color = Char( color, blue, fragCoord, 88. ); // X
    color = Char( color, blue, fragCoord, 89. ); // Y
    color = Char( color, blue, fragCoord, 90. ); // Z
    color = Char( color, blue, fragCoord, 42. ); // *
#endif

#endif // DEBUG_DISABLE_TEXT

    return color;
}


// ---- MAIN --------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // ---- ORIGINAL POSITIONS ----
    
    // get original positions before ZOOM:
    
    // mouse y
    origM = iMouse.xy    / iResolution.xy; // 0..1
    origP = fragCoord.xy / iResolution.xy; // 0..1

    // if we're not using the mouse
    // AND the window size is LIKELY THAT of a thumbnail,
    // force defaults to show off a nice thumbnail:
    if ((iMouse.z < 0.5) && 
        (iResolution.y < 310.))
    {
        origM.x = 0.5; // center, to see most of the AA methods
        origM.y = 1.5 / MAX_ZOOM; // to select ZOOM = 2 via the equation below
    }
    
    // ---- ZOOM QUANTIZE ----
    
    // get ZOOM factor from the original positions
    ZOOM = MIN_ZOOM + 
        floor(
            origM.y * (MAX_ZOOM + 0.99 - MIN_ZOOM) // +0.99 since we floor() the result, 
                                               // and want MAX_ZOOM to be selectable as well
             ); // needs to be integer!
    ZOOM = clamp(ZOOM, MIN_ZOOM, MAX_ZOOM); // can get out of range when window resizes.
        
    // mouse position relative
    float mx0 = origM.x - 0.40;
    float mx1 = origM.x - 0.20;
    float mx2 = origM.x       ;
    float mx3 = origM.x + 0.20;
    float mx4 = origM.x + 0.40;
        
    vec3 color = vec3( 0.0 );

#define COLOR_WHITE vec3( 1.0, 1.0, 1.0 )

// 1. Header
    // background bar
    if (fragCoord.y > (iResolution.y - gvFontSize.y - 2.0))
    {
        // ---- HUD ----
        // the AA method names:
        color = drawTitle( fragCoord, mx0, mx1, mx2, mx3, mx4 );
    }
// 3. Footer
    else
    if ((fragCoord.y <= (gvFontSize.y + 2.0)
    &&  (fragCoord.x < ((gvFontSize.x + 1.) * 7.))))
    {
        // ---- HUD ----
        // background bar
        color = COLOR_WHITE;

        // colors    
        #define nameLit   vec3( 0.0, 0.8, 0.0 )
        #define equalsLit vec3( 0.0, 0.0, 0.0 )
        #define factorLit vec3( 1.0, 0.0, 0.0 )

#ifndef DEBUG_DISABLE_TEXT
        // "ZOOM=" text
        gvPrintCharXY = vec2( 1.0, 1.0 );
        //color = drawStatus( color, fragCoord, nameLit, equalsLit );
        color = Char( color, nameLit  , fragCoord, 90.0 ); // Z
        color = Char( color, nameLit  , fragCoord, 79.0 ); // O
        color = Char( color, nameLit  , fragCoord, 79.0 ); // O
        color = Char( color, nameLit  , fragCoord, 77.0 ); // M
        color = Char( color, equalsLit, fragCoord, 61.0 ); // =

        // show Zoom factor bottom left
        color = Char( color, factorLit, fragCoord, ZOOM );    
#endif
    }
// 2. Main Image
    else
    {
        // quantize to zoom
        vec2 uv = floor(fragCoord / ZOOM) * ZOOM;
        
        // then do actual zoom (center zoom on 0.5,0.5)
        res = (vec2(0.5, 0.5) - iResolution.xy) / ZOOM;
        mou = (vec2(0.5, 0.5) - iMouse.xy     ) / ZOOM;
        uv  = (vec2(0.5, 0.5) - uv.xy         ) / ZOOM;
        
        float t = iGlobalTime;

        // fragCoord = pixel, not normalized
        vec2  q = vec2( 0.25, 0.25 ); // common factor: aa_2x2(), aa_3dfx()
        float s;
        float c;

        // ---- SPLIT SCREEN ----
        
    /*    
        // screen split
        vec3 color = pixelSet   ( uv ); // no AA;
             if (origP.x < mx1) color = aa_2x2     ( uv ); 
        else if (origP.x < mx2) color = aa_3dfx    ( uv );
        else if (origP.x < mx3) color = aa_quincunx( uv ); 
        else if (origP.x < mx4) color = aa_nxn     ( uv );
        else                    color = aa_random  ( uv );
    */

        if( origP.x < mx0 )
            color = pixelSet   ( uv );
        else
        if (origP.x < mx3) { // < mx1: q=0.25, mx2: q=0.25 * rotateX( atan( 0.5 ) ), mx3: q=0.5
            float w1 = 0.25;
            float w2 = 0.0 ;

            // color = aa_2x2     ( uv ); 

            if (origP.x > mx1) {
                //color = vec3( 1.0, 0.0, 0.0 );
                // color = aa_3dfx    ( uv );
                // q = rotateX( vec2(0.25), 0.463647609 );
                s = sin( 0.463647609 );
                c = cos( 0.463647609 );
                q = mat2( c, -s, 
                          s,  c ) * q;
            } 

            if (origP.x > mx2) {
                // color = aa_quincunx( uv ); 
                //q = vec2( 0.5, 0.5 );
                q *= 2.0; // 0.5, 0.5

                // Weightings
                // quincunx = 1/8th power for four corners that are shared with other pixels
                //          = 1/2   power for one center
                //          = TOTAL of 100%
                w1 = 0.125;
                w2 = 0.5  ;
            }

            color = vec3(
                pixelSet(uv + vec2(-q.x, +q.y)) * w1 +
                pixelSet(uv + vec2(+q.y, +q.x)) * w1 +
                pixelSet(uv + vec2(+q.x, -q.y)) * w1 +
                pixelSet(uv + vec2(-q.y, -q.x)) * w1 +
                pixelSet(uv + vec2( 0.0,  0.0)) * w2
            );
        }
        else if (origP.x < mx4) {
            // color = aa_nxn     ( uv );

            #define oon 1. / float(N_NXN)

            for (int i=0; i<N_NXN; i++) {
                for (int j=0; j<N_NXN; j++) {
                    
                    // TODO: could be optimized with additions of a single constant delta applied to both x and y.
                    
                    // perfect grid
                    float n1 = float(i) * oon; // this could be optimized outside the loop
                    float n2 = float(j) * oon;
                    
                    vec2 offset = vec2(n1, n2) - vec2(0.5, 0.5);
                    color += pixelSet(uv + offset);
                }
            }
            color /= float(N_NXN * N_NXN);
        }
        //else                    color = aa_random  ( uv );
        else
        {
            // color = aa_random  ( uv );

            for (int i=0; i<N_RAND; i++) {
                for (int j=0; j<N_RAND; j++) {

#ifdef DISABLE_RND_TEMPORAL_COHERENCE
                    t = 1.0;
#endif                    

                    // noise
                           q = t * vec2(float(i), float(j)); // this could partially be optimized outside the loop
                    float n1 = noise( uv + vec2(q.x, -q.y));
                    float n2 = noise( uv + vec2(q.y, -q.x));
                    
                    vec2 offset = vec2(n1, n2) - vec2(0.5, 0.5);
                    color += pixelSet(uv + offset);
                }
            }
            color /= float(N_RAND * N_RAND);
        }

#if 1
        // show black split bar
        // float fade = 1.0; // TODO: Need to account for mouse y position: m.y;
        #define a 0.002
        #define b 0.005
            color *=    smoothstep( a, b, abs(origP.x-mx0) );
            color *=    smoothstep( a, b, abs(origP.x-mx1) );
            float d=1.0-smoothstep( a, b, abs(origP.x-mx2) );
            color *=    smoothstep( a, b, abs(origP.x-mx3) );
            color *=    smoothstep( a, b, abs(origP.x-mx4) );

        // Color code middle split bar
        if (d > 0.5) 
           color += vec3(0.0,0.5,1.0) * d;
#endif

    }

    // ---- FINAL RESULT
    fragColor = vec4( color, 1.0 );
}
