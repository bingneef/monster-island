shader_type spatial;
render_mode cull_disabled;
void fragment() {
	float u = UV.x + 0.016*sin(UV.y*2.0-TIME*3.0);
	float stream = sin(u*83.0 + 1.7*sin(u*35.0));
	float glint = smoothstep(0.80,0.98,stream)*smoothstep(-0.1,0.8,sin(UV.y*3.8 - TIME*7.5 + u*12.0));
	float rim = smoothstep(0.40,0.5,abs(UV.x-0.5));
	ALBEDO = mix(vec3(0.13,0.65,0.71),vec3(0.71,0.94,0.9),0.12+0.64*max(glint,rim)+0.1*stream);
	ROUGHNESS = 0.85;
}
