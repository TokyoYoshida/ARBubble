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
    float x, y, width, height;
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

float rand(float3 init_sheed)
{
    int seed = init_sheed.x + init_sheed.y * 57 + init_sheed.z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

vertex ColorInOut2 vertexShader2(VertexInput2          in       [[ stage_in ]],
                                 constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                               constant NodeBuffer2& scn_node [[ buffer(1) ]])
{
    ColorInOut2 out;
    float3 pos = in.position;
//    uv.x += sin(uv.y);
//    uv.z += uv.y*0.1;
    pos.x += cos(pos.y*100 + scn_frame.time)*0.01;
    pos.y += cos(pos.x*100 + scn_frame.time)*0.01;
    pos.z += cos(pos.y*100 + scn_frame.time)*0.01;
    float4 transformed = scn_node.modelViewProjectionTransform * float4(pos, 1.0);
//    transformed.x += cos(transformed.y);
//    out.position = float4(uv, 1.0);
    out.position = transformed;
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 fragmentShader2(ColorInOut2 in          [[ stage_in] ],
                                texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                              device GlobalData2 &globalData [[buffer(1)]])
{
    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    float2 uv = in.texCoords;
    float time =globalData.time;
    float2 screenPos =float2(globalData.x, globalData.y);

    float2 alpha = float2(5, 5);
    float2 center = screenPos;
    
    float2 samp = ((uv - center) / alpha) + center;
    float4 color = diffuseTexture.sample(sampler2d, samp);
//    color.r = 1;
    
    return color;
}

