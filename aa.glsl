/* Anti-Aliasing Tests - rev. 43J
   May 21-28, 2016

   Authors: 
     Jason Doucette:    https://www.shadertoy.com/user/JasonD        
                        http://xona.com/jason/
     Michael Pohoreski: https://www.shadertoy.com/user/MichaelPohoreski

  Methods:                       # Samples:
  ----------------------------------------------
  1. none                        1
  2. nVidia Quincunx             2
  3. standard 2x2 supersample    4
  4. 3Dfx rotated grid           4
  5. standard NxN supersample    4^2 (*N^2 set in #define METHOD_NXN_N     below)
  6. random supersample static   8^2 (*N^2 set in #define METHOD_RND_NXN_N below)
  7. random supersample dynamic  8^2 (*N^2 set in #define METHOD_RND_NXN_N below)
*/


// ---- MAIN SETTINGS --------------------------------

#define METHOD_NXN_N  4     // *See Note 5 above.
#define METHOD_RND_NXN_N 8  // *See Note 6 above.
//  4x 4 =   16 samples
//  8x 8 =   64 samples
// 16x16 =  256 samples
// 32x32 = 1024 samples

#define GAMMA_CORRECTION 2.2
    // check gamma:  https://www.shadertoy.com/view/ldVSD1

// NOTE: Scroll down for more settings that are possible.


// ---- METHOD EXPLANATIONS --------------------------------
/*

======== 1. none   

A single sample is used from the pixel's center:

+------+------+
|             |        
|             |
|             |
+      X      +  <--- X marks the spot
|             |
|             |
|             |        
+------+------+


======== 2. nVidia Quincunx    

5 samples are used:
- 1 in the center
- 4 at the corners of the pixel, which are shared with 3 other pixels (4 in total).
The result is that only 2 samples per pixel need to be taken

X------+------X  <--- note the samples from ALL FOUR corners
|             |        
|             |
|             |
+      X      +
|             |
|             |
|             |        
X------+------X  <---- they are shared with adjacent pixels
|             |        
|             |
|             |
+      X  <- -+- - - - weight = 1/2 = 50%
|             |
|             |
|             |        
X------+------X < - - - weight = 1/8 = 12.5%

This is essentiall a blur.



======== 3. standard 2x2 supersample 

4 samples are taken within a pixel,
equi-distance from each other,
and from samples from adjacent pixels

+------+------+
|      |      |        
|  x       x  |
|      |      |
+ - - - - - - +
|      |      |
|  x       x  |
|      |      |        
+------+------+


======== 4. 3Dfx rotated grid        

4 samples are taken within a pixel.
equi-distance from each other,
and from samples from adjacent pixels

^^^ SOUND FAMILIAR? ^^^
    Yup, it's very much like 2x2,

    EXCEPT....

The pixel grid is rotated:

+------+------+
|    X-| - - -| - - - - }
|             |         } dy = constant
|      |    X | - -}- - }
+ - - - - - - +    } dy
| X- - | - - -|- - }- }
|             |       } dy
|      | X - -| - - - }       
+------+------+
  ^  ^   ^  ^
  |  |   |  |
  |  -----  |
  |  |dx |  |
  |  |   ----
  ----     dx = constant

     dx = dy

3Dfx rotation angle is such that the four points are 
EQUI-DISTANCE from each other IN BOTH ORTHOGONAL DIRECTIONS.

Thus, when a near horizontal or near vertical plane moves 
through the pixel, instead of seeing 2 steps (as in a 2x2 AA):
(step 1 = passing through the top    (or right) two samples)
(step 2 = passing through the bottom (or left)  two samples)

You will see 4 steps:
(step 1 = passing through the first sample)
(step 2 = passing through the second sample)
(step 3 = passing through the third sample)
(step 4 = passing through the fourth sample)

This is maximum possible steps!  4 steps for 4 samples.


MATHEMATICS FOR THE ANGLE:

It's not so hard.
Picture the bottom & right dots, and make a right triangle:

    X
   /|
  / o
 /  |
 X--o

The angle is within a triangle of:
- oppsite side = exactly 2x length of adjacent.

 tan( angle ) =    opp / adj
 tan( angle ) =      1 / 2
      angle   = atan(1 / 2)
              = 26.5650512 degrees 
              = 0.46364760 radians


HARD CODE THE RESULT FOR SPEED:

Rotate a point (0.25, 0.25), from the 2x2,
by 26.5650512 degrees:
    
    vec2 p = rotateX( 
        vec2(0.25, 0.25),  
        0.463647609 );  // radians (26.5650512 degrees)

Result = (x,y) = 0.11218413712, 0.33528304367
               =     small    ,     large

The 4 resultant dots (rotated 26.5 degrees clockwise) are:
 1. -small, +large
 2. +large, +small
 3. +small, -large
 4. -large, -small


======== 5. standard NxN supersample 

Subdivides the pixel by N in both directions.
For N = 4:

+------+------+
| X  X | X  X |        
|             |
| X  X | X  X |
+ - - - - - - +
| X  X | X  X |        
|             |
| X  X | X  X |
+------+------+


======== 6. & 7. random supersample       

Same as NxX, except it's random.
6. This could be static, which avoids moire patterns.
7. However, this should CHANGE EVERY FRAME, to produce random photons reaching your eye.
   Thus, this should run at the HIGHEST FRAME-RATE for best results:

+-X----+---X--+
X    X | X    |        
| X    X      X
|   X  |   X  |
+ - - - -X- - +
X  X   |    X |        
|    X   X    |
| X    |   X  X
X----X-+-X----+



======== 8. ADDITIONAL METHODS: EXERCISE FOR THE READER:

7A. make a higher sample rate for 3Dfx's method, say a 4x4 grid.
7B. compare identical sample numbers, say 4x4 square vs. 4x4 random.
7C. define DISABLE_RND_TEMPORAL_COHERENCE to see random NxN with static sample locations.

*/


