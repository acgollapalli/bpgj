/*

SDG                                                                                  JJ

                                 Blank Page Game Jam
                                  Base Vertex Shader
*/

#include <metal_stdlib>

using namespace metal;

struct RasterizerData
{
	float4 position [[position]];
	float4 color;
};

struct BPGJVertex {
	float3 position;
	float3 color;
};

struct BPGJCamera {
	float3 position;
};

// NOTE(caleb): see sdl docs on buffer indices: https://wiki.libsdl.org/SDL3/SDL_CreateGPUShader
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
			 constant BPGJCamera *camera [[buffer(0)]],
			 constant BPGJVertex *vertices [[buffer(14)]])
{
	RasterizerData out;
	out.position = float4(vertices[vertexID].position + camera->position, 1.0);
	out.color = float4(vertices[vertexID].color,1.0);
	return out;
}
			 