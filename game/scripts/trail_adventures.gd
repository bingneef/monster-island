extends Node3D

const S = preload("res://scripts/shapes.gd")
const SPRING := Vector3(-21,0,-13)
const PRISMS := [Vector3(-4,0,1),Vector3(1,0,-4),Vector3(4,0,2)]
const CAMP := Vector3(18,0,15)
const BOWS := [Vector3(22,0,13),Vector3(25,0,17),Vector3(22,0,21)]
const PAINT := ["ee806b","f0bd55","62bfbb"]
var turns := [3,1,2]
var collected := [false,false,false]
var flying := false
var repaired := false
var mirrors: Array[Node3D] = []
var bows: Array[Node3D] = []
var tails: Array[Node3D] = []
var rainbow: Node3D
var kite: Node3D
var string: MeshInstance3D
var spring_label: Label3D

func sign_at(at: Vector3, title: String) -> Label3D:
	var signpost := Label3D.new()
	add_child(signpost)
	signpost.position = at
	signpost.text = title
	signpost.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	signpost.pixel_size = 0.007
	signpost.font_size = 36
	signpost.outline_size = 7
	return signpost

func build(land: Node3D) -> void:
	var pond := S.group(self,SPRING)
	land.flat_disc(pond,Vector3.UP*0.04,2.3,1.8,"ddcb97")
	land.flat_disc(pond,Vector3.UP*0.06,2.05,1.55,"62bfc6")
	S.ball(pond,Vector3.UP*0.57,Vector3(0.45,0.77,0.45),"bce4df",7)
	spring_label = sign_at(SPRING+Vector3(0,2,-1.6),"Lichtbron")
	for i in PRISMS.size():
		var base: Vector3 = PRISMS[i]
		S.tube(pond,base,base+Vector3.UP*0.72,0.53,0.39,"aa987e",8)
		var lens := S.group(pond,base+Vector3.UP*0.77)
		mirrors.append(lens)
		S.ball(lens,Vector3.ZERO,Vector3(0.32,0.46,0.32),PAINT[i],7)
		# A brass pointer and a ray both point along local +Z.
		S.tube(lens,Vector3(0,0.03,0.29),Vector3(0,0.03,0.71),0.18,0.005,"e7c471",5)
		var ray := S.tube(lens,Vector3(0,0,0.27),Vector3(0,0,base.length()),0.039,0.023,PAINT[i],7)
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		align_lens(i)
	rainbow = S.group(pond)
	var colors := ["e97f78","f6b963","f1df81","86c79b","74bfdb","ac9dd8"]
	for band in colors.size():
		var radius := 3.22-band*0.139
		var arc := SurfaceTool.new()
		arc.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in 26:
			var a := j*PI/26
			var b := (j+1)*PI/26
			for point in [Vector2(a,radius),Vector2(b,radius),Vector2(b,radius-0.147),Vector2(a,radius),Vector2(b,radius-0.147),Vector2(a,radius-0.147)]:
				arc.add_vertex(Vector3(cos(point.x)*point.y,sin(point.x)*point.y+0.10,0))
		var paint := S.mat(colors[band]).duplicate() as StandardMaterial3D
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		arc.set_material(paint)
		S.add(rainbow,arc.commit(),Vector3.ZERO,Vector3.ONE,"")
	rainbow.hide()

	land.flat_disc(self,CAMP+Vector3.UP*0.07,1.9,1.34,"dac48c")
	S.tube(self,CAMP,CAMP+Vector3.UP*2.36,0.073,0.054,"a17c54")
	sign_at(CAMP+Vector3(-0.4,2.8,0),"Vliegerwei")
	kite = S.group(self,CAMP+Vector3.UP*1.65)
	var tip := Vector3(0,0.81,0)
	var left := Vector3(-0.75,0.1,0)
	var right := Vector3(0.75,0.1,0)
	var bottom := Vector3(0,-0.92,0)
	var corners := [tip,right,bottom,left]
	for i in 4:
		var sail := SurfaceTool.new()
		sail.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [corners[i],corners[(i+1)%4],Vector3(0,0.09,0.19)]:
			sail.add_vertex(v)
		var cloth := S.mat(["f3bc55","65bec5","619faa","ed856f"][i]).duplicate() as StandardMaterial3D
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
		cloth.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sail.set_material(cloth)
		S.add(kite,sail.commit(),Vector3.ZERO,Vector3.ONE,"")
	S.tube(kite,bottom,bottom+Vector3.DOWN*0.88,0.021,0.021,"f5e5b9")
	for i in 3:
		tails.append(make_bow(kite,bottom+Vector3.DOWN*(0.18+i*0.27),i,0.51))
		tails[i].hide()
		bows.append(make_bow(self,BOWS[i]+Vector3.UP*0.78,i,1.0))
	string = S.tube(self,Vector3.ZERO,Vector3.UP,0.015,0.015,"edd6a6",5)
	string.hide()

