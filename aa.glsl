// Anti-Aliasing Tests - rev. 30
// May 21-26, 2016
//
// Authors: 
//   Jason Doucette:    https://www.shadertoy.com/user/JasonD        
//                      http://xona.com/jason/
//   Michael Pohoreski: https://www.shadertoy.com/user/MichaelPohoreski
//
// Methods:                     # Samples:
// ----------------------------------------------
// 1. none                      1
// 2. nVidia Quincunx           2
// 3. standard 2x2 supersample  4
// 4. 3Dfx rotated grid         4
// 5. standard NxN supersample  4^2 (N^2 set in #define N_NXN  below)
// 6. random supersample        8^2 (N^2 set in #define N_RAND below)
#define N_NXN  4 // See Note 5 above.
#define N_RAND 8 // See Note 6 above.
//  4x 4 =   16 samples
//  8x 8 =   64 samples
// 16x16 =  256 samples
// 32x32 = 1024 samples


// ---- SETTINGS --------------------------------

#define CIRCLE_PERCENTAGE_OF_SCREEN 0.90
#define MIN_ZOOM 1.0
#define MAX_ZOOM 8.0
#define COLOR_TITLE      vec3( 0.0, 0.3, 1.0 ) // text
#define BG_COLOR         vec3( 1.0, 0.8, 0.6 )
#define COLOR_ZOOM       vec3( 0.0, 0.7, 0.0 )
#define COLOR_EQUALS     vec3( 0.0, 0.0, 0.0 )
#define COLOR_ZOOMFACTOR vec3( 1.0, 0.0, 0.0 )
#define GAMMA_CORRECTION 2.2
	// check gamma:
	// https://www.shadertoy.com/view/ldVSD1

//#define DEBUG_DISABLE_BLACK_BAR_SPLITS
//#define DEBUG_DISABLE_TEXT
//#define DISABLE_RND_TEMPORAL_COHERENCE // this should remain enabled



// ---- GLOBALS --------------------------------

	// TODO -- could prefix these with "g" or "g_"

    // quantized zoom:
    float ZOOM;

    // ORIGINAL positions BEFORE zoom:
    vec2 origM; // 0..1
    vec2 origP; // 0..1

    // MODIFIED based on zoom, used in many functions:
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
#ifndef DEBUG_DISABLE_TEXT
    else
    if (x < 78)
        return // Glyphs added by Michael Pohoreski
           x==42 ?  21072.0 // *
          //:x==45 ?   3840.0 // -
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
#endif
    return 0.0;
}

// ---- 8< ---- 8< ---- 8< ---- 8< ---- 8< ---- 8< ----


// ---- TEXT --------------------------------

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
#endif


// ---- UTILITY --------------------------------

vec2 rotateXY( vec2 p, float angleRadians )
{
    float s = sin( angleRadians );
    float c = cos( angleRadians );
    mat2  m = mat2( c, -s, 
                    s,  c );
    return m * p; // vec2
}

// De facto "noise" changed into two values
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
    
    float quarterTime = iGlobalTime * 0.15;

    float dt = sin(quarterTime) * 0.05;
    // TODO -- LOTS OF COMPARES... BAD?
    bool insideCircle = 
        ((g <  1.0    ) && (g >  0.85   )) ||
        ((g <  0.6    ) && (g >  0.4    )) ||
        ((g < (0.2+dt)) && (g > (0.1+dt)));
    
    const float PI = 3.1415926535897932384626;
    
    // TODO -- can't we replace atan() with some clever dot(),
    //         after all it should return -1..+1, and we could use that as an angle.
    bool insideSpokes = mod(atan(p.y, p.x) + quarterTime/10., PI/8.) < 0.15;
    
    float v = mod(float(insideCircle) *  1.0 + 
                  float(insideSpokes) * (1. - g), 
                  1.333);

    return vec3(v,v,v);
}

// patternSet_2Dchecker
vec3 pattern2(vec2 uv)
{
    // correct for aspect ratio    
    float aspect = iResolution.y/iResolution.x;
    
    // rotate with time distortion in Y
    float angle = -iGlobalTime * 0.2;
    
    // translate
    uv.xy -= vec2(0.5, 0.5);
    uv.y *= aspect;
    // rotate
   	vec2 p = rotateXY( uv, angle );
    // translate back
    p += vec2(0.5, 0.5);
    
    const float NUM_CELLS = 8.0;

    // checkerboard
    float checkerboard = (
        mod(floor(p.x*NUM_CELLS),2.0) == 
        mod(floor(p.y*NUM_CELLS),2.0) 
            ? 1.0
            : 0.0);  
    return vec3(checkerboard);
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
    float angle = iGlobalTime * 0.1;
	cam.xy = rotateXY( cam.xy, angle );

    // textured
    float checkerboard = (
        mod(floor(cam.x), 2.0) == mod(floor(cam.y), 2.0) 
            ? 1.0
            : 0.0);  
    return vec3(checkerboard);
}

