extends Node3D
const S = preload("res://scripts/shapes.gd")
var rng := RandomNumberGenerator.new()
var blockers: Array[Vector3] = []
var spray: Array[Node3D] = []
var static_art: Node3D
var water_mat := ShaderMaterial.new()
const POND := Vector2(-37,-14)
const SHORE := Vector2(75,61)
const FALL_SHIFT := Vector3(-31,0,-9.2)

func _ready() -> void:
	rng.seed = 2081
	static_art = S.group(self)
	water_mat.shader = preload("res://scripts/water.gdshader")
	island()
	horizon()
	falls()
	cottage()
	plant_island()
	star_hill()


func formation(parent: Node3D, pos: Vector3, layers: Array, palette: Array, count: int, phase: float, uneven: float) -> Node3D:
	var cluster := S.group(parent,pos)
	var rings := []
	for layer: Vector3 in layers:
		rings.append(S.ring(Vector2(layer.x,layer.z),layer.y,count,phase,uneven))
	S.bands(cluster,rings,palette,0.012 if count==64 else 0.08)
	return cluster

func flat_disc(parent: Node3D, pos: Vector3, rx: float, rz: float, color: String, uneven := 0.06) -> MeshInstance3D:
	var rings := [S.ring(Vector2(rx,rz),0,40,0.7,uneven), S.ring(Vector2(0.001,0.001),0,40)]
	var n := S.bands(parent,rings,[color],0.01)
	n.position = pos
	return n

func island() -> void:
	formation(static_art,Vector3.ZERO,[Vector3(88,-2.7,73),Vector3(85,-0.88,71),Vector3(80,-0.25,66),Vector3(79,0,65),Vector3(0.01,0,0.01)],["d99968","f5d18b","96c755","86c952"],64,0.7,0.04)
	var sea := S.box(static_art,Vector3(0,-1.45,0),Vector3(540,0.15,540),"229fbd")
	sea.material_override = water_mat
	flat_disc(static_art, Vector3(POND.x,0.018,POND.y),4.45,3.34,"e5d996")
	var pond := flat_disc(static_art,Vector3(POND.x,0.033,POND.y),4.18,3.12,"58d4d2")
	pond.material_override = water_mat
	# A winding sandy lane leads from the landing to the cottage.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev := PackedVector3Array()
	for i in 54:
		var t := i/53.0
		var z := lerpf(12.3,-7.8,t)
		var x := path_x(z)
		var w := 0.97+0.19*sin(t*9)+0.13*cos(t*15)
		var edge := PackedVector3Array([Vector3(x-w,0.018,z),Vector3(x+w,0.018,z)])
		if i>0:
			for v in [prev[0],prev[1],edge[0],prev[1],edge[1],edge[0]]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
		prev = edge
	var sand := S.mat("edcf8c").duplicate() as StandardMaterial3D
	sand.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(sand)
	S.add(static_art,st.commit(),Vector3.ZERO,Vector3.ONE,"")
	for i in 120:
		var z := rng.randf_range(-7.3,11.7)
		var size := rng.randf_range(0.035,0.13)
		S.ball(static_art,Vector3(path_x(z)+rng.randf_range(-0.83,0.83),0.024,z),Vector3(size,0.014,size*0.57),"dcba7b",6)

func path_x(z: float) -> float:
	return 1.8+2.5*tanh(-z*0.20)+0.65*sin(z*0.65)

