extends RefCounted
const S = preload("res://scripts/shapes.gd")
const Kind = preload("res://scripts/species.gd")
const Book = preload("res://scripts/questions.gd")
const CENTER := Vector3(170,0,0)
const RADII := Vector2(53,43)
const PORTS := [Vector3(89,0,0),CENTER+Vector3(-53,0,-8)]
# Each ferry stop links to its opposite stop. Islands may have several routes.
const PORT_ISLAND := [0,1]
const CONNECTION := [1,0]
const INWARD := [Vector3.LEFT,Vector3.RIGHT]
const ISLAND_NAMES := ["Vareneiland","Emberflame Island"]
const REGIONS := ["Emberwood Forest","Fire Ridge","Ignis Grotto","Sunflame Shores","Flarefell Marsh"]
const HOMES := [Vector3(-24,0,-13),Vector3(7,0,-24),Vector3(32,0,-1),Vector3(-27,0,20),Vector3(13,0,24)]
# Body, trim and highlight colors from each turnaround sheet, normal then shiny.
const PALETTES := [
	[["79ac22","b5df26","ffe767"],["ac359c","ff8db6","e6a8ff"]],
	[["edac23","b87a16","fff69a"],["9536d3","cf56e4","ffb2ff"]],
	[["4f9934","daa537","dbff65"],["2772bd","b2c5d9","8df4ff"]],
	[["fff3dc","d6a02c","ffe8a7"],["83b3ed","4667a9","dcecff"]],
	[["fff0bd","e6aa36","ffda69"],["b3f5f0","3eb9c7","dbfaff"]],
]
const COLORS := ["77ae4b","ac7060","82739d","f0cf88","789d90"]
const OFFSETS := [Vector3(-4,0,1),Vector3(2,0,-3),Vector3(5,0,2),Vector3(-1,0,5)]
const PEAKS := [Vector3(21,0,-32),Vector3(36,-0.7,-23)]
const PEAK_SIZES := [1.0,0.64]
var eruption_seen := false
var eruption_armed := true
var crater_sparks: CPUParticles3D
var vent_sparks: CPUParticles3D
var ash: CPUParticles3D
const SITES := [Vector3(-30,0,-18),Vector3(36,0,-4),Vector3(-34,0,21),Vector3(16,0,30)]
const SITE_NAMES := ["Windklokken","Kristalgrot","Lichtbaken","Lotusbron"]
const SITE_ACTIONS := ["Speel de windklokken","Raak het kristal aan","Ontsteek het baken","Open de lotusbloem"]
var discovered: Array = []
var ornaments: Array[Node3D] = []
var details: Node3D
var pages: Array = []

static func on_ember(p: Vector3) -> bool:
	return p.x>CENTER.x*0.62

static func nearby_port(p: Vector3, island: int) -> int:
	for i in PORTS.size():
		if PORT_ISLAND[i]==island and p.distance_to(PORTS[i])<2.6:
			return i
	return -1

static func on_ramp(p: Vector3, margin: float) -> bool:
	for i in PORTS.size():
		var d: Vector3 = p-PORTS[i]
		var inward := d.dot(INWARD[i])
		if inward>=-1+margin and inward<=(18 if i==0 else 12) and absf(d.z)<1.25-margin:
			return true
	return false

func residents() -> Array:
	var kinds := []
	for i in REGIONS.size():
		var entry: Dictionary = Book.bank[REGIONS[i]]
		for j in OFFSETS.size():
			var kind := Kind.new()
			kind.display_name = entry.soort
			kind.cloak = PackedStringArray(PALETTES[i][int(j==3)])
			kind.shiny_name = kind.display_name
			kind.habitat = REGIONS[i]
			kind.question_group = kind.habitat
			kind.theme = entry.thema
			kind.food = "gloeibes"
			kind.home = CENTER+HOMES[i]+OFFSETS[j]
			kind.model = preload("res://creatures/models/ember_resident.gd")
			kind.portrait = load("res://creatures/portraits/emberflame/%s.png" % (kind.display_name+("_shiny" if j==3 else "")))
			kind.hover_height = 0.95
			kinds.append(kind)
			if j==0:
				pages.append(kind)
	return kinds

