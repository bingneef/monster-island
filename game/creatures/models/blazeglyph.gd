extends Node3D
const S = preload("res://scripts/shapes.gd")
const R = preload("res://creatures/models/ribbons.gd")

func flame(path: Array, color: String, thickness: float) -> void:
	var pts := PackedVector3Array()
	var widths := PackedFloat32Array()
	var colors := []
	# Smooth the drawn silhouette through each control point, tapering to a tip.
	for i in range(path.size()-1):
		for j in 6:
			var t := j/6.0
			var a: Vector4 = path[maxi(i-1,0)]
			var b: Vector4 = path[i]
			var c: Vector4 = path[i+1]
			var d: Vector4 = path[mini(i+2,path.size()-1)]
			var v := b.cubic_interpolate(c,a,d,t)
			pts.append(Vector3(v.x,v.y,v.z))
			widths.append(maxf(0.006,v.w))
			colors.append(color)
	var end: Vector4 = path.back()
	pts.append(Vector3(end.x,end.y,end.z))
	widths.append(0.005)
	R.strand(self,pts,widths,colors,thickness)

func build(_species: Resource) -> void:
	S.ball(self,Vector3(0,-0.11,0),Vector3(0.50,0.48,0.34),"ff7822",20)
	flame([Vector4(-0.06,-0.65,0.10,0.01),Vector4(-0.34,-0.23,0.1,0.21),Vector4(-0.25,0.22,0.08,0.27),Vector4(0.11,0.57,0.02,0.23),Vector4(0.07,0.82,-0.03,0.115),Vector4(0.30,0.96,-0.04,0)],"ff6d12",1.05)
	flame([Vector4(-0.15,-0.58,0.24,0.008),Vector4(-0.30,-0.18,0.25,0.14),Vector4(-0.18,0.17,0.21,0.16),Vector4(0.16,0.52,0.15,0.13),Vector4(0.13,0.79,0.09,0)],"ffd039",0.72)
	flame([Vector4(-0.07,-0.62,0.18,0.012),Vector4(0.17,-0.40,0.20,0.13),Vector4(0.48,-0.13,0.11,0.17),Vector4(0.58,0.16,0.0,0.09),Vector4(0.51,0.40,-0.04,0)],"fa3961",0.9)
	flame([Vector4(-0.06,-0.59,0.24,0.005),Vector4(0.12,-0.38,0.28,0.08),Vector4(0.38,-0.18,0.23,0.095),Vector4(0.52,0.06,0.15,0)],"ffb22b",0.7)
	flame([Vector4(-0.26,-0.38,-0.02,0.05),Vector4(-0.53,-0.07,0,0.13),Vector4(-0.48,0.21,-0.04,0.11),Vector4(-0.39,0.43,-0.07,0)],"ffae22",0.9)
	var mask := S.ball(self,Vector3(0,-0.10,0.30),Vector3(0.36,0.23,0.14),"361f32",24)
	mask.rotation.z = 0.20
	for side in [-1,1]:
		var e := S.ball(self,Vector3(0.15*side,-0.10+0.03*side,0.42),Vector3(0.059,0.098,0.024),"ffe86a",16)
		e.rotation.z = -0.39*side