vec3 pixelSet(vec2 uv)
{
    
    // our position (already quantized ZOOM):
    // res is the NEW resolution after ZOOM
    vec2 p = uv.xy / res.xy; 
    
    // get slow time:
    float tDistort = iGlobalTime * 1.25 + 
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
    
    const float REPEAT_PER_PATTERN = 4.0; // number of frames of just a single pattern (between fades)
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


/*
INLINED IN MAIN()... DO NOT DELETE THE COMMENTS... DELETE ONLY THE CODE.
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
    
    vec3 c = vec3(0);
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
*/

// ---- HUD TITLE & ZOOM --------------------------------

vec3 drawTitle( in vec2 fragCoord, 
               // TODO --- these are equidistant, so why not pass in START and DELTA_X?
               float mx0, 
               float mx1, 
               float mx2, 
               float mx3, 
               float mx4)
{
    vec3 color = BG_COLOR;
    
    float scale  = iResolution.x;
    float center = (mx1 - mx0) * 0.5 * scale;

#ifndef DEBUG_DISABLE_TEXT
    gvPrintCharXY.y = iResolution.y - gvFontSize.y - 1.;
    
    // no sense in showing anything for "none"
    //gvPrintCharXY.x = mx0*scale - center;
    //color = Char( color, COLOR_TITLE, fragCoord, 45. ); // -

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

    gvPrintCharXY.x = mx4*scale + center;
    //                          ^-- positive, to show on the other side of the line

    color = Char( color, COLOR_TITLE, fragCoord, 82. ); // R
    color = Char( color, COLOR_TITLE, fragCoord, 68. ); // D

#endif // DEBUG_DISABLE_TEXT

    return color;
}

vec3 drawZoom ( vec2 fragCoord, vec3 color ) 
{
    #ifndef DEBUG_DISABLE_TEXT
    // "ZOOM=" text
    gvPrintCharXY = vec2( 1.0, iResolution.y - gvFontSize.y - 1. );
    
    //color = drawStatus( color, fragCoord, nameLit, equalsLit );
    color = Char( color, COLOR_ZOOM  , fragCoord, 90.0 ); // Z
    color = Char( color, COLOR_EQUALS, fragCoord, 61.0 ); // =

    // show Zoom factor bottom left
    color = Char( color, COLOR_ZOOMFACTOR, fragCoord, ZOOM );    
    #endif

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
        
    vec3 color = vec3( 0.0 );

    // ----------------------------------------------------------------
	// 1. Header
    // background bar
    if (fragCoord.y > (iResolution.y - gvFontSize.y - 2.0))
    {
        // the AA method names:
        color = drawTitle( fragCoord, mx0, mx1, mx2, mx3, mx4 );
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
            
        // TODO ------ THIS PART NEEDS AN EXPLANATION OF EVERYTHING THAT'S HAPPENING.
        //             TAKE THE EXPLANATION FROM 3DFX ABOVE, AND THEN ADD ANOTHER FOR QUINCUNX
        //             AND 2X2, THEN A FINAL EXPLANATION OF OUR PIXEL SHADER'S OPTIMIZATION
        //             **OF CODE SIZE** DESPITE DOING MORE WORK THAN THE ORIGINAL HARDWARE AA.
            
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
                pixelSet(uv + vec2(-q.x, +q.y)) * w1 +
                pixelSet(uv + vec2(+q.y, +q.x)) * w1 +
                pixelSet(uv + vec2(+q.x, -q.y)) * w1 +
                pixelSet(uv + vec2(-q.y, -q.x)) * w1 +
                pixelSet(uv + vec2( 0.0,  0.0)) * w2
            );
        }
        
        // ---- METHOD 5. NxN ----
        
        else if (origP.x < mx4) {

            #define invNxN (1. / float(N_NXN))

            for (int i=0; i<N_NXN; i++) {
                float n1 = float(i) * invNxN;
                for (int j=0; j<N_NXN; j++) {
                    
                    // TODO: could be optimized with additions of a single constant delta 
                    //       applied to both x and y.
                    // TODO: along with that optimization, the vec(.5,.5) could be placed
                    //       there too.
                    
                    float n2 = float(j) * invNxN;                    
                    
                    vec2 offset = vec2(n1, n2) - vec2(0.5, 0.5); 
                    color += pixelSet(uv + offset);
                }
            }
            color /= float(N_NXN * N_NXN);
        }

        // ---- METHOD 6. RANDOM NxN ----
        
        else
        {
            #ifdef DISABLE_RND_TEMPORAL_COHERENCE
            float t = 1.0;
            #else
            float t = iGlobalTime;
            #endif                    
            
            for (int i=0; i<N_RAND; i++) {
                for (int j=0; j<N_RAND; j++) {
                    
                    // noise
                    vec2 q = t * vec2(float(i), float(j)); // this could partially be optimized outside the loop
                    vec2 n = noise2( uv , q );
                    vec2 offset = vec2(n.x, n.y) - vec2(0.5, 0.5);
                    color += pixelSet(uv + offset);
                }
            }
            color /= float(N_RAND * N_RAND);           
        }        
    }
    
    // ---- GAMMA CORRECTION ----
    
   
    // TODO -- if we're always doing grayscale, then we need to compute only one of these.
    // TODO -- IN FACT, that goes for the ENTIRE PROGRAM, except for the bars after this:
    
    const float invGamma = 1. / GAMMA_CORRECTION;    
    color = vec3(pow(color.r, invGamma),
                 pow(color.g, invGamma),
                 pow(color.b, invGamma));

    // ---- SHOW BLACK BAR SPLITS BETWEEN AA METHODS ----

#ifndef DEBUG_DISABLE_BLACK_BAR_SPLITS

    // float fade = 1.0; // TODO: Need to account for mouse y position: m.y;
    #define X1 0.002
    #define X2 0.003
    color *=        smoothstep( X1, X2, abs(origP.x-mx0) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx1) );
    color.g += 1. - smoothstep( X1, X2, abs(origP.x-mx2) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx3) );
    color *=        smoothstep( X1, X2, abs(origP.x-mx4) );
#endif

    
    // ---- FINAL RESULT ----
    fragColor = vec4(color, 1.);
    
}
