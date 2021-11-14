#version 410


//Define and Uniforms
uniform vec2 iResolution;
uniform mat4 iMat;
#define AA 3

//Constants
const float maxDistance = 30.0;
const float epsilon = 0.001;

const float maxShadowDistance = 10.0;
const float shadowEpsilon = 0.005;

// Lighting
const float kAmbient = 0.35;
const float kDiffuse = 1.0 - kAmbient;

const float shadowK = 30.0;

const float aoIncrement = 0.02;
const float aoK = 4.0;

// Other scene globals
const vec3 toSun = normalize(vec3(-1.0, 3.75, 2.0));

// Number of iterations for the Sierpinski IFS
const int sierpinskiLevel = 5;

const vec3[] vertices = vec3[](
    vec3(1.0, 1.0, 1.0),
    vec3(-1.0, 1.0, -1.0),
    vec3(-1.0, -1.0, 1.0),
    vec3(1.0, -1.0, -1.0));

// Get a 2D rotation matrix
mat2 getRotationMatrix(float angle)
{
	return mat2(cos(angle), sin(angle),
                -sin(angle), cos(angle));
}

// Get a surface color based on a point's location
// Uses a procedural palette from iq
// https://www.shadertoy.com/view/ll2GD3
vec3 getColor(vec3 point)
{
    // Set t such that the floor color will change slowly
    // and the tetrahedron color will change more rapidly
    float t;
    if (point.y < -1.9) {
        t = point.x / 60.0 + 0.2;
    }
    else {
        point /= 2.0;
     	t = point.x * point.x - point.y + point.z * point.z;
    }
    
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.00, 0.10, 0.20);
	vec3 color = a + b*cos( radians(360.0)*(c*t+d) );
    
    // Lighten the color a bit
    return mix(color, vec3(1.0), 0.3);
}

// Signed distance to a floor plane
float sdFloor(vec3 point, float floorY)
{
	return point.y - floorY;
}

// Signed distance to a tetrahedron within canonical cube
// https://www.shadertoy.com/view/Ws23zt
float sdTetrahedron(vec3 point)
{
    return (max(
	    abs(point.x + point.y) - point.z,
	    abs(point.x - point.y) + point.z
	) - 1.0) / sqrt(3.);
}

// Fold a point across a plane defined by a point and a normal
// The normal should face the side to be reflected
vec3 fold(vec3 point, vec3 pointOnPlane, vec3 planeNormal)
{
    // Center plane on origin for distance calculation
    float distToPlane = dot(point - pointOnPlane, planeNormal);
    
    // We only want to reflect if the dist is negative
    distToPlane = min(distToPlane, 0.0);
    return point - 2.0 * distToPlane * planeNormal;
}

// Signed distance to Sierpinski tetrahedron at specified level
// Rotates over time or with mouse press
float sdSierpinski(vec3 point, int level)
{
    float scale = 1.0;
    for (int i = 0; i < level; i++)
    {
    	// Scale point toward corner vertex, update scale accumulator
        point -= vertices[0];
        point *= 2.0;
        point += vertices[0];
        
        scale *= 2.0;
        
        // Fold point across each plane
        for (int i = 1; i <= 3; i++)
        {
         	vec3 normal = normalize(vertices[0] - vertices[i]); 
            point = fold(point, vertices[i], normal);
        }
    }
    return sdTetrahedron(point) / scale;
}

// Returns signed distance to the scene
float scene(vec3 point)
{
    // Create a sierpinski tetrahedron and a floor
 	float sierpinskiDist = sdSierpinski(point, sierpinskiLevel);
    float floorDist = sdFloor(point, -2.0);
    
    return min(sierpinskiDist, floorDist);
}

// Approximates the normal at an intersection by calculating the gradient of the distance function
vec3 estimateNormal(vec3 point) {
	return normalize(vec3(
        scene(vec3(point.x + epsilon, point.y, point.z)) - scene(vec3(point.x - epsilon, point.y, point.z)),
        scene(vec3(point.x, point.y + epsilon, point.z)) - scene(vec3(point.x, point.y - epsilon, point.z)),
        scene(vec3(point.x, point.y, point.z  + epsilon)) - scene(vec3(point.x, point.y, point.z - epsilon))));
}

float calcAO(vec3 surfacePoint, vec3 normal)
{
    float t = aoIncrement;
    float distSum = 0.0;
    for (int i = 0; i < 4; i++)
    {
        vec3 point = surfacePoint + t * normal;
     	float dist = scene(point);
        
        distSum += exp2(-float(i)) * (t - dist);
        
        t += aoIncrement;
    }
    return 1.0 - aoK * distSum;
}


float calcShadow(vec3 surfacePoint)
{
    // Initialize our marching variables
 	vec3 point = surfacePoint;
    float t;
    float illumination = 1.0;
    

    for (t = 2.0 * shadowEpsilon; t < maxShadowDistance;)
    {
     	point = surfacePoint + t * toSun;
        float dist = scene(point);
        
        // The path to the sun is blocked
        if (dist < shadowEpsilon) {
            return 0.0;
        }
        
        // Get darker if we get closer to the scene than we have been before
        illumination = min(illumination, shadowK * dist/t);
        t += dist;
    }
    return illumination;
}

// Shades a surface at the given point
vec3 shadeSurface(vec3 point) {
    // Calculate the surface normal and color of our point
    vec3 normal = estimateNormal(point);
    vec3 surfaceColor = vec3(0.56,0.42,0.33);
    
    vec3 color = vec3(0.8);
	float diffuseIntensity = max(dot(normal, toSun), 0.0);
    float illumination = calcShadow(point);
    diffuseIntensity *= illumination;
    color +=   diffuseIntensity * surfaceColor * vec3(0.8);

    if (point.y > -2.0 + epsilon) {
        float occlusion = calcAO(point, normal);
        color *= occlusion;
    }
    
    return color;
}

vec3 castRay(vec3 rayOrigin, vec3 rayDir)
{
    vec3 point = rayOrigin;
    float t;
    vec3 color = vec3(0.8);
    
    for (t = 0.0; t < maxDistance; point = rayOrigin + t * rayDir)
    {
     	float dist = scene(point);
        
        // We got a hit
        if (dist <= epsilon) {
            color = shadeSurface(point);
        	break;
        }
        t += dist;
    }
    float totalDist = t / maxDistance;
    return mix(color, vec3(0.8), totalDist * totalDist);
}

mat3 SliceMatrix(mat4 mat)
{
    vec3 a = vec3(mat[0][0],mat[0][1],mat[0][2]);
    vec3 b = vec3(mat[1][0],mat[1][1],mat[1][2]);
    vec3 c = vec3(mat[2][0],mat[2][1],mat[2][2]);

    return mat3(a,b,c);
}

void main()
{   
    vec3 total = vec3(0.0);
    mat3 bufferMatrix = SliceMatrix(iMat);

    float x = iMat[3][0];
    float y = iMat[3][1];
    float z = iMat[3][2];

    for( int m=0; m<AA; m++ )
        for( int n=0; n<AA; n++ )
            {
                vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
                vec2 p = (-iResolution.xy + 2.0*(gl_FragCoord.xy+o))/iResolution.y;

                vec3 rd = bufferMatrix * normalize( vec3(p.xy,2.0) );

                vec3 color = castRay(vec3(x,y,z), rd);

                color = pow( color, vec3(0.4545) );

                total +=color;
            }
    total /= float(AA*AA);


    gl_FragColor = vec4(total, 1.0);
}