func build(land) -> void:
	var coast := S.group(land,CENTER)
	details = S.group(land)
	land.formation(coast,Vector3.ZERO,[Vector3(56,-2,46),Vector3(54,-0.46,44),Vector3(53,0,43),Vector3(0.01,0,0.01)],["745450","edb772","91b56b"],64,0.6,0.027)
	landscape_edges(land,coast)
	for i in REGIONS.size():
		if i in [1,2]:
			var rings := []
			for r: float in [1.0,0.78,0.52,0.3,0.001]:
				rings.append(S.ring(Vector2(16,13)*r,0.024+hill_profile(r,i),64))
			var hill := S.bands(coast,rings,["8d7760",COLORS[i],COLORS[i],COLORS[i]],0.025)
			hill.position = HOMES[i]
		else:
			land.flat_disc(coast,HOMES[i]+Vector3.UP*0.02,14,10,COLORS[i])
		land.trail_to(CENTER+HOMES[i],CENTER)
		decorate_region(land,i)
	land.trail_to(PORTS[1]+Vector3.RIGHT*7,CENTER+HOMES[0])
	# A coastal loop crosses Emberfall bridge and approaches the marsh shrine from the west.
	var bridge := CENTER+Vector3(-8,0,18)
	land.trail_to(CENTER+HOMES[3],bridge+Vector3.LEFT*2.6)
	land.trail_to(bridge+Vector3.RIGHT*2.6,CENTER+SITES[3])
	land.trail_to(CENTER+SITES[3],CENTER+HOMES[4])
	for i in PEAKS.size():
		volcano(land,coast,PEAKS[i],PEAK_SIZES[i])
	crater_sparks = plume(details,"ffad38",100,0.48,16,Vector3.DOWN*7)
	ash = plume(details,"927b78",45,1.1,5,Vector3(0.5,0.3,0))
	vent_sparks = plume(details,"ffc75c",36,0.14,4.5,Vector3.DOWN*4)
	# The great tree and beacon stay visible across the water.
	var tree: Vector3 = HOMES[0]+Vector3(2,0,-7)
	S.tube(coast,tree,tree+Vector3.UP*6,1.3,0.8,"81583a")
	for j in 8:
		var a := j*2.4
		S.ball(coast,tree+Vector3(sin(a)*2.8,6.4+cos(j)*0.8,cos(a)*2.7),Vector3(3.2,2.1,3.0),["45884d","77ad47","99bf49"][j%3],9)
	land.blockers.append(Vector3(CENTER.x+tree.x,tree.z,1.25))
	for j in 12:
		var a := j*2.4
		var p: Vector3 = CENTER+HOMES[0]+Vector3(sin(a)*11,0,cos(a)*8)
		land.grove_tree(p,"598749","92af4e" if j%3 else "d38245")
	var beacon := Vector3(-34,0,23)
	S.tube(coast,beacon,beacon+Vector3.UP*5,0.85,0.55,"fff0ce")
	S.tube(coast,beacon+Vector3.UP*3,beacon+Vector3.UP*3.8,0.70,0.66,"d87747")
	S.ball(coast,beacon+Vector3.UP*5.4,Vector3(0.72,0.74,0.72),"ffd678",8)
	S.tube(coast,beacon+Vector3.UP*6,beacon+Vector3.UP*6.8,0.93,0.02,"a55243")
	land.blockers.append(Vector3(CENTER.x+beacon.x,beacon.z,0.85))
	for j in 5:
		land.palm(CENTER+Vector3(-32+j*3.2,0,12+sin(j)*3),4+cos(j))
	var cave: Vector3 = CENTER+HOMES[2]+Vector3(4,0,-4)
	cave.y = elevation(cave)
	for j in 9:
		var a := PI*j/8
		var stone := cave+Vector3(cos(a)*4,sin(a)*3.7,0)
		S.ball(details,stone,Vector3(1.35,1.45,1.9),"575170",7)
	for j in 18:
		var base := cave+Vector3(cos(j*2.4)*(3.7+sin(j)),0,sin(j*2.4)*3)
		var tip := base+Vector3(sin(j)*0.5,1.2+0.8*cos(j),0)
		S.tube(details,base,tip,0.31,0.02,["68ddec","b490ee","e3b5fe"][j%3],5)
	for j in 7:
		var p: Vector3 = CENTER+HOMES[4]+Vector3(sin(j*2.4)*9,0.03,cos(j*2.4)*8)
		land.flat_disc(details,p,2.7,1.7,"649daa")
		for k in 5:
			S.ball(details,p+Vector3(sin(k*1.26)*0.4,0.19,cos(k*1.26)*0.4),Vector3(0.32,0.26,0.32),"eaa1cf",7)
	var falls := CENTER+Vector3(-4,0,6)
	S.ball(details,falls,Vector3(3.1,3.5,2.6),"8e8b72",8)
	land.blockers.append(Vector3(falls.x,falls.z,2.7))
	for j in 5:
		var x := (j-2)*0.38
		S.tube(details,falls+Vector3(x,3.1,1.2),falls+Vector3(x,0.15,2.8),0.26,0.32,"a9ede5" if j%2 else "76cfd9",6)
	land.flat_disc(details,falls+Vector3(0,0.04,3),3.1,1.6,"77ced3")
	for x in [-1.9,1.9]:
		S.box(details,CENTER+Vector3(x,1.65,-9),Vector3(1.1,3.3,1.2),"a6936d")
	S.box(details,CENTER+Vector3(0,3.6,-9),Vector3(5.5,0.8,1.6),"bac08a")
	build_discoveries()
	for i in PORTS.size():
		dock(land,PORTS[i],1 if i==0 else -1)

