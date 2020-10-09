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

vertex ColorInOut2 vertexShader2(VertexInput2          in       [[ stage_in ]],
                               constant NodeBuffer2& scn_node [[ buffer(0) ]])
{
    ColorInOut2 out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
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