// ---- MINOR SETTINGS --------------------------------

#define CIRCLE_PERCENTAGE_OF_SCREEN 0.90
#define MIN_ZOOM 1.0
#define MAX_ZOOM 8.0
#define COLOR_TITLE      vec3( 0.0, 0.3, 1.0 ) // text
#define BG_COLOR         vec3( 1.0, 0.8, 0.6 )
#define COLOR_ZOOM       vec3( 0.0, 0.7, 0.0 )
#define COLOR_EQUALS     vec3( 0.0, 0.0, 0.0 )
#define COLOR_ZOOMFACTOR vec3( 1.0, 0.0, 0.0 )


// ---- GLOBALS --------------------------------

    // TODO -- could prefix these with "g" or "g_"

    #define PI 3.1415926535897932384626
    
    // quantized zoom:
    float ZOOM;

    // ORIGINAL positions BEFORE zoom:
    vec2 origM; // 0..1
    vec2 origP; // 0..1

    // MODIFIED based on quantized zoom, used in many functions:
    vec2  res; // resolution
    vec2  mou; // mouse coordinates


// ---- 8< ---- 8< ---- 8< ---- 8< ---- 8< ---- 8< ----
// ---- GLSL NUMBER PRINTING --------------------------------
// ---- @P_Malin --------------------------------

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
          :/*x==8 ?*/ 481111.0/*
          :       481095.0*/;
    else
    if (x < 78)
        return // Glyphs added by Michael Pohoreski
           x==42 ?  21072.0 // *
          :x==45 ?   3840.0 // -
          :x==61 ?  61680.0 // =
          //:x==65 ? 434073.0 // A
          //:x==66 ? 497559.0 // B
          :x==67 ? 921886.0 // C
          :/*x==68 ?*/ 498071.0 // D
          //:x==69 ? 988959.0 // E
          //:x==70 ? 988945.0 // F
          //:x==71 ? 925086.0 // G
          //:x==72 ? 630681.0 // H
          //:x==73 ? 467495.0 // I
          //:x==74 ? 559239.0 // J
          //:x==75 ? 611161.0 // K
          //:x==76 ?  69919.0 // L
          //:        653721.0 // M
          ;
    else
    if (x < 91)
        return // Glyphs added by Michael Pohoreski
           x==78 ? 638361.0 // N
          //:x==79 ? 432534.0 // O
          //:x==80 ? 497425.0 // P
          :x==81 ? 432606.0 // Q
          :x==82 ? 497561.0 // R
          //:x==83 ? 923271.0 // S
          //:x==84 ? 467490.0 // T
          //:x==85 ? 629142.0 // U
          //:x==86 ? 349474.0 // V
          //:x==87 ? 629241.0 // W
          //:x==88 ? 628377.0 // X
          //:x==89 ? 348706.0 // Y
          :        475671.0;// Z
    return 0.0;
}

