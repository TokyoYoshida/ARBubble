//
//  StringShader.metal
//  GoodbyeMessage
//
//  Created by TokyoYoshida on 2020/07/30.
//  Copyright © 2020 TokyoMac. All rights reserved.
//
//  Quote from : http://glslsandbox.com/e#66295.7
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct VertexInput {
    float3 position  [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeBuffer {
    float4x4 modelViewProjectionTransform;
};

struct ColorInOut
{
    float4 position [[ position ]];
    float2 texCoords;
};

vertex ColorInOut vertexShader(VertexInput          in       [[ stage_in ]],
                               constant NodeBuffer& scn_node [[ buffer(0) ]])
{
    ColorInOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    
    return out;
}

float3 hsv2rgb(  float3 c )
{
    float3 rgb = clamp( abs(fmod(c.x*6.0+float3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( float3(1.0), rgb, c.y);
}

fragment float4 fragmentShader(ColorInOut in          [[ stage_in] ],
                              constant   float& time [[ buffer(0) ]],
                              texture2d<float> texture [[ texture(0) ]])
{
    float2 position = in.texCoords;
    int width = texture.get_width();
    int height = texture.get_height();
    float2 resolution = float2(width, height);

    float2 uv = -1.0 + 2.0*position.xy / resolution.xy;
    uv.x *=  resolution.x / resolution.y;

    // background
    float3 color = float3(0.8 + 0.2*uv.y);

    // bubbles
    for( int i=0; i<40; i++ )
    {
        // bubble seeds
        float pha =      sin(float(i)*546.13+1.0)*0.5 + 0.5;
        float siz = pow( sin(float(i)*651.74+5.0)*0.5 + 0.5, 4.0 );
        float pox =      sin(float(i)*321.55+4.1) * resolution.x / resolution.y;

        // buble size, position and color
        float rad = 0.1 + 0.5*siz;
        float2  pos = float2( pox, -1.0-rad + (2.0+2.0*rad)*fmod(pha+0.1*time*(0.2+0.8*siz),1.0));
        float dis = length( uv - pos );
        float3  col = mix( float3(0.94,0.3,0.0), float3(0.1,0.4,0.8), 0.5+0.5*sin(float(i)*1.2+1.9));
        //    col+= 8.0*smoothstep( rad*0.95, rad, dis );
        
        // render
        float f = length(uv-pos)/rad;
        f = sqrt(clamp(1.0-f*f,0.0,1.0));
        color -= col.zyx *(1.0-smoothstep( rad*0.95, rad, dis )) * f;
    }

    // vigneting
    color *= sqrt(1.5-0.5*length(uv));

    float4 ret = float4(color,1.0);
    
    return ret;
}
