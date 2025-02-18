#version 450

layout(set=1, binding=0) uniform UniformBufferObject {
	vec3 pos;
} ubo;

layout(location=0) in vec3 inPosition;
layout(location=1) in vec3 inColor;
// layout(location=2) in vec2 inTexCoord;

layout(location=0) out vec3 fragColor;

void main() {
	gl_Position = vec4(inPosition + ubo.pos , 1.0);
	fragColor = inColor;
}