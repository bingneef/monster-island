extends Node3D
const S = preload("res://scripts/shapes.gd")
const R = preload("res://creatures/models/ribbons.gd")
var rotors: Array[Node3D] = []

func build(_species: Resource) -> void:
	for sign_x in [-1,1]:
		var hub := S.group(self,Vector3(sign_x*0.48,-0.12,0))
		rotors.append(hub)
		var tire := TorusMesh.new()
		tire.inner_radius = 0.25
		tire.outer_radius = 0.42
		tire.rings = 36
		tire.ring_segments = 12
		var wheel := S.add(hub,tire,Vector3.ZERO,Vector3.ONE,"119e86")
		wheel.rotation.x = PI/2
		for face in [-1,1]:
			var pts := PackedVector3Array()
			var widths := PackedFloat32Array()
			var colors := []
			for j in 55:
				var t := j/54.0
				var a: float = t*TAU*1.6*sign_x
				var r := 0.025+0.34*t
				pts.append(Vector3(cos(a)*r,sin(a)*r,face*(0.065+0.055*(1-t))))
				widths.append(0.019+0.059*sin(PI*t))
				colors.append(["ffe33f","96da31","25bf87"][mini(2,floori(t*3))])
			R.strand(hub,pts,widths,colors,0.65)
		S.tube(self,Vector3(sign_x*0.12,0.05,0),hub.position,0.065,0.088,"98c43d")
	S.ball(self,Vector3(0,0.08,0.06),Vector3(0.17,0.33,0.16),"aace36",16)
	for side in [-1,1]:
		S.ball(self,Vector3(side*0.091,0.11,0.19),Vector3(0.038,0.066,0.025),"243c43")
		S.ball(self,Vector3(side*0.09,0.14,0.211),Vector3.ONE*0.014,"e9ffd6")
	S.tube(self,Vector3(0,0.27,0),Vector3(0,0.53,0),0.09,0.065,"5a9b48")
	var panel := S.group(self,Vector3(0,0.53,0))
	panel.rotation.x = 0.45
	S.box(panel,Vector3.ZERO,Vector3(1.10,0.067,0.55),"f5ca39")
	for col in 5:
		for row in 2:
			S.box(panel,Vector3((col-2)*0.203,0.039,(row-0.5)*0.237),Vector3(0.188,0.022,0.216),["1c607a","245a8a"][(row+col)%2])

func _process(dt: float) -> void:
	for i in rotors.size():
		rotors[i].rotation.z += dt*(0.85 if i==0 else -0.85)