// ---- 8< ---- 8< ---- 8< ---- 8< ---- 8< ---- 8< ----


// ---- TEXT --------------------------------

vec2 gvPrintCharXY = vec2( 0.0, 0.0 );
vec3 Char(  vec3 backgroundColor, vec3 textColor, vec2 fragCoord, float fValue )
{
    vec2 vStringCharCoords = (fragCoord.xy - gvPrintCharXY) / gvFontSize;
    if ((vStringCharCoords.y < 0.0) || (vStringCharCoords.y >= 1.0)) return backgroundColor;
    if ( vStringCharCoords.x < 0.0)                                  return backgroundColor;

    float fCharBin = (vStringCharCoords.x < 1.0) ? DigitBin(int(fValue)) : 0.0;

    // Auto-Advance cursor one glyph plus 1 pixel padding
    // thus characters are spaced 9 pixels apart    
    // except for characters 3 pixels wide
    // TODO -- LOTS OF COMPARES... BAD?
    float fAdvance = /* false        
        || (fValue == 42.) // *
        || (fValue == 73.) // I
        || (fValue == 84.) // T
        || (fValue == 86.) // V
        || (fValue == 89.) // Y
        || (fValue == 90.) // Z        
        ? 0.0 // glyph width has no padding
        : */ 1.0; 
    gvPrintCharXY.x += gvFontSize.x + fAdvance;
        
    float a = floor(
        mod(
            (fCharBin / pow(
                2.0, 
                floor(fract(vStringCharCoords.x) * 4.0) + (floor(vStringCharCoords.y * 5.0) * 4.0))), 
            2.0)
    );
    return mix( backgroundColor, textColor, a );
}


// ---- UTILITY --------------------------------

vec2 rotateXY( vec2 p, float angleRadians )
{
    float s = sin( angleRadians );
    float c = cos( angleRadians );
    mat2  m = mat2( c, -s, 
                    s,  c );
    return m * p; // vec2
}

// De facto "noise" function, modified to supply two values
vec2 noise2( vec2 location, vec2 delta ) {
    const vec2 c = vec2(12.9898, 78.233);
    const float m = 43758.5453;
    return vec2(
        fract(sin(dot(location +      delta            , c)) * m),
        fract(sin(dot(location + vec2(delta.y, delta.x), c)) * m)
        );
}


// ---- PATTERNS TO ANTI-ALIAS --------------------------------

// patternSet_circleWithSpokes
vec3 pattern1( vec2 uv )
{    
    // full circle
    vec2 p = (2.*uv - 1.) / CIRCLE_PERCENTAGE_OF_SCREEN;
   
    // quick semi-distance to circle formula:
    float g = dot( p, p );

    float t = iGlobalTime * 0.15;
    float insideCircle = float(int(g * 5.                    + t));
    float insideSpokes = float(int(atan(p.y, p.x) / PI * 12. + t));
    return vec3(mod(insideCircle + insideSpokes, 2.0));
}

