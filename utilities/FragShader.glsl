#version 410

//Define and Uniforms
uniform vec2 iResolution;
uniform mat4 iMat;
#define AA 2



float sdPlane( vec3 p )
{
	return p.y;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}



float map( in vec3 pos )
{
    vec3 qos = vec3( fract(pos.x+0.5)-0.5, pos.yz );
    return min( sdPlane(     pos.xyz-vec3( 0.0,0.00, 0.0)),
                sdBox(       qos.xyz-vec3( 0.0,0.25, 0.0), vec3(0.2,0.5,0.2) ) );
}
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, int technique )
{
	float res = 1.0;
    float t = mint;
    float ph = 1e10; 
    
    for( int i=0; i<32; i++ )
    {
		float h = map( ro + rd*t );

        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, 10.0*d/max(0.0,t-y) );
        ph = h;
        
        t += h;
        
        if( res<0.0001 || t>tmax ) break;
        
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ) + 
					  e.yyx*map( pos + e.yyx ) + 
					  e.yxy*map( pos + e.yxy ) + 
					  e.xxx*map( pos + e.xxx ) );
}

float castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    float tp1 = (0.0-ro.y)/rd.y; if( tp1>0.0 ) tmax = min( tmax, tp1 );
    float tp2 = (1.0-ro.y)/rd.y; if( tp2>0.0 ) { if( ro.y>1.0 ) tmin = max( tmin, tp2 );
                                                 else           tmax = min( tmax, tp2 ); }

    
    float t = tmin;
    for( int i=0; i<64; i++ )
    {
	    float precis = 0.0005*t;
	    float res = map( ro+rd*t );
        if( res<precis || t>tmax ) break;
        t += res;
    }

    if( t>tmax ) t=-1.0;
    return t;
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.001 + 0.15*float(i)/4.0;
        float d = map( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 1.5*occ, 0.0, 1.0 );    
}

vec3 render( in vec3 ro, in vec3 rd)
{ 
    vec3  col = vec3(0.0);
    float t = castRay(ro,rd);

    if( t>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
          
		vec3 mate = vec3(0.3);
        vec3  lig = normalize( vec3(-0.1, 0.3, 0.6) );
        vec3  hal = normalize( lig-rd );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 ) * 
                    calcSoftshadow( pos, lig, 0.01, 3.0, 1 );

		float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

		col = mate * 4.0*dif*vec3(1.00,0.70,0.5);
        col +=      12.0*spe*vec3(1.00,0.70,0.5);
        float occ = calcAO( pos, nor );
		float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        col += mate*amb*occ*vec3(0.0,0.08,0.1);
        col *= exp( -0.0005*t*t*t );
    }

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
    mat3 AMatrix = SliceMatrix(iMat);

    float x = iMat[3][0];
    float y = iMat[3][1];
    float z = iMat[3][2];


    vec3 ro = vec3(x,y,z);
    vec3 ta = vec3(x +1 , y , z + 1);


    vec3 tot = vec3(0.0);

    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(gl_FragCoord.xy+o))/iResolution.y;


        vec3 rd = AMatrix * normalize( vec3(p.xy,2.0) );

        vec3 col = render( ro, rd );

        col = pow( col, vec3(0.4545) );

        tot += col;

    }
    tot /= float(AA*AA);


    
    gl_FragColor = vec4( tot, 1.0 );
}