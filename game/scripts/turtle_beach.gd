extends Node3D

signal reached_water
const S = preload("res://scripts/shapes.gd")
const NEST := Vector3(-3,0,43)
const AFTER := 0.73
var active := false
var home := false
var progress := 0.0
var babies: Array[Node3D] = []
var flippers: Array = []
var eggs: Node3D
var signpost: Label3D

func route(t: float) -> Vector3:
	return NEST+Vector3(3.8*sin(t*PI*1.15)+t*4.0,0,t*23.1)

func build(land: Node3D) -> void:
	beach_sand()
	land.flat_disc(self,NEST+Vector3.UP*0.08,2.16,1.65,"e9d298")
	eggs = S.group(self,NEST)
	for i in 10:
		var a := i*TAU/10
		S.ball(self,NEST+Vector3(sin(a)*1.55,0.1,cos(a)*1.18),Vector3(0.31,0.15,0.24),"ccae79",7)
	for j in 18:
		var p := route((j+1)/23.0)
		for side in [-1,1]:
			var print_pos := p+Vector3(side*(0.40+j%2*0.12),0.10,side*0.13)
			S.ball(self,print_pos,Vector3(0.11,0.013,0.21),"b99566",7)
	for i in 3:
		var p := NEST+Vector3((i-1)*0.74,0.18,0.22*sin(i*2))
		S.ball(eggs,p-NEST+Vector3.UP*0.12,Vector3(0.32,0.45,0.33),"fff0c9",12)
		for k in 3:
			S.ball(eggs,p-NEST+Vector3(0.19*sin(k*2),0.24,0.20*cos(k*2)),Vector3.ONE*0.078,"dbb98a",7)
		var turtle := S.group(self,p)
		babies.append(turtle)
		var shell_color: String = ["609e83","71a676","6ba5a0"][i]
		S.ball(turtle,Vector3(0,0.16,0),Vector3(0.34,0.23,0.45),shell_color,12)
		S.ball(turtle,Vector3(0,0.18,0.45),Vector3(0.17,0.15,0.19),"a1c982")
		for side in [-1,1]:
			S.ball(turtle,Vector3(side*0.112,0.23,0.56),Vector3.ONE*0.035,"324c40")
		for k in 5:
			var a := k*TAU/5
			S.ball(turtle,Vector3(sin(a)*0.17,0.332,cos(a)*0.22),Vector3(0.10,0.042,0.12),"b5cf92",7)
		var limbs := []
		for side in [-1,1]:
			for end in [-1,1]:
				var limb := S.ball(turtle,Vector3(side*0.30,0.055,end*0.23),Vector3(0.20,0.054,0.10),"95bb79",8)
				limbs.append(limb)
		flippers.append(limbs)
		turtle.hide()
	signpost = Label3D.new()
	signpost.text = "Schildpadstrand"
	signpost.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	signpost.font_size = 38
	signpost.outline_size = 7
	signpost.pixel_size = 0.007
	signpost.position = NEST+Vector3(-1.7,1.45,-0.9)
	add_child(signpost)

func start() -> void:
	active = true
	eggs.hide()
	for baby in babies:
		baby.show()
	signpost.text = "Loop mee naar zee!"

func restore() -> void:
	home = true
	progress = 1.0
	eggs.hide()
	signpost.text = "Groetjes uit zee!"
	for baby in babies:
		baby.show()

func animate(dt: float, time: float, foot: Vector3) -> void:
	if not active and not home:
		eggs.rotation.z = 0.045*sin(time*6)*maxf(0,cos(time*2))
		return
	var leader := route(progress)
	var moving := home or foot.distance_to(leader)<4.8
	if moving:
		progress = minf(1,progress+dt*(0.037 if home else 0.087))
		if progress>=AFTER and not home:
			home = true
			active = false
			signpost.text = "Groetjes uit zee!"
			reached_water.emit()
	for i in babies.size():
		var t := maxf(0,progress-i*0.018)
		var p := route(t)
		p.x += (i-1)*0.78
		var swim := smoothstep(0.85,1.0,progress)
		p.z += (12.5+sin(time*0.75+i)*0.55)*swim
		p.y = 0.13+absf(sin(time*6+i))*0.045 if moving else 0.14
		p.y = lerpf(p.y,-1.22+sin(time*2+i)*0.10,smoothstep(68.0,75.0,p.z))
		babies[i].position = p
		var heading := route(t+0.01)-route(t)
		babies[i].rotation.y = atan2(heading.x,heading.z)+swim*sin(time+i)*0.28
		for k in 4:
			flippers[i][k].rotation.y = (0.45*sin(time*7+i+k*2) if moving else 0.12)

func beach_sand() -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last := PackedVector3Array()
	for j in 44:
		var t := j/43.0
		var p := route(t*1.10-0.10)
		var width := 0.12+smoothstep(0,0.16,t)*3.6+t*t*5.0
		var row := PackedVector3Array([
			p+Vector3(-width-0.65*sin(t*14),0.045,0),
			p+Vector3(width+0.6*sin(t*11),0.045,0)])
		if j:
			for v in [last[0],last[1],row[0],last[1],row[1],row[0]]:
				mesh.set_normal(Vector3.UP)
				mesh.add_vertex(v)
		last = row
	var sand := S.mat("e5c98c").duplicate() as StandardMaterial3D
	sand.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_material(sand)
	S.add(self,mesh.commit(),Vector3.ZERO,Vector3.ONE,"")
	for i in 22:
		var t := i/28.0
		var side := 1 if i%2==0 else -1
		var p := route(t)+Vector3(side*(3.8+sin(i*2.4)*0.8+t*t*4),0.06,0)
		for reed in 4:
			var offset := Vector3(sin(reed*2.4)*0.18,0,cos(reed*2.4)*0.18)
			S.tube(self,p+offset,p+offset*2.3+Vector3(0.22,0.42+0.13*cos(i+reed),0),0.045,0.009,"9eaf79",5)
		if i%4==0:
			S.ball(self,p+Vector3(0.21,0,0.3),Vector3(0.22,0.11,0.19),"c7af90",7)
	var log_at := NEST+Vector3(-3.7,0.17,4.4)
	S.tube(self,log_at,log_at+Vector3(0.62,0.07,1.65),0.19,0.12,"b6987b",8)
	S.tube(self,log_at+Vector3(0.34,0.1,0.85),log_at+Vector3(-0.32,0.38,1.12),0.10,0.046,"b6987b",7)
