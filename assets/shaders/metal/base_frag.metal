/*

SDG                                                                                  JJ

                                 Blank Page Game Jam
                                 Base Fragment Shader
*/

#include <metal_stdlib>

using namespace metal;

struct RasterizerData
{
	float4 position [[position]];
	float4 color;
};

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
	return in.color;
}