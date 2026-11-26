extends Node3D
const S = preload("res://scripts/shapes.gd")
var pieces: Dictionary = {}
var found: Array = []
var lights: Array[MeshInstance3D] = []
var telescope: Node3D
const PEAK := Vector3(47,6,32)

func build(kinds: Array) -> void:
	for kind in kinds:
		var piece := S.group(self,kind.relic_position)
		pieces[kind.theme] = piece
		match kind.theme:
			"Plus en min":
				for i in 2:
					S.box(piece,Vector3(-0.47+i*0.94,0,0),Vector3(0.09,1.08,0.13),"925937")
					S.box(piece,Vector3(0,-0.5+i,0),Vector3(1.02,0.09,0.13),"c98a4a")
				for row in 3:
					var y := 0.31*row-0.31
					S.tube(piece,Vector3(-0.45,y,0),Vector3(0.45,y,0),0.025,0.025,"f7d996")
					for bead in row+1:
						S.ball(piece,Vector3(-0.31+bead*0.21,y,0),Vector3(0.095,0.13,0.10),["ff714d","ffc64a","f79948"][row])
			"Dieren":
				for side in [-1,1]:
					var shell := S.ball(piece,Vector3(side*0.12,0.05,-0.06),Vector3(0.39,0.47,0.18),"f0b996")
					shell.rotation.z = side*-0.34
				for i in 7:
					var a := (i-3)*0.23
					S.tube(piece,Vector3(0,-0.3,0.12),Vector3(sin(a)*0.7,cos(a)*0.82-0.32,0.11),0.025,0.032,"ffe2a8")
				S.ball(piece,Vector3(0,-0.17,0.19),Vector3.ONE*0.17,"bbf3ec")
			"Ruimte":
				S.ball(piece,Vector3.ZERO,Vector3.ONE*0.32,"ffa768")
				var ring := S.group(piece)
				ring.rotation.z = 0.32
				for i in 24:
					var a := TAU*i/24
					var b := TAU*(i+1)/24
					S.tube(ring,Vector3(cos(a)*0.62,0,sin(a)*0.62),Vector3(cos(b)*0.62,0,sin(b)*0.62),0.057,0.057,"ffde8b")
			"Keer en deel":
				S.box(piece,Vector3.ZERO,Vector3.ONE*0.77,"edaa46")
				for side in [-1,1]:
					for j in 3:
						S.ball(piece,Vector3((j-1)*0.21,(j-1)*0.21,side*0.393),Vector3(0.063,0.063,0.02),"704736")
					for j in 4:
						S.ball(piece,Vector3(side*0.393,(j%2-0.5)*0.35,(floori(j/2.0)-0.5)*0.35),Vector3(0.02,0.063,0.063),"704736")
			"Vlaggen":
				S.tube(piece,Vector3(-0.36,-0.55,0),Vector3(-0.36,0.54,0),0.044,0.044,"835338")
				for i in 3:
					S.box(piece,Vector3(0,0.40-i*0.145,0),Vector3(0.68,0.145,0.07),["db6056","fff3da","539dc3"][i])
	telescope = S.group(self,PEAK)
	for i in 3:
		var a := TAU*i/3
		S.tube(telescope,Vector3(cos(a)*0.8,0,sin(a)*0.8),Vector3.UP*1.42,0.10,0.06,"ac764d")
	S.tube(telescope,Vector3(-0.78,1.29,0),Vector3(0.9,2.05,0),0.18,0.34,"499fa0")
	S.tube(telescope,Vector3(0.85,2.03,0),Vector3(0.98,2.09,0),0.38,0.38,"f4c969")
	for i in 5:
		var p := Vector3((i-2)*0.67,0.18,1.65)
		S.tube(telescope,p-Vector3.UP*0.18,p,0.21,0.18,"987d72")
		lights.append(S.ball(telescope,p+Vector3.UP*0.13,Vector3.ONE*0.16,"66858b",9))

func mark(theme: String) -> void:
	if not pieces.has(theme) or theme in found:
		return
	found.append(theme)
	pieces[theme].hide()
	lights[found.size()-1].material_override = S.mat("ffe27c")

func animate(t: float) -> void:
	for key in pieces:
		var piece: Node3D = pieces[key]
		if piece.visible:
			piece.rotation.y = t*0.9
			piece.position.y = 1.01+sin(t*2.2+piece.position.x)*0.15

var pennants: Array[Node3D] = []
var streamers := CPUParticles3D.new()
func decorate_porch(kinds: Array) -> void:
	var rail := S.group(self,Vector3(5.4,0,-7.4))
	rail.rotation.y = -0.26
	for i in 5:
		var x := (i-2)*0.79
		var top := 2.84+0.063*absf(x)
		var flag := S.group(rail,Vector3(x,top,2.00))
		pennants.append(flag)
		var paper := SurfaceTool.new()
		paper.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [Vector3(-0.34,0,0),Vector3(0,-0.66,0.03),Vector3(0.34,0,0)]:
			paper.add_vertex(v)
		var color := S.mat(["eb9672","6cc1bf","c290ad","e7bc62","a895c6"][i]).duplicate() as StandardMaterial3D
		color.cull_mode = BaseMaterial3D.CULL_DISABLED
		paper.generate_normals()
		paper.set_material(color)
		S.add(flag,paper.commit(),Vector3.ZERO,Vector3.ONE,"")
		var portrait := Sprite3D.new()
		portrait.texture = kinds[i].portrait
		portrait.pixel_size = 0.00145
		portrait.position = Vector3(0,-0.20,0.035)
		flag.add_child(portrait)
		flag.hide()
		S.tube(rail,Vector3(x-0.40,top,2),Vector3(x+0.40,top,2),0.026,0.026,"8d7656",7)
	rail.add_child(streamers)
	streamers.position = Vector3(0,2.1,2.8)
	streamers.emitting = false
	streamers.one_shot = true
	streamers.amount = 44
	streamers.lifetime = 2.35
	streamers.explosiveness = 0.82
	streamers.direction = Vector3.UP
	streamers.spread = 56
	streamers.gravity = Vector3(0.38,-1.9,0)
	streamers.initial_velocity_min = 1.8
	streamers.initial_velocity_max = 3.1
	streamers.angular_velocity_min = 90
	streamers.angular_velocity_max = 240
	var confetti := BoxMesh.new()
	confetti.size = Vector3(0.08,0.12,0.024)
	var ink := StandardMaterial3D.new()
	ink.vertex_color_use_as_albedo = true
	confetti.material = ink
	streamers.mesh = confetti
	var color_band := Gradient.new()
	color_band.colors = PackedColorArray([Color("#ffbc6e"),Color("#f28e92"),Color("#a7eac5"),Color("#b9b1ff")])
	streamers.color_initial_ramp = color_band
