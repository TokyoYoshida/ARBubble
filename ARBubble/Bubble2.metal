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

struct GlobalData2 {
    float time;
};

struct VertexInput2 {
    float3 position  [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeBuffer2 {
    float4x4 modelViewProjectionTransform;
};

struct ColorInOut2
{
    float4 position [[ position ]];
    float2 texCoords;
};

vertex ColorInOut2 vertexShader2(VertexInput2          in       [[ stage_in ]],
                               constant NodeBuffer2& scn_node [[ buffer(0) ]])
{
    ColorInOut2 out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    
    return out;
}

float3 hsv2rgb2(  float3 c )
{
    float3 rgb = clamp( abs(fmod(c.x*6.0+float3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( float3(1.0), rgb, c.y);
}

fragment float4 fragmentShader2(ColorInOut2 in          [[ stage_in] ],
                                texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                              device GlobalData2 &globalData [[buffer(1)]])
{
    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    float2 uv = in.texCoords;
    float time =globalData.time;
    
    float2 samp = uv / 5;
    float4 color = diffuseTexture.sample(sampler2d, samp);
//    color.r = 1;
    
    return color;
}