func horizon() -> void:
	var peak := Vector3(2,-1.5,-72)
	var rings := []
	for layer in [Vector3(17,0,11),Vector3(10,3.0,7),Vector3(6.6,5.5,5.6),Vector3(3.1,10.0,3.0),Vector3(1.9,12.5,1.65),Vector3(1.3,12.4,1.2)]:
		var ring := S.ring(Vector2(layer.x,layer.z),layer.y,18,0.5,0.085)
		for i in ring.size():
			ring[i].y += 0.34*sin(i*4.7)
		rings.append(ring)
	var mt := S.group(static_art,peak)
	S.bands(mt,rings,["659d89","629783","968486","a47268","f6a165"],0.12)
	for i in 5:
		var a := -0.92+i*0.5
		var pos := Vector3(sin(a)*1.83,12.35,cos(a)*1.7)
		for j in 3:
			var b := Vector3(sin(a)*(2.25+j*0.47)+0.14*sin(i+j),11.8-j*0.74,cos(a)*(2.14+j*0.60))
			S.tube(mt,pos,b,0.11-j*0.022,0.095-j*0.03,"ffa048",5)
			pos = b
	for i in 6:
		var puff := 0.58+i*0.14
		S.ball(mt,Vector3(0.15+i*i*0.095,13.0+i*0.72,0),Vector3(puff,puff*0.70,puff),"ffe4ca",10)
	for i in 17:
		var a := TAU*i/17
		var island_pos := Vector3(sin(a)*99,-1.7,cos(a)*95)
		var h := rng.randf_range(2.3,6.2)
		formation(static_art,island_pos,[Vector3(11,0,8),Vector3(6,h*0.64,4),Vector3(2.4,h,1.7),Vector3(0.01,h+0.3,0.01)],["62a8a1","78b7a0","9bc8a1"],9,a,0.14)
	for i in 24:
		var a := TAU*i/24
		var c := Vector3(108*sin(a),rng.randf_range(9.5,21),108*cos(a))
		for j in rng.randi_range(3,5):
			var r := rng.randf_range(1.4,3.0)
			S.ball(static_art,c+Vector3(j*2.1,rng.randf_range(0,0.7),0),Vector3(r*1.35,r*0.63,r),"fff9df",10)

func falls() -> void:
	for k in [[-8.6,-7.4,3.1,2.85],[-5.8,-8.2,4.3,2.8],[-3.7,-8.8,2.8,2.1]]:
		var at := Vector3(k[0],0,k[1])+FALL_SHIFT
		var h: float = k[2]
		var r: float = k[3]
		formation(static_art,at,[Vector3(r*1.13,0,r),Vector3(r*1.05,h*0.44,r*0.93),Vector3(r*0.95,h-0.24,r*0.84),Vector3(r,h,r*0.9),Vector3(0.01,h,0.01)],["ab9079","bb9e80","749f53","84bf57"],10,k[0],0.08)
		blockers.append(Vector3(at.x,at.z,r))
	var sheet := SurfaceTool.new()
	sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges := []
	for j in 5:
		var edge := PackedVector3Array()
		for i in 17:
			var u := i/16.0
			var width: float = [1.77,1.83,1.88,1.93,2.13][j]
			var y: float = [4.34,4.34,4.17,3.83,0.16][j]
			var z: float = [-6.98,-5.78,-5.49,-5.38,-4.91][j]
			edge.append(Vector3(-5.8+(u-0.5)*width,y,z+0.034*sin(i*1.7)))
		edges.append(edge)
	for j in 4:
		for i in 16:
			for off in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var v: Vector3 = edges[j+off.y][i+off.x]
				sheet.set_uv(Vector2((i+off.x)/16.0,4.35-v.y+(v.z+6.98)))
				sheet.set_normal(Vector3(0,0.35,1).normalized())
				sheet.add_vertex(v+FALL_SHIFT)
	var curtain := ShaderMaterial.new()
	curtain.shader = preload("res://scripts/falls.gdshader")
	sheet.set_material(curtain)
	S.add(static_art,sheet.commit(),Vector3.ZERO,Vector3.ONE,"")
	for i in 15:
		var n := S.ball(self,FALL_SHIFT+Vector3(-6.9+rng.randf()*2.6,0.22,-5.0+rng.randf()*0.75),Vector3(0.34,0.21,0.32),"e0fff4",9)
		spray.append(n)
	for i in 17:
		var a := rng.randf()*TAU
		rock(Vector3(POND.x+4.25*sin(a),0.04,POND.y+3.15*cos(a)),rng.randf_range(0.23,0.52))
	for i in 10:
		var p := Vector3(POND.x+rng.randf_range(-2.5,2.5),0.06,POND.y+rng.randf_range(0.6,2.05))
		S.ball(static_art,p,Vector3(0.29,0.035,0.21),"65ae76",9)
		if i%3==0:
			flower(p,0.55,"ffabaf")