static func hill_profile(radius: float, region: int) -> float:
	return (5.6 if region==1 else 3.8)*clampf((1-radius)/0.70,0,1)

static func elevation(world: Vector3) -> float:
	var local := world-CENTER
	var h := 0.0
	for i in [1,2]:
		var d: Vector3 = local-HOMES[i]
		h = maxf(h,hill_profile(Vector2(d.x/16,d.z/13).length(),i))
	return h

func build_discoveries() -> void:
	for i in SITES.size():
		var site: Vector3 = CENTER+SITES[i]
		site.y = elevation(site)
		var host := S.group(details,site)
		var moving := S.group(host)
		ornaments.append(moving)
		match i:
			0:
				for x in [-1.0,1.0]:
					S.tube(host,Vector3(x,0,0),Vector3(x,2.8,0),0.09,0.08,"906c47")
				S.box(host,Vector3(0,2.8,0),Vector3(2.4,0.16,0.19),"906c47")
				moving.position.y = 2.72
				for j in 5:
					var x := (j-2)*0.30
					S.tube(moving,Vector3(x,0,0),Vector3(x,-0.45,0),0.02,0.02,"796951")
					S.tube(moving,Vector3(x,-0.45,0),Vector3(x,-0.95-j*0.12,0),0.08,0.08,"e0b766")
			1:
				moving.position.y = 0.8
				S.tube(moving,Vector3.DOWN*0.65,Vector3.ZERO,0.06,0.46,"8193dc",6)
				S.tube(moving,Vector3.ZERO,Vector3.UP*0.9,0.46,0.012,"a9e7ef",6)
			2:
				# The rotating light sits in the existing lighthouse behind the landing.
				moving.position = Vector3(0,5.4,2)
				for side in [-1,1]:
					S.tube(moving,Vector3(side*0.63,0,0),Vector3(side*3.5,0,0),0.10,0.28,"ffe6a2",8)
			3:
				for j in 8:
					var a := j*TAU/8
					var petal := S.ball(moving,Vector3(0.51*sin(a),0.35,0.51*cos(a)),Vector3(0.32,0.60,0.25),"ea9fc8",9)
					petal.rotation = Vector3(0.55,a,0)
				S.ball(moving,Vector3(0,0.38,0),Vector3.ONE*0.27,"ffcf62",9)
		if i==2:
			moving.hide()

func nearby_site(foot: Vector3) -> int:
	for i in SITES.size():
		if foot.distance_to(CENTER+SITES[i])<2.4:
			return i
	return -1

func explore(i: int) -> void:
	if SITE_NAMES[i] not in discovered:
		discovered.append(SITE_NAMES[i])
	ornaments[i].show()

func animate_sites(time: float) -> void:
	for i in SITES.size():
		if SITE_NAMES[i] not in discovered:
			continue
		var art := ornaments[i]
		match i:
			0: art.rotation.z = sin(time*3)*0.16
			1:
				art.rotation.y = time
				art.position.y = 1.1+sin(time*2)*0.22
			2: art.rotation.y = time*0.9
			3: art.scale = Vector3(1.45,0.64+0.05*sin(time*2),1.45)

