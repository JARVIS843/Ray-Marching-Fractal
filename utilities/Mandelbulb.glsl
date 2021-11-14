

//Define and Uniforms
uniform vec2 iResolution;
uniform mat4 iMat;

#define AA 2


vec2 isphere( in vec4 sph, in vec3 ro, in vec3 rd )
{
    vec3 oc = ro - sph.xyz;
	float b = dot(oc,rd);
	float c = dot(oc,oc) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt( h );
    return -b + vec2(-h,h);
}

// http://iquilezles.org/www/articles/mandelbulb/mandelbulb.htm
float map( in vec3 p, out vec4 resColor )
{
    vec3 w = p;
    float m = dot(w,w);

    vec4 trap = vec4(abs(w),m);
	float dz = 1.0;
    
	for( int i=0; i<4; i++ )
    {

		dz = 8.0*pow(m,3.5)*dz + 1.0;
      
        // z = z^8+z
        float r = length(w);
        float b = 8.0*acos( w.y/r);
        float a = 8.0*atan( w.x, w.z );
        w = p + pow(r,8.0) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );       
        
        trap = min( trap, vec4(abs(w),m) );

        m = dot(w,w);
		if( m > 256.0 )
            break;
    }

    resColor = vec4(m,trap.yzw);

    return 0.25*log(m)*sqrt(m)/dz;
}

vec3 calcNormal( in vec3 pos, in float t, in float px )
{
    vec4 tmp;
    vec2 e = vec2(1.0,-1.0)*0.5773*0.25*px;
    return normalize( e.xyy*map( pos + e.xyy,tmp ) + 
					  e.yyx*map( pos + e.yyx,tmp ) + 
					  e.yxy*map( pos + e.yxy,tmp ) + 
					  e.xxx*map( pos + e.xxx,tmp ) );
}

float softshadow( in vec3 ro, in vec3 rd, in float k )
{
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<64; i++ )
    {
        vec4 kk;
        float h = map(ro + rd*t, kk);
        res = min( res, k*h/t );
        if( res<0.001 ) break;
        t += clamp( h, 0.01, 0.2 );
    }
    return clamp( res, 0.0, 1.0 );
}

float raycast( in vec3 ro, in vec3 rd, out vec4 rescol, in float px )
{
    float res = -1.0;

    // bounding sphere
    vec2 dis = isphere( vec4(0.0,0.0,0.0,1.25), ro, rd );
    if( dis.y<0.0 ) return -1.0;
    dis.x = max( dis.x, 0.0 );
    dis.y = min( dis.y, 10.0 );

    // raymarch fractal distance field
	vec4 trap;

	float t = dis.x;
	for( int i=0; i<128; i++  )
    { 
        vec3 pos = ro + rd*t;
        float th = 0.25*px*t;
		float h = map( pos, trap );
		if( t>dis.y || h<th ) break;
        t += h;
    }
    
    if( t<dis.y )
    {
        rescol = trap;
        res = t;
    }

    return res;
}

const vec3 light1 = vec3(  0.577, 0.577, -0.577 );

const vec3 light2 = vec3( -0.707, 0.000,  0.707 );

vec3 refVector( in vec3 v, in vec3 n )
{
    return v;
    float k = dot(v,n);
    return (k>0.0) ? v : v-2.0*n*k;
}


vec3 render( in vec2 p, in mat3 matrix , float x1 , float y1 , float z1 )
{
	// ray setup
    const float fle = 1.5;

    vec2  sp = (2.0*p-iResolution.xy) / iResolution.y;
    float px = 2.0/(iResolution.y*fle);

    vec3  ro = vec3( x1, y1, z1 );
	vec3  rd = matrix * normalize((vec4(sp,fle,0.0)).xyz );

	vec4 tra;
    float t = raycast( ro, rd, tra, px );
    
	vec3 col;

    if( t<0.0 )
    {
     	col  = vec3(0.8,.9,1.1);
	}
	else
	{
        col = vec3(0.7);

        vec3  pos = ro + t*rd;
        vec3  nor = calcNormal( pos, t, px );
        
        nor = refVector(nor,-rd);
        
        vec3  hal = normalize( light1-rd);
        float occ = clamp(0.05*log(tra.x),0.0,1.0);
        float fac = clamp(1.0+dot(rd,nor),0.0,1.0);

        float dif = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 )*occ;
        
		vec3 lin = vec3(0.0); 
		     lin +=  4.0*vec3(0.25,0.20,0.15)*dif;
        	 lin +=  4.0*fac*occ;
		col *= lin;
		col = pow( col, vec3(0.7,0.9,1.0) );
    }

	col = pow( col, vec3(0.4545) );

    return col;
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

    mat3 bufferMatrix = SliceMatrix(iMat);

    float x = iMat[3][0];
    float y = iMat[3][1];
    float z = iMat[3][2];

    vec3 col = vec3(0.0);
    for( int j=0; j<AA; j++ )
    for( int i=0; i<AA; i++ )
    {
	    col += render( gl_FragCoord.xy + (vec2(i,j)/float(AA)), bufferMatrix, x , y , z );
    }
	col /= float(AA*AA);

	gl_FragColor = vec4( col, 1.0 );
}