const PORCH := Vector3(4.25,0,-4.10)

func cottage() -> void:
	var h := S.group(static_art,Vector3(5.4,0,-7.4))
	h.rotation.y = -0.26
	blockers.append(Vector3(5.4,-7.4,2.2))
	S.box(h,Vector3(0,0.16,0),Vector3(4.25,0.33,3.45),"aa805c")
	for i in 9:
		S.box(h,Vector3(0,0.41+i*0.25,0),Vector3(3.85,0.245,3.12),["e5ac69","e7b675","de9d61"][i%3])
	for x in [-1.89,1.89]:
		S.box(h,Vector3(x,1.40,1.59),Vector3(0.22,2.47,0.22),"996844")
	for side in [-1,1]:
		var roof := S.box(h,Vector3(side*1.14,3.15,0),Vector3(2.91,0.23,3.92),"a44d39")
		roof.rotation.z = -side*0.57
		for j in 5:
			for i in 8:
				var x: float = side*(0.22+j*0.49)
				var tile := S.box(h,Vector3(x,4.02-abs(x)*0.64,-1.82+i*0.52),Vector3(0.65,0.15,0.505),["d86d42","ed8851","e57b49","e98451"][(i*7+j*3)%4])
				tile.rotation.z = -side*0.57
	for i in 6:
		var width := 3.68-i*0.6
		S.box(h,Vector3(0,2.62+i*0.19,1.53),Vector3(width,0.19,0.24),"f4ce87")
	S.box(h,Vector3(-0.40,1.12,1.59),Vector3(1.1,1.96,0.14),"9b6344")
	S.box(h,Vector3(-0.40,1.10,1.69),Vector3(0.90,1.75,0.11),"338d83")
	S.ball(h,Vector3(-0.1,1.13,1.78),Vector3.ONE*0.078,"ffd55d")
	for x in [-1.36,0.99]:
		S.box(h,Vector3(x,1.58,1.63),Vector3(0.8,0.88,0.16),"fff0bb")
		S.box(h,Vector3(x,1.59,1.74),Vector3(0.61,0.67,0.08),"428c95")
		S.box(h,Vector3(x,1.59,1.80),Vector3(0.065,0.68,0.06),"f6ddb0")
		S.box(h,Vector3(x,1.58,1.80),Vector3(0.64,0.065,0.06),"f6ddb0")
	S.box(h,Vector3(-0.4,0.12,2.01),Vector3(1.45,0.24,0.78),"cc9f68")
	for x in [2.5,3.65,4.8]:
		S.tube(h,Vector3(x,0,0.95),Vector3(x,0.97,0.95),0.13,0.105,"b77f51")
	for y in [0.37,0.72]:
		S.box(h,Vector3(3.65,y,0.95),Vector3(2.35,0.12,0.11),"d59d66")

	# Shutters, a round loft vent and a porch awning give the cottage a readable front.
	for x in [-1.36,0.99]:
		for side in [-1,1]:
			S.box(h,Vector3(x+side*0.47,1.60,1.67),Vector3(0.15,0.83,0.10),"559b8c")
		S.box(h,Vector3(x,1.10,1.79),Vector3(0.96,0.13,0.28),"a76d49")
	S.ball(h,Vector3(0,3.01,1.71),Vector3(0.31,0.31,0.06),"a37452",18)
	S.ball(h,Vector3(0,3.01,1.77),Vector3(0.215,0.215,0.04),"4f9292",18)
	var awning := S.box(h,Vector3(-0.38,2.20,1.99),Vector3(1.54,0.13,0.85),"b55c40")
	awning.rotation.x = 0.18
	for x in [-1.03,0.27]:
		S.tube(h,Vector3(x,0.14,2.26),Vector3(x,2.12,2.26),0.055,0.06,"ad7851")
	S.box(h,Vector3(1.17,3.81,-0.71),Vector3(0.46,1.22,0.53),"b5846b")
	S.box(h,Vector3(1.17,4.40,-0.71),Vector3(0.55,0.17,0.63),"a06a50")

	# A lit lantern and a doormat mark the family's save spot.
	S.box(h,Vector3(-0.40,0.035,3.12),Vector3(1.35,0.06,0.88),"438f82")
	for x in [-0.95,0.15]:
		S.box(h,Vector3(x,0.072,3.12),Vector3(0.08,0.026,0.83),"f3c97b")
	S.box(h,Vector3(0.39,1.82,1.86),Vector3(0.24,0.33,0.21),"ffdb86")
	for y in [1.62,2.01]:
		S.box(h,Vector3(0.39,y,1.86),Vector3(0.31,0.08,0.27),"765943")