func landscape_edges(land, coast: Node3D) -> void:
	# Break up the rim with basalt columns, sandy coves and pockets of trees.
	for j in 86:
		var a := TAU*j/86
		var p := Vector3(51*cos(a),0,41*sin(a))
		if p.distance_to(PORTS[1]-CENTER)<7:
			continue
		if p.x<0 and p.z>4:
			if j%4==0:
				land.palm(CENTER+p*0.89,3.8+sin(j)*0.9)
			continue
		var h := 1.1+0.65*cos(j*2.2)+0.55*sin(j)
		if p.x>2 and p.z<0:
			h += 1.8
		var rock := S.ball(coast,p,Vector3(2.3+sin(j),h,2.1),["926e61","ae8a70","877462"][j%3],7)
		rock.rotation.y = a
		land.blockers.append(Vector3(CENTER.x+p.x,p.z,1.7))
		if j%3==0 and (p.z>0 or p.x<0):
			land.grove_tree(CENTER+p*0.91,"527f55","89a254" if j%2 else "cc8952")
	for j in 16:
		var a := j*2.4
		var p := HOMES[0]+Vector3(-2+cos(a)*14,0,-9+sin(a)*7)
		if OFFSETS.any(func(offset): return p.distance_to(HOMES[0]+offset)<2.2):
			continue
		if j%4==0:
			land.grove_tree(CENTER+p,"935b41","d89049")
		else:
			land.grove_tree(CENTER+p,"46794d","73a258")
	# A stream below Emberfall empties onto the southern beach.
	for j in 19:
		var p := CENTER+Vector3(-4-j*0.92+sin(j*0.61)*1.1,0.033,10+j*1.62)
		land.flat_disc(details,p,1.75,2.0,"78c8c7",0.09)
	var bridge := S.group(details,CENTER+Vector3(-8,0.09,18))
	for j in 13:
		S.box(bridge,Vector3((j-6)*0.41,0,0),Vector3(0.39,0.15,1.9),"ba915e")
	for z in [-1,1]:
		for x in [-2.5,2.5]:
			S.tube(bridge,Vector3(x,0,z),Vector3(x,1,z),0.085,0.07,"806445")
		S.tube(bridge,Vector3(-2.5,0.9,z),Vector3(0,0.60,z),0.045,0.045,"9d7952")
		S.tube(bridge,Vector3(0,0.60,z),Vector3(2.5,0.9,z),0.045,0.045,"9d7952")
	var shrine := S.group(details,CENTER+Vector3(16,0,32))
	for x in [-1.4,1.4]:
		S.tube(shrine,Vector3(x,0,0),Vector3(x,3.3,0),0.19,0.17,"ac5042")
	S.box(shrine,Vector3(0,2.55,0),Vector3(3.8,0.26,0.38),"be6852")
	S.box(shrine,Vector3(0,3.35,0),Vector3(4.5,0.3,0.6),"704d52")
	for j in 3:
		var p := CENTER+Vector3(3+j*2.3,0,-10.5)
		S.tube(details,p,p+Vector3.UP*(1.1+j*0.4),0.54,0.49,"a28d70",7)

func decorate_region(land, region: int) -> void:
	var center: Vector3 = CENTER+HOMES[region]
	for j in 32:
		var a := j*2.39996
		var p := center+Vector3(cos(a)*(7+fmod(j*2.1,6.0)),0.06,sin(a)*(6+fmod(j*1.2,3.5)))
		p.y += elevation(p)
		match region:
			0:
				land.flower(p,0.6,["f2bd5c","ec8760","fbedad"][j%3])
			1:
				S.ball(details,p,Vector3(0.6,0.45,0.55)*(0.7+0.4*cos(j)),"715659",7)
				if j%3==0:
					S.tube(details,p,p+Vector3(0.24,0.7,0),0.17,0.02,"ffae44",5)
			2:
				S.tube(details,p,p+Vector3(0.21,0.7+0.4*sin(j),0),0.23,0.02,["9891db","72bacb","b98bcd"][j%3],5)
			3:
				S.ball(details,p,Vector3(0.34,0.15,0.29),["eec2a0","f9e5bd","c39d7c"][j%3],7)
			4:
				for k in 3:
					S.tube(details,p,p+Vector3(0.18*cos(k*2.1),0.7+0.25*sin(j+k),0.18*sin(k*2.1)),0.047,0.015,"698956",5)

