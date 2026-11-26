shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 p = world.xz;
	float wave = sin(p.y*9.0 + 1.1*sin(p.x*2.1 + TIME) + TIME*1.9);
	float fleck = smoothstep(0.87,0.98,wave)*smoothstep(0.54,0.91,sin(p.x*2.6+sin(p.y*2.0)-TIME*0.55));
	vec3 shallow = vec3(0.10,0.70,0.71);
	vec3 deep = vec3(0.055,0.56,0.66);
	ALBEDO = mix(mix(deep,shallow,0.5+0.5*sin(p.y*0.6+p.x*0.24)),vec3(0.65,0.94,0.86),fleck*0.65);
	ROUGHNESS = 0.74;
}