// patternSet_2Dchecker
vec3 pattern2(vec2 uv)
{
    // correct for aspect ratio    
    float aspect = iResolution.y/iResolution.x;
    
    // rotate with time distortion in Y    
    float angle = -iGlobalTime * 0.05;
    
    // TODO -- I suspect this could be massively optimized.
    //         We are translating, rotating, scaling, translating
    //         Twice.  Grabbing coordinates within each.

    const float NUM_CELLS = 8.0;
    const float SHIFT_POSITIVE = 32.0; // ensure no negatives are rendered, since we use int(x)
    
    vec2 pStart = uv.xy - vec2(0.5);
    pStart.y *= aspect;
    
    // 1. normal checkerboard
    
    // translate
    vec2 p1 = pStart;
    // rotate
    p1 = rotateXY( p1, angle );
    // translate back
    p1 += vec2(SHIFT_POSITIVE + 0.5);    
    float checkerboard1 = float(int(p1.x*NUM_CELLS)) + float(int(p1.y*NUM_CELLS));
    
    // 2. 45 degree rotated checkerboard, zoomed to match vertices
    
    // translate
    vec2 p2 = pStart;
    // rotate
    p2 = rotateXY( p2, angle + PI / 4.0);
    // expand
    p2 *= 1.41421356237;
    // translate back
    p2 += vec2(SHIFT_POSITIVE + 0.5);
    float checkerboard2 = float(int(p2.x*NUM_CELLS)) + float(int(p2.y*NUM_CELLS));
    
    // combine
    return vec3(mod(checkerboard1 + checkerboard2, 2.0));
}

// patternSet_3Dchecker
vec3 pattern3(vec2 uv)
{
    // distance from center
    vec2 dCenter = vec2(0.5, 0.5) - uv.xy;
    
    float X_INV_SCALE = 1.5;
    float Z_INV_SCALE = 0.6;
    
    // 3D perspective: 1/Z = constant
    vec3 cam;
    cam.z = 1.0 / dCenter.y;
    cam.xy = vec2(
        X_INV_SCALE * dCenter.x,
        Z_INV_SCALE)
         * cam.z;

    // rotate
    float angle = (iGlobalTime * 0.05) 
        * float(uv.y < 0.5); // only allow the ground to rotate, not the ceiling
    cam.xy = rotateXY( cam.xy, angle );

    // textured
    return vec3(
        mod(
            float(fract(cam.x) < 0.5) + 
            float(fract(cam.y) < 0.5), 
            2.0
           )
               );
}

vec3 pixelSet(vec2 uv)
{
    
    // our position (already quantized ZOOM):
    // res is the NEW resolution after ZOOM
    vec2 p = uv.xy / res.xy; 
    
    // get slow time:
    float tDistort = iGlobalTime * 1.5 + 
        dot( 
            origP, 
            vec2(0.5, 0.5) // NOTE: changing X vs. Y will change the angle of the swipe fade
        );
    
    // the idea is that we will cycle through a bunch of "frames"
    // each "frame" is either:
    // 1. a static image of a pattern 
    //    (well, the pattern itself may be animating, but that's its own discretion)
    // 2. a fade between two patterns.
    // Since all "frames" are the same time length,
    // we should double / triple (or more) up frames for static patterns,
    // so the fades take a short amount of time.    
    
    const float REPEAT_PER_PATTERN = 9.0; // number of frames of just a single pattern (between fades)
    const float NUM_FRAMES_PER_PATTERN = REPEAT_PER_PATTERN + 1.0; // + 1.0 for the fade
    
    const float NUM_PATTERNS = 3.0;

    const float NUM_FRAMES = NUM_PATTERNS * NUM_FRAMES_PER_PATTERN;

    // Thus for our three patterns, with a repeat of 2:
    // E.g.:
    // 1. A
    // 2. A
    // 3. A -> B  
    // 4.      B
    // 5.      B
    // 6.      B -> C
    // 7.           C
    // 8.           C
    // 9. A <------ C
    
    // Thus for our three patterns, with a repeat of 3:
    // E.g.:
    //  1. A
    //  2. A
    //  3. A
    //  4. A -> B  
    //  5.      B
    //  6.      B
    //  7.      B
    //  8.      B -> C
    //  9.           C
    // 10.           C
    // 11.           C
    // 12. A <------ C
    
    float t = mod(tDistort, NUM_FRAMES ); // 0.0..NUM_FRAMES, wraps
    float f = smoothstep(0.0, 1.0, fract(tDistort)); // change from linear to smooth
    
    // Optimized    
         if (t < REPEAT_PER_PATTERN                              ) return     pattern1(p);
    else if (t < NUM_FRAMES_PER_PATTERN)                           return mix(pattern1(p), pattern2(p), f);
    else if (t < REPEAT_PER_PATTERN + NUM_FRAMES_PER_PATTERN     ) return                  pattern2(p);
    else if (t < NUM_FRAMES_PER_PATTERN * 2.)                      return mix(             pattern2(p), pattern3(p), f);
    else if (t < REPEAT_PER_PATTERN + NUM_FRAMES_PER_PATTERN * 2.) return                               pattern3(p);
    else                                                           return mix(                          pattern3(p), pattern1(p), f);
}