func volcano(land, coast: Node3D, p: Vector3, size: float) -> void:
	var cone: Node3D = land.formation(coast,p,[Vector3(10,0,7),Vector3(7,3,5),Vector3(4,6.5,3),Vector3(2,10,1.6),Vector3(1.2,9.7,0.9),Vector3(0.01,9.7,0.01)],["674950","78535a","975e50","ff9c39","ffcf55"],14,0.4,0.12)
	cone.scale = Vector3(1,2.1,1)*size
	for j in 4:
		var puff := 0.55+j*0.28
		S.ball(cone,Vector3(j*j*0.19,10.8+j*0.98,0),Vector3(puff,puff*0.78,puff),"c7a99a",8)
	for j in 3:
		var a := j*1.9
		var prev := Vector3(sin(a)*2,9.9,cos(a)*1.6)
		for k in range(1,7):
			var next := Vector3(sin(a+0.09*sin(k))*(2+k*1.3),10-k*1.62,cos(a+0.09*sin(k))*(1.6+k*0.90))
			S.tube(cone,prev,next,0.16,0.14,"ff9a31",5)
			prev = next
	land.blockers.append(Vector3(CENTER.x+p.x,p.z,7.0*size))

func plume(parent: Node3D, color: String, count: int, radius: float, speed: float, gravity: Vector3) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = 3.5
	particles.explosiveness = 0.45
	particles.direction = Vector3.UP
	particles.spread = 33
	particles.initial_velocity_min = speed*0.65
	particles.initial_velocity_max = speed
	particles.gravity = gravity
	particles.scale_amount_min = 0.45
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 7
	mesh.rings = 3
	mesh.material = S.mat(color)
	particles.mesh = mesh
	parent.add_child(particles)
	return particles

# A wider exit radius lets the player explore the foothills without repeatedly firing the vent.
func approach_volcano(foot: Vector3) -> bool:
	var nearest := 0
	var distance := INF
	for i in PEAKS.size():
		var offset: Vector3 = foot-(CENTER+PEAKS[i])
		var from_peak := Vector2(offset.x,offset.z).length()/float(PEAK_SIZES[i])
		if from_peak<distance:
			distance = from_peak
			nearest = i
	if distance>19:
		eruption_armed = true
	if not eruption_armed or distance>13 or crater_sparks.emitting:
		return false
	eruption_armed = false
	var peak: Vector3 = CENTER+PEAKS[nearest]
	crater_sparks.global_position = peak+Vector3.UP*20.8*float(PEAK_SIZES[nearest])
	ash.global_position = crater_sparks.global_position
	var outward := Vector3(foot.x-peak.x,0,foot.z-peak.z).normalized()
	vent_sparks.global_position = Vector3(peak.x,0.25,peak.z)+outward*10.4*float(PEAK_SIZES[nearest])
	for particles: CPUParticles3D in [crater_sparks,ash,vent_sparks]:
		particles.restart()
		particles.emitting = true
	var first_sighting := not eruption_seen
	eruption_seen = true
	return first_sighting

func dock(land, at: Vector3, outward: int) -> void:
	var pier := S.group(land,at)
	if outward<0:
		pier.rotation.y = PI
	for j in (38 if outward>0 else 26):
		S.box(pier,Vector3(0.8-j*0.48,0.015,0),Vector3(0.46,0.14,2.8),["bd925d","cc9f69","b58a58"][j%3])
	for x in [-10,-5,0]:
		for z in [-1.52,1.52]:
			S.tube(pier,Vector3(x,-1.6,z),Vector3(x,0.45,z),0.14,0.13,"826345")
	var boat := S.group(pier,Vector3(0,-0.87,2.9))
	boat.rotation.y = 0.58
	S.bands(boat,[S.ring(Vector2(1.5,0.5),-0.32,10),S.ring(Vector2(2.45,0.91),0.57,10),S.ring(Vector2(2.17,0.69),0.48,10),S.ring(Vector2(0.01,0.01),0.05,10)],["775542","f0c786","986c47"])
	S.tube(boat,Vector3.ZERO,Vector3.UP*4,0.09,0.06,"806342")
	var sail := PrismMesh.new()
	sail.size = Vector3(2.3,2.75,0.08)
	sail.left_to_right = 0.08
	S.add(boat,sail,Vector3(0.9,2.47,0),Vector3.ONE,"f6bb64")