func rock(pos: Vector3, size: float) -> void:
	var n := S.ball(static_art,pos,Vector3(size*1.32,size*0.76,size),["a0aea0","adad99","91a79f"][rng.randi()%3],7)
	n.rotation.y = rng.randf()*TAU

func palm(at: Vector3, h: float) -> void:
	var p := S.group(static_art,at)
	p.rotation.y = rng.randf()*TAU
	var prev := Vector3.ZERO
	for i in 8:
		var t := (i+1)/8.0
		var tip := Vector3(h*0.15*t*t,h*t,0)
		S.tube(p,prev,tip,h*(0.054-0.023*i/8.0),h*(0.050-0.023*t),["ad8357","c29a64"][i%2],9)
		prev = tip
	for i in 11:
		var leaf := S.group(p,prev)
		leaf.rotation.y = TAU*i/11+rng.randf_range(-0.13,0.13)
		var length := h*rng.randf_range(0.46,0.68)
		var rings := []
		for j in 9:
			var t := j/8.0
			var mid := Vector3(0,length*(0.5*sin(t*PI)-0.26*t)+(i%2)*0.55*t,length*t)
			var w := length*(0.015+0.15*pow(sin(PI*t),0.70))*(0.67 if j%2==1 else 1.0)
			rings.append([mid+Vector3(-w,-w*0.33,0),mid+Vector3(0,w*0.24,0),mid+Vector3(w,-w*0.52,0)])
		S.bands(leaf,rings,Array(["4ea758","60bc5e","58b25b","72c864","64bd5e","7cca65","83cd69","85ca64"]) if i%2 else Array(["20845a","2e975b","369e5d","43a958","49af5e","57b35e","61ba60","62bd60"]))
	for i in 3:
		S.ball(p,prev+Vector3(0.22*cos(i*2),-0.17,0.22*sin(i*2)),Vector3.ONE*h*0.056,"8c7541")
	if at.y<1:
		blockers.append(Vector3(at.x,at.z,h*0.057))

func flower(at: Vector3, size: float, color: String) -> void:
	var top := at+Vector3.UP*size*0.48
	S.tube(static_art,at,top,0.029*size,0.023*size,"4e9955",5)
	for i in 5:
		var a := TAU*i/5
		var petal := S.ball(static_art,top+Vector3(sin(a),0,cos(a))*size*0.105,Vector3(0.093,0.07,0.135)*size,color,8)
		petal.rotation.y = a
	S.ball(static_art,top+Vector3.UP*0.05*size,Vector3.ONE*0.083*size,"ffcc4c",8)