func make_bow(parent: Node3D, at: Vector3, id: int, size_factor: float) -> Node3D:
	var bow := S.group(parent,at)
	for side in [-1,1]:
		S.tube(bow,Vector3(side*0.36,0.09,0),Vector3.ZERO,0.23,0.045,PAINT[id],4)
	S.ball(bow,Vector3.ZERO,Vector3.ONE*0.11,"fff1c9",8)
	bow.scale *= size_factor
	return bow

func align_lens(i: int) -> void:
	var offset: Vector3 = PRISMS[i]
	mirrors[i].rotation.y = atan2(-offset.x,-offset.z)+int(turns[i])*PI/2

func nearby(foot: Vector3) -> String:
	for i in 3:
		if turns[i]!=0 and foot.distance_squared_to(SPRING+PRISMS[i])<4.0:
			return "lens"+str(i)
		if not collected[i] and foot.distance_squared_to(BOWS[i])<4.0:
			return "bow"+str(i)
	if foot.distance_squared_to(CAMP)<4.5:
		return "kite"
	return ""

func prompt(action: String) -> String:
	if action.begins_with("lens"):
		return "Draai het kristal"
	if action.begins_with("bow"):
		return "Pak de strik"
	if repaired and flying:
		return "Haal de vlieger in"
	return "Laat hem vliegen" if collected.count(true)==3 else "Bekijk de vlieger"

func interact(action: String) -> String:
	if action.begins_with("lens"):
		var i := int(action.right(1))
		turns[i] = (int(turns[i])+1)%4
		align_lens(i)
		rainbow.visible = turns.count(0)==3
		if rainbow.visible:
			spring_label.text = "Regenboogbron"
			return "Kijk omhoog! Jullie eigen regenboog!"
		return "Raak! Nog %d." % (3-turns.count(0)) if turns[i]==0 else "Richt het licht op de steen in de plas."
	if action.begins_with("bow"):
		var i := int(action.right(1))
		collected[i] = true
		bows[i].hide()
		tails[i].show()
		return "Alle strikken! Terug naar de vlieger." if collected.count(true)==3 else "Een strik voor de staart!   %d / 3" % collected.count(true)
	if collected.count(true)<3:
		return "De staart mist strikken. Zoek ze in het gras!"
	repaired = true
	flying = not flying
	string.visible = flying
	return "Neem de vlieger mee op pad!" if flying else "De vlieger rust weer bij de paal."

func animate(dt: float, time: float, hand: Vector3, camera_at: Vector3) -> void:
	for i in 3:
		if bows[i].visible:
			bows[i].rotation.y = sin(time+i)*0.64
			bows[i].position.y = 0.8+0.18*sin(time*2+i)
	var goal := CAMP+Vector3.UP*1.65
	if flying:
		goal = hand+Vector3(2.8+sin(time)*0.45,2.5+cos(time*1.4)*0.28,-1.65)
	kite.position = kite.position.lerp(goal,1-exp(-dt*3))
	kite.rotation.z = 0.12*sin(time*1.3)
	var view := camera_at-kite.position
	kite.rotation.y = lerp_angle(kite.rotation.y,atan2(view.x,view.z)+0.18*sin(time*0.8),1-exp(-dt*5))
	if flying:
		var end := kite.position+Vector3.UP*0.1
		var delta := end-hand
		if delta.length()>0.01:
			string.position = (hand+end)*0.5
			string.quaternion = Quaternion(Vector3.UP,delta.normalized())
			string.scale = Vector3(0.015,delta.length(),0.015)

func snapshot() -> Dictionary:
	return {"turns":turns,"bows":collected,"repaired":repaired,"flying":flying}

func restore(data: Dictionary) -> void:
	var saved_turns: Variant = data.get("turns")
	var saved_bows: Variant = data.get("bows")
	for i in 3:
		if saved_turns is Array and saved_turns.size()==3 and (saved_turns[i] is float or saved_turns[i] is int):
			turns[i] = clampi(int(saved_turns[i]),0,3)
			align_lens(i)
		if saved_bows is Array and saved_bows.size()==3:
			collected[i] = saved_bows[i]==true
			tails[i].visible = collected[i]
			bows[i].visible = not collected[i]
	rainbow.visible = turns.count(0)==3
	if rainbow.visible:
		spring_label.text = "Regenboogbron"
	repaired = collected.count(true)==3 and data.get("repaired")==true
	flying = repaired and data.get("flying")==true
	string.visible = flying
