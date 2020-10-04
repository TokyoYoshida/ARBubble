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

struct GlobalData {
    float2 ch_pos;//   = float2 (0.0, 0.0);             // character position(X,Y)
    float d;// = 1e6;
    float time;
};

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
                              device GlobalData &globalData [[buffer(1)]])
{
    float2 position = in.texCoords;
    float time =globalData.time;
    
    float3 color = float3(0.1, 0.1, 0.1);
    
    color = hsv2rgb(float3(time * 0.3 + position.x - position.y,0.5,1.0));

    return float4(color,0.5);
}