// ---- HUD TITLE & ZOOM --------------------------------

vec3 drawTitle( in vec2 fragCoord, 
               // TODO --- these are equidistant, so why not pass in START and DELTA_X?
               float mx0, 
               float mx1, 
               float mx2, 
               float mx3, 
               float mx4,
               float mx5)
{
    vec3 color = BG_COLOR;
    
    float scale  = iResolution.x;
    float center = (mx1 - mx0) * 0.5 * scale;

    gvPrintCharXY.y = iResolution.y - gvFontSize.y - 1.;
    
    gvPrintCharXY.x = mx0*scale - center;
    color = Char( color, COLOR_TITLE, fragCoord, 45. ); // -

    gvPrintCharXY.x = mx1*scale - center;
    color = Char( color, COLOR_TITLE, fragCoord, 81. ); // Q
    color = Char( color, COLOR_TITLE, fragCoord, 67. ); // C

    gvPrintCharXY.x = mx2*scale - center;
    color = Char( color, COLOR_TITLE, fragCoord,  2. ); // 2
    color = Char( color, COLOR_TITLE, fragCoord, 42. ); // *

    gvPrintCharXY.x = mx3*scale - center;
    color = Char( color, COLOR_TITLE, fragCoord,  3. ); // 3
    color = Char( color, COLOR_TITLE, fragCoord, 68. ); // D

    gvPrintCharXY.x = mx4*scale - center;
    color = Char( color, COLOR_TITLE, fragCoord, 78. ); // N
    color = Char( color, COLOR_TITLE, fragCoord, 42. ); // *

    gvPrintCharXY.x = mx5*scale - center;
    color = Char( color, COLOR_TITLE, fragCoord, 82. ); // R
    color = Char( color, COLOR_TITLE, fragCoord, 1.  ); // 1

    gvPrintCharXY.x = mx5*scale + center;
    //                          ^-- positive, to show on the other side of the line

    color = Char( color, COLOR_TITLE, fragCoord, 82. ); // R
    color = Char( color, COLOR_TITLE, fragCoord, 2.  ); // 2

    return color;
}