func plant_island() -> void:
	for spec in [[-10,0,-1,6.4],[-9,0,4.6,5.7],[-12,0,-3.4,4.3],[9,0,0.4,5.8],[10.8,0,-3.3,6.4],[1.7,0,-9.5,4.2],[-38.9,3.1,-17.4,3.1],[9,0,5.7,4.9],[-7,0,8.3,4.4],[5.9,0,12.5,4.7]]:
		palm(Vector3(spec[0],spec[1],spec[2]),spec[3])
	# Broadleaf shrubs soften the ledges and cluster along the outer coast.
	for spec in [[-39.4,3.1,-16.8],[-36.1,4.3,-17.6],[-35.5,2.8,-17.3],[-3.5,0,-6.4],[-9.3,0,-4.9],[-10,0,1.3],[8.3,0,-5.3],[8.8,0,-2.2],[6.9,0,6.8],[-7.8,0,5.9],[0.5,0,-9.4]]:
		var base := Vector3(spec[0],spec[1],spec[2])
		for j in 8:
			var a := j*2.4
			var rad := rng.randf_range(0.32,0.65)
			var leaf := S.ball(static_art,base+Vector3(sin(a)*rad,rad*0.57,cos(a)*rad),Vector3(rad*0.66,rad*1.24,rad*0.59),["389566","66ab5a","8dbe5c"][j%3],8)
			leaf.rotation.z = -sin(a)*0.6
			leaf.rotation.x = cos(a)*0.6

	for i in 240:
		var x := rng.randf_range(-14,14)
		var z := rng.randf_range(-11.8,11.8)
		if Vector2(x/14,z/11.7).length()>0.99 or wet(Vector2(x,z)) or absf(x-path_x(z))<1.15 or Vector2(x-5.4,z+7.4).length()<2.75:
			continue
		var p := Vector3(x,0.035,z)
		var kind := rng.randf()
		if kind<0.12 and absf(x)>5:
			rock(p,rng.randf_range(0.35,0.82))
		elif kind<0.50:
			var c: String = ["fff1c2","ff9780","fed14d","dfa2f7"][rng.randi()%4]
			for j in rng.randi_range(3,7):
				flower(p+Vector3(rng.randf_range(-0.4,0.4),0,rng.randf_range(-0.4,0.4)),rng.randf_range(0.52,1.0),c)
		else:
			for j in 5:
				var a := j*2.4
				var b := p+Vector3(cos(a),0,sin(a))*0.15
				S.tube(static_art,b,b+Vector3(cos(a)*0.19,rng.randf_range(0.19,0.48),sin(a)*0.19),0.079,0.003,["69af51","a3d65b","68b455"][j%3],4)

func wet(p: Vector2) -> bool:
	return ((p-POND)/Vector2(4.3,3.18)).length()<1

func accessible(p: Vector3, margin := 0.0) -> bool:
	if (Vector2(p.x,p.z)/(SHORE-Vector2.ONE*margin)).length()>0.99 or ((Vector2(p.x,p.z)-POND)/(Vector2(4.3,3.18)+Vector2.ONE*margin)).length()<1:
		return false
	for block in blockers:
		if Vector2(p.x-block.x,p.z-block.y).length()<block.z+0.24+margin:
			return false
	return true

func animate(t: float) -> void:
	for i in spray.size():
		spray[i].position.y = 0.16+0.12*sin(t*4+i)
		spray[i].scale.y = 0.24+0.12*cos(t*4+i)

# Instance repeated details together so flower fields cost only a few draw calls.
func batch_scenery() -> void:
	var groups := {}
	for n: MeshInstance3D in static_art.find_children("*","MeshInstance3D",true,false):
		if n.material_override == null or not n.mesh is PrimitiveMesh:
			continue
		var key := Vector2i(n.mesh.get_instance_id(),n.material_override.get_instance_id())
		if not groups.has(key):
			groups[key] = []
		groups[key].append(n)
	for nodes: Array in groups.values():
		if nodes.size()<3:
			continue
		var batch := MultiMeshInstance3D.new()
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = nodes[0].mesh
		mesh.instance_count = nodes.size()
		batch.multimesh = mesh
		batch.material_override = nodes[0].material_override
		add_child(batch)
		for i in nodes.size():
			mesh.set_instance_transform(i,nodes[i].global_transform)
			nodes[i].free()

