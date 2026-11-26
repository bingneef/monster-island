shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool painted = false;
uniform int palette = 0;
void fragment() {
	vec3 c = base_color.rgb;
	if (painted) { c *= COLOR.rgb; }
	float v = max(max(c.r,c.g),c.b);
	float chroma = v-min(min(c.r,c.g),c.b);
	if (v>0.075 && chroma>0.045) {
		if (palette==0 && c.r>c.b*1.5) {
			c = vec3(v, c.g*0.48, 0.045*v+0.055);
		} else if (palette==1 && c.r>=c.b*0.8 && c.r>c.g*0.94) {
			c = vec3(v,0.57*v,0.055*v);
		} else if (palette==2 && c.r>c.g && c.r>c.b) {
			c = c.b>c.g ? vec3(0.12*v,0.46*v,v) : vec3(v,0.77*v,0.10*v);
		} else if (palette==3 && c.g>=c.r*0.75 && c.g>c.b*0.8) {
			c = c.r>c.b*1.65 ? vec3(v,0.65*v,0.06*v) : vec3(0.04*v,0.52*v,v);
		} else if (palette==4 && c.b>c.r) {
			c = vec3(0.57*v,0.12*v,v);
		}
	}
	ALBEDO = c;
	ROUGHNESS = 0.43;
}
