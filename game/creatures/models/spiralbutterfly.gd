extends Node3D
const S = preload("res://scripts/shapes.gd")
const R = preload("res://creatures/models/ribbons.gd")
var wings: Array[Node3D] = []
var time := 0.0

func wing(pivot: Node3D, side: int, upper: bool) -> void:
	var pts := PackedVector3Array()
	var widths := PackedFloat32Array()
	var colors := []
	var center := Vector2(0.48,0.26) if upper else Vector2(0.29,-0.26)
	var radius := Vector2(0.49,0.33) if upper else Vector2(0.33,0.21)
	for j in 72:
		var t := j/71.0
		var a := PI + t*TAU*1.74*(1 if upper else -1)
		var off := Vector2(cos(a),sin(a))*radius*(1.0-t*0.96)
		off.y += off.x*(0.52 if upper else -0.56)
		pts.append(Vector3(side*(center.x+off.x),center.y+off.y,0.04*sin(a)))
		widths.append(0.012+sin(PI*pow(t,0.60))*(0.12 if upper else 0.080))
		colors.append(["164bb4","1882ef","2ed8ff","8af6ff","168fea"][mini(4,floori(t*5))])
	R.strand(pivot,pts,widths,colors,0.38)

func build(_species: Resource) -> void:
	S.ball(self,Vector3.ZERO,Vector3(0.073,0.33,0.078),"225bbf",16)
	S.ball(self,Vector3(0,0.26,0.02),Vector3(0.087,0.091,0.081),"3389e4")
	for side in [-1,1]:
		var pivot := S.group(self)
		wings.append(pivot)
		wing(pivot,side,true)
		wing(pivot,side,false)
		var pts := PackedVector3Array([Vector3(side*0.035,0.31,0),Vector3(side*0.092,0.51,0)])
		var widths := PackedFloat32Array([0.022,0.024])
		var colors := ["245cbf","245cbf"]
		for j in 27:
			var t := j/26.0
			var a := PI+t*TAU*1.12
			var r := 0.086*(1-t*0.88)
			pts.append(Vector3(side*(0.19+r*cos(a)),0.60-r*sin(a),0))
			widths.append(0.024-0.01*t)
			colors.append("245cbf")
		R.strand(self,pts,widths,colors,0.9)

func _process(dt: float) -> void:
	time += dt
	for i in wings.size():
		wings[i].rotation.y = (0.16+0.35*sin(time*7))*(1 if i==0 else -1)