func mark_habitat(species: Resource) -> void:
	var patch := S.group(self,species.home)
	var sign_pos := Vector3(1.25,0,-0.65)
	S.tube(patch,sign_pos,sign_pos+Vector3.UP*0.79,0.07,0.055,"9e704d")
	var badge := Sprite3D.new()
	badge.texture = species.portrait
	badge.pixel_size = 0.0046
	badge.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	badge.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	badge.position = sign_pos+Vector3.UP*1.14
	patch.add_child(badge)
	match species.habitat:
		"Watervalplas":
			for i in 13:
				var base := Vector3(sin(i*2.4)*1.4,0,-0.85+0.34*cos(i*2.4))
				var tip := base+Vector3(sin(i)*0.11,0.37+0.19*cos(i),0.06)
				S.tube(patch,base,tip,0.026,0.013,"578c65")
				S.ball(patch,tip,Vector3(0.041,0.105,0.041),"99734c")
		"Lavakloof":
			flat_disc(patch,Vector3(0,0.028,0),1.61,1.12,"aa8069")
			for i in 9:
				var a := i*TAU/9
				var p := Vector3(sin(a)*1.32,0.09,cos(a)*0.92)
				var r := 0.21+0.08*cos(i*3.3)
				S.ball(patch,p,Vector3(r*1.55,r*0.87,r),"6e646a",7)
				S.ball(patch,p+Vector3(0.04,r*0.68,0),Vector3(r*0.65,r*0.26,r*0.62),"f8a85f",7)
		"Zonnekaap":
			for i in 3:
				var p := Vector3(-1.4+i*0.67,0,-0.94)
				var h := 0.64+0.19*i
				S.tube(patch,p,p+Vector3.UP*h,0.035,0.026,"608a59")
				for j in 8:
					var a := j*TAU/8
					S.ball(patch,p+Vector3(0.14*sin(a),h+0.14*cos(a),0),Vector3(0.095,0.10,0.05),"ffcf43")
				S.ball(patch,p+Vector3(0,h,0.036),Vector3(0.115,0.115,0.055),"936336")
		"Vlindertuin":
			for i in 42:
				var a := i*0.32
				var r := 0.22+i*0.036
				flower(species.home+Vector3(sin(a)*r,0.02,cos(a)*r),0.68+0.18*sin(i),["bc98ed","8ec8fc","f4c6ed"][i%3])
		"Vuurweide":
			for i in 3:
				var p := Vector3(-1.5-i*0.23,0.25,-0.67+sin(i)*0.32)
				S.ball(patch,p,Vector3(0.43,0.32,0.37),"66aa68",10)
				for j in 4:
					S.ball(patch,p+Vector3(0.31*sin(j*2.4),0.14,0.25*cos(j*2.4)),Vector3.ONE*0.08,"ed8260")

