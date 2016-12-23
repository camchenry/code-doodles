extern number hue;
extern number saturation;
extern number value;
extern number zoom;
extern number translateX;
extern number translateY; 
extern int maxIterations;
extern number realConst;
extern number imagConst;
extern number circleRadius;
extern int supersampling;
extern int mode;

int JULIA = 1;
int MANDELBROT = 2;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
    vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Input: re, im, iterations
// re: real part of point to test
// im: imaginary part of point to test
// iterations: max number of iterations to perform (higher = more detail)
// Returns: vec2 data
// x: is in set? (0 or 1)
// y: smoothing value (for color gradient)
vec2 fractal_julia(float re, float im, int iterations) {
    // complex point to test
    float real = re;
    float imag = im;
    float oldReal;
    float oldImag;

    float limit = circleRadius * circleRadius;

    // Smoothing value for color gradient
    // Ranges from 0 to 1, where 0 = no iterations, 1 = max iterations
    float smoothing = 0;

    // point is in julia set or not?
    bool isInJuliaSet = false;

    // number of iterations completed
    float i;

    for(i = 0; i < iterations; i++) {
        oldReal = real;
        oldImag = imag;

        real = (oldReal * oldReal) - (oldImag * oldImag) + realConst;
        imag = (2 * oldReal * oldImag) + imagConst;
        
        // Check if point lies in circle
        // If it does not, then it is not in the julia set
        float z = (real * real) + (imag * imag);
        smoothing = smoothing + exp(-abs(z));
        if (z > limit) {
            isInJuliaSet = true;
            break;
        }
    }
    smoothing /= iterations;
    return vec2(isInJuliaSet ? 1 : 0, smoothing);
}

// Input: re, im, iterations
// re: real part of point to test
// im: imaginary part of point to test
// iterations: max number of iterations to perform (higher = more detail)
// Returns: vec2 data
// x: is in set? (0 or 1)
// y: smoothing value (for color gradient)
vec2 fractal_mandelbrot(float re, float im, int iterations) {
    // complex point to test
    float real = re;
    float imag = im;
    float oldReal;
    float oldImag;

    float limit = circleRadius * circleRadius;

    // Smoothing value for color gradient
    // Ranges from 0 to 1, where 0 = no iterations, 1 = max iterations
    float smoothing = 0;

    // point is in mandelbrot set or not?
    bool isInSet = false;

    // number of iterations completed
    float i;

    for(i = 0; i < iterations; i++) {
        oldReal = real;
        oldImag = imag;

        real = (oldReal * oldReal) - (oldImag * oldImag) + re;
        imag = (2 * oldReal * oldImag) + im;
        
        // Check if point lies in circle
        // If it does not, then it is not in the mandelbrot set
        float z = (real * real) + (imag * imag);
        if (z > limit) {
            smoothing = i + 1 - log(log(abs(z)))/log(2.0);
            isInSet = true;
            break;
        }
    }
    smoothing /= iterations;
    return vec2(isInSet ? 1 : 0, smoothing);
}

vec4 fractal_color_point(vec2 point_data) {
    bool inSet = point_data.x == 1;
    float smoothing = point_data.y;

    vec3 hsv = vec3(hue + smoothing/4, saturation, inSet ? value : 0);
    vec3 rgb = hsv2rgb(hsv);

    return vec4(rgb.rgb, smoothing*15);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    float width = love_ScreenSize.x;
    float height = love_ScreenSize.y;
    float x = 1.5 * (screen_coords.x - width/2) / (0.5 * zoom * width) + translateX;
    float y = (screen_coords.y - height/2) / (0.5 * zoom * height) + translateY;

    vec4 pixel_color = vec4(0, 0, 0, 0);

    for (int v = 0; v < supersampling; ++v) {
        for (int u = 0; u < supersampling; ++u) {
            float fx = x + float(u) / float(supersampling) / width / zoom;
            float fy = y + float(v) / float(supersampling) / height / zoom;
            vec4 color;

            if (mode == JULIA) {
                color = fractal_color_point(fractal_julia(fx, fy, maxIterations));
            }
            else if (mode == MANDELBROT) {
                color = fractal_color_point(fractal_mandelbrot(fx, fy, maxIterations));
            }
            pixel_color += color;
        }
    }

    pixel_color /= (float(supersampling) * float(supersampling));

    return pixel_color;
}
