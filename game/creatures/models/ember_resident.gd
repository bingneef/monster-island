extends Node3D
const S = preload("res://scripts/shapes.gd")
const R = preload("res://creatures/models/ribbons.gd")

var base: String
var trim: String
var light: String

func build(kind: Resource) -> void:
	base = kind.cloak[0]
	trim = kind.cloak[1]
	light = kind.cloak[2]
	match kind.display_name:
		"Sylvendra": sylvendra()
		"Aurelon": aurelon()
		"Gyralune": gyralune()
		"Voltaris": core(false)
		"Voltarium": core(true)

# The rings of each ribbon follow a smoothed 3D spine, tapering at both ends.
func ribbon(knots: PackedVector3Array, width: float, color: String, depth := 0.46) -> void:
	var curve := Curve3D.new()
	for i in knots.size():
		var tangent := (knots[mini(i+1,knots.size()-1)]-knots[maxi(i-1,0)])/6
		curve.add_point(knots[i],-tangent,tangent)
	curve.bake_interval = 0.055
	var points := curve.get_baked_points()
	var widths := PackedFloat32Array()
	var colors := []
	for i in points.size():
		widths.append(width*(0.035+0.965*pow(maxf(0.0,sin(PI*i/(points.size()-1))),0.65)))
		colors.append(color)
	R.strand(self,points,widths,colors,depth)

func eye(p: Vector3) -> void:
	S.ball(self,p,Vector3(0.046,0.05,0.04),"2a3743")
	S.ball(self,p+Vector3(0,0.017,0.028),Vector3.ONE*0.015,"fffbe0")

func sylvendra() -> void:
	S.ball(self,Vector3(0,0.43,0.25),Vector3(0.22,0.14,0.29),base)
	for side in [-1,1]:
		eye(Vector3(side*0.145,0.46,0.43))
	for i in 9:
		var angle := TAU*i/9
		var x := cos(angle)
		var z := sin(angle)
		var start := Vector3(x*0.09,0.43,0.22)
		var stem := Vector3(x*0.47,0.13,z*0.31-0.18)
		var end := Vector3(x*0.52+0.16*sin(i*2),-0.88+0.32*cos(i*2),z*0.41)
		ribbon([start,Vector3(x*0.32,0.36+0.22*z,0.04),stem,Vector3(x*0.23+0.11,-0.40,z*0.38),end],0.078,[base,trim,light][i%3])
		if i%2==0:
			ribbon([stem,stem+Vector3(x*0.20,0.05,-0.06),stem+Vector3(x*0.31,0.18,-0.13)],0.085,trim)
	for side in [-1,1]:
		ribbon([Vector3(0,0.46,0.31),Vector3(side*0.22,0.64,0.04),Vector3(side*0.45,0.70,-0.27),Vector3(side*0.62,0.55,-0.46)],0.07,light)

func aurelon() -> void:
	var hull := Vector3(0,0,-0.08)
	S.ball(self,hull,Vector3(0.24,0.23,0.64),base)
	ribbon([Vector3(0,-0.07,0.26),Vector3(0,0.22,0.45),Vector3(0,0.56,0.43),Vector3(0,0.71,0.32)],0.17,base,0.88)
	S.ball(self,Vector3(0,0.70,0.43),Vector3(0.15,0.13,0.29),base)
	for side in [-1,1]:
		eye(Vector3(side*0.117,0.74,0.55))
		ribbon([Vector3(side*0.08,0.76,0.56),Vector3(side*0.14,0.85,0.34),Vector3(side*0.21,0.90,0.11),Vector3(side*0.26,0.82,-0.12)],0.046,trim)
		ribbon([Vector3(side*0.17,0.05,0.38),Vector3(side*0.26,0.16,0.02),Vector3(side*0.35,0.28,-0.44),Vector3(side*0.43,0.49,-0.72)],0.13,light)
		for z in [0.28,-0.44]:
			var hip := Vector3(side*0.16,-0.02,z)
			var knee := hip+Vector3(side*0.035,-0.27,-0.065)
			var hoof := hip+Vector3(side*0.055,-0.53,0.015)
			S.tube(self,hip,knee,0.103,0.061,base)
			S.tube(self,knee,hoof,0.062,0.035,trim)
			S.ball(self,hoof,Vector3(0.055,0.045,0.077),trim)
	ribbon([hull,Vector3(0,0.05,-0.5),Vector3(0.07,0.14,-0.81),Vector3(0.17,0.08,-1.07),Vector3(0.25,-0.11,-1.18)],0.13,trim)

func gyralune() -> void:
	S.ball(self,Vector3.ZERO,Vector3(0.075,0.41,0.10),trim)
	for side in [-1,1]:
		var s := float(side)
		ribbon([Vector3(0,-0.05,0),Vector3(s*0.39,-0.01,-0.04),Vector3(s*0.70,0.12,-0.13),Vector3(s*0.80,0.59,-0.18),Vector3(s*0.72,0.63,-0.16),Vector3(s*0.19,0.54,0),Vector3(0,0.29,0.04)],0.085,base)
		for lower in [false,true]:
			var center := Vector3(s*(0.34 if not lower else 0.20),0.27 if not lower else -0.36,0.03)
			var knots := PackedVector3Array([Vector3(0,-0.04,0)])
			for j in 26:
				var t := j/25.0
				var a := t*TAU*1.58-PI*0.48
				var r := lerpf(0.245,0.012,t)
				knots.append(center+Vector3(s*cos(a)*r,sin(a)*r,0.035*t))
			ribbon(knots,0.045,trim if lower else light,0.73)

func core(armored: bool) -> void:
	# Layered bevels surround an inset face on the shield and a translucent-looking bright facet on the prism.
	var rings := []
	for layer in [Vector3(0.04,-0.66,0.04),Vector3(0.29,-0.39,0.18),Vector3(0.36,0.37,0.22),Vector3(0.24,0.54,0.15),Vector3(0.01,0.55,0.01)]:
		rings.append(S.ring(Vector2(layer.x,layer.z),layer.y,6,0))
	S.bands(self,rings,[trim,base,trim,light])
	var face := "193d42" if armored else base
	S.box(self,Vector3(0,0.04,0.185),Vector3(0.38,0.62,0.075),face)
	for side in [-1,1]:
		var x: float = side*0.81
		var size := Vector3(0.44,0.23,0.27) if armored else Vector3(0.32,0.34,0.26)
		var pod := S.box(self,Vector3(x,0.02,0),size,trim)
		S.box(pod,Vector3(0,0,0.5),Vector3(0.79,0.71,0.12),face)
		var start := Vector3(side*0.29,0.05,0)
		for j in 3:
			var end := Vector3(side*(0.39+0.105*j),0.03+0.06*cos(j*PI),0)
			S.tube(self,start,end,0.019,0.019,light,6)
			start = end
		if armored:
			S.tube(self,Vector3(x,-0.09,0),Vector3(x-side*0.10,-0.37,0),0.095,0.009,base,5)
		S.tube(self,Vector3(x-0.045,-0.053,0.16),Vector3(x+0.048,0.076,0.16),0.024,0.012,light,5)
	if armored:
		for side in [-1,1]:
			S.tube(self,Vector3(side*0.21,-0.32,0.19),Vector3(side*0.24,0.36,0.19),0.047,0.052,trim,5)
		ribbon([Vector3(0.08,0.28,0.24),Vector3(-0.065,0.02,0.24),Vector3(0.061,0.04,0.24),Vector3(-0.07,-0.24,0.24)],0.054,light)
	else:
		S.box(self,Vector3(-0.10,0.03,0.23),Vector3(0.047,0.57,0.023),light)