func create_regions(species_list: Array) -> void:
	for species in species_list:
		var origin: Vector3 = species.home
		var ground: String = {"Vuurweide":"a5c35c","Watervalplas":"a8d29a","Lavakloof":"a78980","Zonnekaap":"d9cf79","Vlindertuin":"a6c79b"}[species.habitat]
		var center := origin+Vector3(0,0,1.5)
		# Leave the pond above the meadow and the paths above both ground layers.
		flat_disc(static_art,center+Vector3.UP*0.008,12.5,9.8,ground,0.075)
		if origin.length()>10:
			var gate := origin.normalized()*9.4
			trail_to(gate,origin)
			waymark(gate,species)
		mark_habitat(species)
		for i in 15:
			var a := TAU*i/15
			var p := center+Vector3(11.8*sin(a),0,8.7*cos(a))
			match species.habitat:
				"Vuurweide":
					if i>0 and i%3==0:
						grove_tree(p,"c16a46","efa65a")
				"Watervalplas":
					if i%3==0 and not wet(Vector2(p.x,p.z)):
						palm(p,5.6+sin(a))
					else:
						rock(p,0.55)
				"Lavakloof":
					var h := 1.3+2.4*absf(sin(i*2.4))
					var r := 0.8+0.4*cos(i)
					formation(static_art,p,[Vector3(r,0,r),Vector3(r*0.87,h*0.8,r*0.85),Vector3(r*0.73,h,r*0.72),Vector3(0.01,h,0.01)],["68596c","876578","b17e72"],6,a,0.09)
					blockers.append(Vector3(p.x,p.z,r))
					S.tube(static_art,p+Vector3(0.7,0,0.4),p+Vector3(0.9,h*0.45,0.5),0.22,0.02,"ffb85d",5)
				"Zonnekaap":
					if i%4==0:
						windmill(p)
					for j in 7:
						flower(p+Vector3(sin(j*2.4)*1.3,0,cos(j*2.4)),1.1,"ffd345")
				"Vlindertuin":
					if i%3==0:
						grove_tree(p,"b295cd","efb8d7")
					for j in 9:
						flower(p+Vector3(sin(j*2.4)*1.5,0,cos(j*2.4)*1.4),0.92,["cd99df","fbc2db","96bffc"][j%3])
		for j in 26:
			var a := j*2.39996
			var r := 2.4+sqrt(j/25.0)*7.3
			var p := center+Vector3(cos(a)*r,0.012,sin(a)*r*0.78)
			if wet(Vector2(p.x,p.z)):
				continue
			match species.habitat:
				"Lavakloof":
					flat_disc(static_art,p,1.2+0.4*sin(a),0.55,"897378",0.12)
					var seam := flat_disc(static_art,p+Vector3.UP*0.004,0.86,0.075,"efaa62")
					seam.rotation.y = a
				"Vlindertuin":
					for k in 7:
						var t := k*0.8
						flower(p+Vector3(sin(t),0,cos(t))*0.12*k,0.78+0.16*cos(a+t),["e6abe2","abb9f4","ffe0e2"][j%3])
				"Watervalplas":
					for k in 4:
						var tip := p+Vector3(cos(k*2.4)*0.31,0.54+0.19*sin(a+k),sin(k*2.4)*0.31)
						S.tube(static_art,p,tip,0.11,0.006,"65aa79",5)
				"Zonnekaap":
					for k in 5:
						var stalk := p+Vector3(sin(k*2.4)*0.4,0,cos(k*2.4)*0.4)
						var tip := stalk+Vector3(0.16,0.5+0.1*cos(k+a),0.05)
						S.tube(static_art,stalk,tip,0.023,0.013,"a5aa55",5)
						S.ball(static_art,tip,Vector3(0.058,0.14,0.061),"f3be5f",7)
				"Vuurweide":
					if j%3==0:
						S.ball(static_art,p,Vector3(0.60,0.28,0.41),"80ab61",9)
						for k in 4:
							S.ball(static_art,p+Vector3(cos(k)*0.37,0.23,sin(k)*0.26),Vector3.ONE*0.09,"ef8a5e")
	# Coastal planting also gives the walks between habitats a visible shoreline.
	for i in 48:
		var a := TAU*i/48
		var p := Vector3(53*sin(a),0,43*cos(a))
		if i%4==0:
			palm(p,rng.randf_range(5.0,7.0))
		else:
			rock(p,1.1+0.8*sin(i))
	for i in 540:
		var p := Vector3(rng.randf_range(-55,55),0,rng.randf_range(-45,45))
		if not accessible(p) or p.length()<12:
			continue
		if i%9==0:
			rock(p,rng.randf_range(0.35,0.68))
		else:
			for j in 3:
				flower(p+Vector3(0.33*cos(j*2.4),0,0.38*sin(j*2.4)),0.64,"fff0be")
	batch_scenery()

