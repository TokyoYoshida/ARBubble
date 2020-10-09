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
    float x, y;
    int32_t id;
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
                               constant NodeBuffer2& scn_node [[ buffer(1) ]],
                                 device GlobalData2 &globalData [[buffer(2)]],
                                 uint iid [[ instance_id ]])
{
    ColorInOut2 out;
    float3 pos = in.position;
    float time = globalData.time;
//    uv.x += sin(uv.y);
//    uv.z += uv.y*0.1;
    pos.x += cos(pos.y*100 + scn_frame.time + globalData.id)*0.005;
    pos.y += cos(pos.x*100 + scn_frame.time + globalData.id)*0.005;
    pos.z += cos(pos.y*100 + scn_frame.time + globalData.id)*0.005;
    float4 transformed = scn_node.modelViewProjectionTransform * float4(pos, 1.0);
//    transformed.x += cos(transformed.y);
//    out.position = float4(uv, 1.0);
    out.position = transformed;
    out.texCoords = in.texCoords;
    
    return out;
}

float4 waterColor(float time, float2 sp) {
    float2 p = sp * 15.0 - float2(20.0);
    float2 i = p;
    float c = 0.0; // brightness; larger -> darker
    float inten = 0.025; // brightness; larger -> brighter
    float speed = 1.5; // larger -> slower
    float speed2 = 3.0; // larger -> slower
    float freq = 0.8; // ripples
    float xflow = 1.5; // flow speed in x direction
    float yflow = 0.0; // flow speed in y direction

    for (int n = 0; n < 8; n++) {
        float t = time * (1.0 - (3.0 / (float(n) + speed)));
        i = p + float2(cos(t - i.x * freq) + sin(t + i.y * freq) + (time * xflow), sin(t - i.y * freq) + cos(t + i.x * freq) + (time * yflow));
        c += 1.0 / length(float2(p.x / (sin(i.x + t * speed2) / inten), p.y / (cos(i.y + t * speed2) / inten)));
    }
    
    c /= float(8);
    c = 1.5 - sqrt(c);
    return float4(float3(c * c * c * c), 0.0) + float4(0.0, 0.4, 0.55, 0.001);
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
    float4 water = waterColor(time, uv);
    float4 result = color + water;
    
    return result;
}