vec3 drawZoom ( vec2 fragCoord, vec3 color ) 
{
    // "Z=x" text, where x = the zoom factor
    gvPrintCharXY = vec2( 1.0, iResolution.y - gvFontSize.y - 1. );
    
    //color = drawStatus( color, fragCoord, nameLit, equalsLit );
    color = Char( color, COLOR_ZOOM  , fragCoord, 90.0 ); // Z
    color = Char( color, COLOR_EQUALS, fragCoord, 61.0 ); // =

    // show Zoom factor in upper-left
    color = Char( color, COLOR_ZOOMFACTOR, fragCoord, ZOOM );    
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
    
    // ---- RESET ZOOM WHEN (LIKELY) IN THUMBNAIL MODE ----

    // if we're not using the mouse
    // AND the window size is LIKELY THAT of a thumbnail,
    // force defaults to show off a nice thumbnail:
    // NOTE: this will think it's a thumbnail, even when not, if you're in a very small browser window,
    //       since the site will shrink the output target to the size of a thumbnail.
    // ALSO: the site increases thumbnail sizes if your browser window is large; this makes life difficult! :(

    // method of changing X and Y without if-statements:
    
    float multChange = 
        float(iMouse.z < 0.5) * 
        float(iResolution.y < 310.0);
    
    // 0.5 = center, to see most of the AA methods
    origM.x = mix(origM.x, 0.5, multChange);
    
    // 1.5 is the middle of the ZOOM=2 region
    origM.y = mix(origM.y, 1.5 / MAX_ZOOM, multChange);

    
    // ---- ZOOM QUANTIZE ----
    
    // get ZOOM factor from the original positions
    ZOOM = MIN_ZOOM + 
        floor(
            origM.y * (MAX_ZOOM + 0.99 - MIN_ZOOM) // +0.99 since we floor() the result, 
                                               // and want MAX_ZOOM to be selectable as well
             ); // needs to be integer 
                // (unless you want cool but inaccurate video game pixel blur animations)
    ZOOM = clamp(ZOOM, MIN_ZOOM, MAX_ZOOM); // can get out of range when window resizes.
    
    
    // ---- COMPUTE SPLIT SCREEN SECTIONS ----
        
    // mouse position relative
    float mx0 = origM.x - 0.40;
    float mx1 = origM.x - 0.20;
    float mx2 = origM.x       ;
    float mx3 = origM.x + 0.20;
    float mx4 = origM.x + 0.40;
    float mx5 = origM.x + 0.60;
        
    vec3 color = vec3( 0.0 );

    // ----------------------------------------------------------------
    // 1. Header
    // background bar
    if (fragCoord.y > (iResolution.y - gvFontSize.y - 2.0))
    {
        // the AA method names:
        color = drawTitle( fragCoord, mx0, mx1, mx2, mx3, mx4, mx5 );
        color = drawZoom ( fragCoord, color );
    }
    
    // ----------------------------------------------------------------
    // 2. Main Image (between the header/footer)
    else
    {
        // ---- QUANTIZE TO ZOOM ----
        
        vec2 uv = floor(fragCoord / ZOOM) * ZOOM;
        
        // then do actual zoom (center zoom on 0.5,0.5)
        res = (vec2(0.5, 0.5) - iResolution.xy) / ZOOM;
        mou = (vec2(0.5, 0.5) - iMouse.xy     ) / ZOOM;
        uv  = (vec2(0.5, 0.5) - uv.xy         ) / ZOOM;
        
        // ---- SPLIT SCREEN ---- DIFFERENT AA METHODS ----
        
        /* (UNOPTIMIZED VERSION)
             if (origP.x < mx0) color = pixelSet   ( uv ); // no AA
        else if (origP.x < mx1) color = aa_quincunx( uv ); // 2 samples          }
        else if (origP.x < mx2) color = aa_2x2     ( uv ); // 4 samples          }-> similar algorithms (in this shader, that is = share code)
        else if (origP.x < mx3) color = aa_3dfx    ( uv ); // 4 samples (better) }
        else if (origP.x < mx4) color = aa_nxn     ( uv ); // 16 samples
        else                    color = aa_random  ( uv ); // 64 samples
        */
        
        // TODO -- we should show the resultant if-statement layoyut below
        //         in a simple format where we just call getColorX(),
        //         and setCommon(), so that we can see what we've optimized,
        //         in terms of if statement depth.

        // ---- METHOD 1. NO AA ----
        
        if( origP.x < mx0 )
        {
            color = pixelSet   ( uv );
        }
        else
          
        // ===========================
        // EXPLANATION
        // ===========================
        // Because pixel shaders don't like too many if-statements, we tried to reduce them.
        // Since 2x2, Quincunx, and 3Dfx are so similar pixel-shader-wise, we combined them.
        // Individually, this isn't optimal, but globally (for the pixel shader to use less
        // "if-statement resources", it is.  THIS MEANS MORE PEOPLE CAN RUN THIS SHADER.
        // ===========================
            
        if (origP.x < mx3) {
            
            // ---- METHOD 2 & 3 & 4 ---- ALL ARE SHARING SOME PIXEL SHADER CODE ----

            // ---- METHOD 3. 2x2 ----
            
            // fragCoord = pixel, not normalized
            vec2  q = vec2( 0.25, 0.25 ); // common factor: aa_2x2(), aa_3dfx()
            
            float w1 = 0.25;
            float w2 = 0.0 ;
            

            // ---- METHOD 4. 3DFX ----

            if (origP.x > mx2) {
                // WE KNOW THE RESULT OF THIS:
                // small = 0.11218413712
                // large = 0.33528304367
                q = vec2(0.11218413712, 0.33528304367);
            }
            
            // ---- METHOD 2. QUINCUNX ----

            if (origP.x < mx1) {
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
                (
                    pixelSet(uv + vec2(-q.x, +q.y)) +
                    pixelSet(uv + vec2(+q.y, +q.x)) +
                    pixelSet(uv + vec2(+q.x, -q.y)) +
                    pixelSet(uv + vec2(-q.y, -q.x))
                )                                     * w1 +
                pixelSet(uv + vec2( 0.0,  0.0))       * w2
            );
        }
        
        // ---- METHOD 5. NxN ----
        
        else if (origP.x < mx4) {

            #define invNxN (1. / float(METHOD_NXN_N))

            for (int i=0; i<METHOD_NXN_N; i++) {
                float n1 = float(i) * invNxN;
                for (int j=0; j<METHOD_NXN_N; j++) {
                    
                    // TODO: could be optimized with additions of a single constant delta 
                    //       applied to both x and y.
                    // TODO: along with that optimization, the vec(.5,.5) could be placed
                    //       there too.
                    
                    float n2 = float(j) * invNxN;                    
                    
                    vec2 offset = vec2(n1, n2) - vec2(0.5, 0.5); 
                    color += pixelSet(uv + offset);
                }
            }
            color /= float(METHOD_NXN_N * METHOD_NXN_N);
        }

        // ---- METHOD 6. RANDOM NxN STATIC ----
        // ---- METHOD 7. RANDOM NxN DYNAMIC ----
        
        else
        {
            float t = (origP.x > mx5 ? iGlobalTime : 1.0);
            for (int i=0; i<METHOD_RND_NXN_N; i++) {
                for (int j=0; j<METHOD_RND_NXN_N; j++) {
                    
                    // noise
                    vec2 q = t * vec2(float(i), float(j)); // this could partially be optimized outside the loop
                    vec2 n = noise2( uv , q );
                    vec2 offset = vec2(n.x, n.y) - vec2(0.5, 0.5);
                    color += pixelSet(uv + offset);
                }
            }
            color /= float(METHOD_RND_NXN_N * METHOD_RND_NXN_N);           
        }        
    }
    
    // ---- GAMMA CORRECTION ----
    
   
    // TODO -- if we're always doing grayscale, then we need to compute only one of these.
    //         in fact, that goes for the ENTIRE PROGRAM, except for the bars after this:
    // CAUTION: It likely isn't any faster, since vec3(v) is probably just as fast as float(v)
    //          And the HUD is colorized.  But we could return early for them.  But it makes the code ugly.
    //          It only really saves on this gamma correction AFTER super-sampling is done:
    
    const float invGamma = 1. / GAMMA_CORRECTION;    
    color = vec3(pow(color.r, invGamma),
                 pow(color.g, invGamma),
                 pow(color.b, invGamma));

    // ---- SHOW BLACK BAR SPLITS BETWEEN AA METHODS ----

    // float fade = 1.0; // TODO: Need to account for mouse y position: m.y;
    #define X1 0.002
    #define X2 0.003
    color *=        smoothstep( X1, X2, abs(origP.x-mx0) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx1) );
    color.g += 1. - smoothstep( X1, X2, abs(origP.x-mx2) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx3) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx4) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx5) );

    
    // ---- FINAL RESULT ----
    fragColor = vec4(color, 1.);
    
}