func trail_to(start: Vector3, end: Vector3) -> void:
	var side := (end-start).normalized().cross(Vector3.UP)
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous := start
	for i in range(1,33):
		var t := i/32.0
		var p := start.lerp(end,t)+side*sin(t*TAU)*1.5
		for v in [previous-side,previous+side,p-side,previous+side,p+side,p-side]:
			mesh.set_normal(Vector3.UP)
			mesh.add_vertex(v+Vector3.UP*0.045)
		previous = p
	var sand := S.mat("edcf8c").duplicate() as StandardMaterial3D
	sand.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_material(sand)
	S.add(static_art,mesh.commit(),Vector3.ZERO,Vector3.ONE,"")

func waymark(p: Vector3, species: Resource) -> void:
	var post := S.group(static_art,p+Vector3.UP*0.15)
	S.tube(post,Vector3.ZERO,Vector3.UP*1.75,0.09,0.07,"ad8056")
	var sign_icon := Sprite3D.new()
	sign_icon.texture = species.portrait
	sign_icon.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign_icon.pixel_size = 0.006
	sign_icon.position.y = 1.88
	post.add_child(sign_icon)
	var label := Label3D.new()
	label.text = species.habitat
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.font_size = 39
	label.pixel_size = 0.008
	label.outline_size = 9
	label.position.y = 1.17
	post.add_child(label)

func grove_tree(at: Vector3, shade: String, light: String) -> void:
	var h := rng.randf_range(3.0,4.8)
	S.tube(static_art,at,at+Vector3.UP*h,0.28,0.16,"947153",8)
	blockers.append(Vector3(at.x,at.z,0.34))
	for j in 6:
		var p := at+Vector3(sin(j*2.4)*1.05,h+0.6*cos(j),cos(j*2.4)*0.85)
		S.ball(static_art,p,Vector3(1.48,1.18,1.42),shade if j%3==0 else light,9)

func windmill(at: Vector3) -> void:
	S.tube(static_art,at,at+Vector3.UP*3.5,0.22,0.12,"a78459")
	var hub := at+Vector3(0,3.35,0.16)
	for j in 4:
		var a := j*PI/2+0.28
		var blade := S.box(static_art,hub+Vector3(sin(a),cos(a),0)*0.68,Vector3(0.30,1.1,0.10),"fff0ac")
		blade.rotation.z = -a
	S.ball(static_art,hub+Vector3(0,0,0.1),Vector3.ONE*0.23,"e6ab43")
	blockers.append(Vector3(at.x,at.z,0.26))

# A broad grassy slope and a flat summit. The mesh and walkers use the same profile.
const SUMMIT := Vector2(47,32)
func height_at(p: Vector3) -> float:
	return 6.0*clampf((18.0-SUMMIT.distance_to(Vector2(p.x,p.z)))/13.0,0.0,1.0)

func star_hill() -> void:
	var rings := []
	for radius: float in [18.0,15.0,12.0,9.0,5.0,0.01]:
		var h := 6.0*clampf((18-radius)/13.0,0.0,1.0)
		rings.append(S.ring(Vector2.ONE*radius,h+0.018,64))
	var hill := S.bands(static_art,rings,["88b866","87bb6c","90bf70","a2c974","b4ce82"],0.025)
	hill.position = Vector3(SUMMIT.x,0,SUMMIT.y)
	for i in 56:
		var t := i/55.0
		var p := Vector3(lerpf(8,47,t),0,lerpf(11,32,t)+sin(t*9)*1.4)
		p.y = height_at(p)+0.06
		S.ball(static_art,p,Vector3(0.40,0.075,0.25),"dfcc92",8)
	for i in 44:
		var angle := i*2.399
		var radius := 5.2+fmod(i*3.31,12.0)
		var p := Vector3(SUMMIT.x+cos(angle)*radius,0,SUMMIT.y+sin(angle)*radius)
		p.y = height_at(p)+0.06
		flower(p,0.9,["fbd78c","dbc6ef","f5e8ad"][i%3])
	for i in 32:
		var a := TAU*i/32
		var p := Vector3(69*sin(a),0,54*cos(a))
		p.y = height_at(p)
		if i%4==0:
			palm(p,5.4)
		else:
			rock(p,0.8+0.4*sin(a))
