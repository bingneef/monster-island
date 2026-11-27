extends Node3D
const S = preload("res://scripts/shapes.gd")
const Terrain = preload("res://scripts/landscape.gd")
const Ember = preload("res://scripts/emberflame.gd")
var ember := Ember.new()
var island_id := 0
var start_on_ember := OS.has_feature("editor")
const Explorer = preload("res://scripts/explorer.gd")
const HUD = preload("res://scripts/hud.gd")
const Creature = preload("res://scenes/creature.tscn")
const SPECIES = [
	preload("res://creatures/flamelingo.tres"),
	preload("res://creatures/aquapouch.tres"),
	preload("res://creatures/blazeglyph.tres"),
	preload("res://creatures/cyclovolt.tres"),
	preload("res://creatures/spiralbutterfly.tres"),
]
var sky_book := preload("res://scripts/sky_book.gd").new()
var quiz := preload("res://scripts/quiz.gd").new()
var teamwork := preload("res://scripts/team_adventures.gd").new()
var outings := preload("res://scripts/trail_adventures.gd").new()
var beach := preload("res://scripts/turtle_beach.gd").new()
var wonders := preload("res://scripts/wonders.gd").new()
var finds := preload("res://scripts/discoveries.gd").new()
var pads := preload("res://scripts/pad_controls.gd").new()
const WALK_SPEED := 4.55
const RUN_SPEED := 7.2
var solo_jump_chord := false
var checkpoint := preload("res://scripts/cottage_save.gd").new()
var land := Terrain.new()
var player := Explorer.new()
var creatures: Array[Node3D] = []
# Each pair is (sideways spacing, distance back along the explorer's footsteps).
const FOLLOW_SLOTS := [Vector2(0,1.65),Vector2(-1.72,2.70),Vector2(1.72,2.70),
	Vector2(-0.96,4.44),Vector2(0.96,4.44)]
var trail: Array[Vector3] = []
var walk_heading := Vector3.FORWARD
var lane_sign := 1.0
var reversing := false
var after_turn := 0.0
var hud := HUD.new()
var guidebook := preload("res://scripts/guidebook.gd").new()
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var cam := Camera3D.new()
var yaw := 0.0
var pitch := 0.25
var velocity_y := 0.0
var t := 0.0
var grid := AStarGrid2D.new()
var camera_focus := Vector3.ZERO
var berry: Node3D
var sound := AudioStreamPlayer.new()

func _ready() -> void:
	get_window().title = "Monstereiland"
	bind_inputs()
	lighting()
	add_child(land)
	land.create_regions(SPECIES)
	add_child(finds)
	finds.build(SPECIES)
	finds.decorate_porch(SPECIES)
	land.blockers.append(Vector3(finds.PEAK.x,finds.PEAK.z,0.62))
	add_child(wonders)
	wonders.build(land)
	add_child(beach)
	beach.build(land)
	add_child(outings)
	outings.build(land)
	add_child(teamwork)
	teamwork.build(land)
	teamwork.milestone.connect(save_teamwork)
	beach.reached_water.connect(turtles_swim)
	ember.build(land)
	build_navigation(0)
	add_child(player)
	player.position = Vector3(-0.6,0,4.7)
	player.rotation.y = PI
	trail.append(player.position)
	var offsets := [Vector3.ZERO,Vector3(-5,0,4),Vector3(5,0,3),Vector3(3,0,7)]
	for resident in offsets.size():
		for kind in SPECIES.size():
			var species: Resource = SPECIES[kind]
			spawn_resident(species,quiz.Book.bank[species.display_name].namen[resident],resident,kind,species.home+offsets[resident])
	var ember_kinds := ember.residents()
	for i in ember_kinds.size():
		var kind: Resource = ember_kinds[i]
		var entry: Dictionary = quiz.Book.bank[kind.habitat]
		spawn_resident(kind,entry.namen[i%4],i%4,-1,kind.home,entry.bewaar_ids[i%4])
	cam.fov = 55
	cam.near = 0.12
	add_child(cam)
	camera_focus = player.position+Vector3(0,1.36,0)
	move_camera(1.0)
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(hud)
	layer.add_child(guidebook)
	layer.add_child(quiz)
	layer.add_child(sky_book)
	sky_book.closed.connect(close_sky)
	sky_book.chart_found.connect(save_chart)
	quiz.closed.connect(close_quiz)
	quiz.finished.connect(finish_quiz)
	guidebook.treasures = finds.found
	guidebook.stamps = wonders.stamps
	guidebook.setup(SPECIES,creatures)
	guidebook.travel_requested.connect(travel_from_map)
	guidebook.discoveries = ember.discovered
	guidebook.toggle_requested.connect(toggle_follow)
	guidebook.close_requested.connect(toggle_book)
	guidebook.practice_requested.connect(practice_with)
	hud.camera = cam
	hud.pad = not Input.get_connected_joypads().is_empty()
	# A click captures the mouse. An uncaptured drag also orbits the camera.
	add_child(sound)
	sound.stream = friendship_song()
	restore_cottage()
	if "--emberflame" in OS.get_cmdline_user_args() and island_id!=1:
		disembark(1)
		hud.cottage_message("Welkom op Emberflame Island!")
	refresh_island()

func spawn_resident(kind: Resource, nickname: String, rank: int, palette: int, home: Vector3, saved_id := "") -> void:
	var c := Creature.instantiate()
	c.species = kind
	c.nickname = nickname
	c.save_id = nickname if saved_id.is_empty() else saved_id
	c.name = nickname
	c.level = rank+1
	c.shiny = rank==3
	c.palette = palette
	c.position = home
	c.clock = creatures.size()*1.73
	add_child(c)
	creatures.append(c)

func refresh_island() -> void:
	ember.details.visible = island_id==1
	hud.total = 0
	hud.friends = 0
	for c in creatures:
		var local := Ember.on_ember(c.home)==(island_id==1)
		c.visible = local or c.following
		if local:
			hud.total += 1
			hud.friends += int(c.friend)

func build_navigation(destination: int) -> void:
	grid.region = [Rect2i(-153,-125,337,251),Rect2i(230,-90,220,181)][destination]
	grid.cell_size = Vector2(0.5,0.5)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(grid.region.position.x,grid.region.end.x):
		for z in range(grid.region.position.y,grid.region.end.y):
			grid.set_point_solid(Vector2i(x,z),not land.accessible(Vector3(x*0.5,0,z*0.5),0.15))

func disembark(port: int) -> void:
	var destination: int = Ember.PORT_ISLAND[port]
	if destination!=island_id:
		build_navigation(destination)
	island_id = destination
	var inward: Vector3 = Ember.INWARD[port]
	player.position = Ember.PORTS[port]+inward*(17 if port==0 else 11)
	yaw = -atan2(inward.x,-inward.z)
	player.rotation.y = atan2(inward.x,inward.z)
	walk_heading = inward
	reversing = false
	lane_sign = 1
	velocity_y = 0
	trail.assign([player.position])
	for c in creatures:
		if c.following:
			c.position = trailing_spot(player.position,c.follow_slot)
			c.velocity = Vector3.ZERO
			c.follow_speed = 0
	camera_focus = player.position+Vector3.UP*1.35
	move_camera(1)
	guidebook.island_id = destination
	guidebook.species = SPECIES if destination==0 else ember.pages
	guidebook.page = 0
	guidebook.row = 0
	refresh_island()

func lighting() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#64bde8")
	sky_mat.sky_horizon_color = Color("#c3eee6")
	sky_mat.ground_horizon_color = Color("#c3eee6")
	sky_mat.ground_bottom_color = Color("#90dbde")
	sky_mat.sky_curve = 0.28
	sky_mat.sun_angle_max = 0
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1dc")
	env.ambient_light_energy = 0.66
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-51,-32,0)
	sun.light_color = Color("#fff3d9")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 54
	sun.shadow_opacity = 0.57
	add_child(sun)

func bind_inputs() -> void:
	var keys := {"west":KEY_A,"east":KEY_D,"north":KEY_W,"south":KEY_S,
		"offer":KEY_SPACE,"hop":KEY_SHIFT,"run":KEY_CTRL,"journal":KEY_TAB}
	for action in pads.SOLO_BUTTONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action,0.18)
			if keys.has(action):
				var key := InputEventKey.new()
				key.physical_keycode = keys[action]
				InputMap.action_add_event(action,key)
	Input.joy_connection_changed.connect(pad_connection)
	for device in Input.get_connected_joypads():
		pad_connection(device,true)

func pad_connection(device: int, connected: bool) -> void:
	pads.connection(device,connected)
	hud.pad = not pads.single_left.is_empty()
	hud.single_left = pads.single_left.values().has(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("offer"):
		solo_jump_chord = event is InputEventJoypadButton and pads.single_left.get(event.device,false) and Input.is_joy_button_pressed(event.device,JOY_BUTTON_LEFT_SHOULDER)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value)>0.22):
		hud.pad = true
		hud.single_left = pads.single_left.get(event.device,false)
	elif event is InputEventKey or event is InputEventMouseButton:
		hud.pad = false
	if quiz.visible or sky_book.visible:
		return
	if guidebook.visible:
		if event is InputEventKey and event.keycode==KEY_ESCAPE and event.pressed:
			toggle_book()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and hud.book_rect().has_point(hud.get_local_mouse_position()):
		toggle_book()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and (Input.mouse_mode==Input.MOUSE_MODE_CAPTURED or event.button_mask&MOUSE_BUTTON_MASK_RIGHT):
		yaw -= event.relative.x*0.004
		pitch = clampf(pitch+event.relative.y*0.003,0.07,0.95)

func _physics_process(dt: float) -> void:
	if sky_book.visible:
		sky_book.navigate()
		return
	if quiz.visible:
		quiz.navigate()
		return
	var chord_jump := solo_jump_chord and Input.is_action_just_pressed("offer")
	if Input.is_action_just_pressed("journal"):
		toggle_book()
		return
	if guidebook.visible:
		guidebook.navigate()
		return
	t += dt
	var pan := Input.get_vector("pan_left","pan_right","pan_up","pan_down")
	yaw -= pan.x*dt*2.2
	pitch = clampf(pitch+pan.y*dt*1.5,0.07,0.95)
	var stick := Input.get_vector("west","east","north","south")
	var direction := Vector3(stick.x,0,stick.y).rotated(Vector3.UP,yaw)
	var last_foot := Vector3(player.position.x,0,player.position.z)
	var running := Input.is_action_pressed("run")
	var speed := RUN_SPEED if running else WALK_SPEED
	var travel := direction*dt*speed
	for move in [Vector3(travel.x,0,0),Vector3(0,0,travel.z)]:
		if land.accessible(player.position+move):
			player.position += move
	if direction.length_squared()>0.003:
		player.rotation.y = lerp_angle(player.rotation.y,atan2(direction.x,direction.z),1-exp(-dt*13))
	var ground := land.height_at(player.position)
	var jump_height := maxf(0,player.position.y-land.height_at(last_foot))
	if (Input.is_action_just_pressed("hop") or chord_jump) and jump_height<=0.001:
		velocity_y = 5.3
	velocity_y -= 15*dt
	jump_height = maxf(0,jump_height+velocity_y*dt)
	player.position.y = ground+jump_height
	if jump_height<=0:
		velocity_y = 0
	player.animate(dt*speed/WALK_SPEED,stick.length(),jump_height>0.06)
	var foot := Vector3(player.position.x,0,player.position.z)
	var motion := foot-last_foot
	if motion.length_squared()>0.000001:
		var heading := motion.normalized()
		if heading.dot(walk_heading)<-0.70:
			lane_sign *= -1.0
			reversing = true
			after_turn = 0.0
		after_turn += motion.length()
		if after_turn>6.0:
			reversing = false
		walk_heading = heading
	if foot.distance_to(trail[0])>=0.12:
		trail.push_front(foot)
		if trail.size()>64:
			trail.pop_back()
	hud.place = "Sterrenheuvel" if ground>0.1 else "Vareneiland"
	for species in SPECIES:
		if foot.distance_to(species.home)<13:
			hud.place = species.habitat
			break
	if island_id==1:
		hud.place = "Emberflame Island"
		if ember.approach_volcano(foot):
			hud.cottage_message("Ontdekt! De vuurberg barst uit!" if save_progress() else "Uitbarsting ontdekt! Opslaan lukt niet.")
		for i in Ember.HOMES.size():
			if foot.distance_to(Ember.CENTER+Ember.HOMES[i])<13:
				hud.place = Ember.REGIONS[i]
				break
	var spots := following_spots(foot)
	hud.target = null
	var nearest := 3.85
	for creature in creatures:
		if not creature.visible:
			continue
		var goal := foot
		if creature.following:
			goal = spots[creature.follow_slot]
			if reversing and motion.length_squared()>0.000001:
				# Let the explorer pass instead of racing back through the flock.
				var retreat: float = (goal-creature.position).dot(walk_heading)
				if retreat<0:
					var waiting: Vector3 = goal-walk_heading*retreat
					if land.accessible(waiting):
						goal = waiting
		if creature==teamwork.helper and creature.following:
			goal = teamwork.goal
		creature.step(dt,player.position,follow_route.bind(creature),goal,running)
		var surface := land.height_at(creature.position)
		creature.model.position.y += surface
		creature.marker.position.y = creature.species.hover_height+1.18+surface
		var delta := creature.position-player.position
		var distance := Vector2(delta.x,delta.z).length()
		if not creature.friend and distance<nearest:
			hud.target = creature
			nearest = distance
	beach.animate(dt,t,foot)
	var at_nest := foot.distance_to(beach.NEST)<2.5
	if foot.distance_to(beach.NEST)<12 or foot.distance_to(beach.route(beach.progress))<5.0:
		hud.place = "Schildpadstrand"
	wonders.animate(dt,t)
	var wonder := wonders.nearest(foot)
	if wonder>=0 and foot.distance_squared_to(wonders.PLACES[wonder])<1.4:
		hud.target = null
	hud.wonder_action = wonders.ACTIONS[wonder] if wonder>=0 and not hud.target else ""
	if at_nest and not beach.active and not beach.home:
		hud.wonder_action = "Kijk bij de eitjes"
	var outing := outings.nearby(foot)
	if outing!="":
		hud.target = null
		hud.wonder_action = outings.prompt(outing)
	var team_action := teamwork.nearby(foot)
	if team_action!="":
		hud.target = null
		hud.wonder_action = teamwork.prompt(team_action)
	var carrier: Node3D
	for c in creatures:
		if c.following:
			carrier = c
			break
	teamwork.animate(dt,t,foot,carrier)
	var hand: Vector3 = carrier.model.global_position if carrier else player.position+Vector3.UP
	outings.animate(dt,t,hand,cam.global_position)
	finds.animate(t)
	for kind in SPECIES:
		if kind.theme not in finds.found and foot.distance_to(kind.relic_position)<1.35:
			finds.mark(kind.theme)
			hud.cottage_message("Schat gevonden! "+kind.relic if save_progress() else "Opslaan lukt niet. Probeer het bij het huisje.")
	hud.at_peak = player.position.distance_to(finds.PEAK)<3
	hud.at_cottage = foot.distance_to(Terrain.PORCH)<1.65
	if hud.at_cottage:
		hud.target = null
	var port := Ember.nearby_port(foot,island_id)
	var site := ember.nearby_site(foot) if island_id==1 else -1
	if island_id==1:
		ember.animate_sites(t)
	if site>=0:
		hud.target = null
		hud.wonder_action = Ember.SITE_ACTIONS[site]
	if port>=0:
		hud.target = null
		hud.wonder_action = "Vaar naar "+Ember.ISLAND_NAMES[Ember.PORT_ISLAND[Ember.CONNECTION[port]]]
	if not chord_jump and Input.is_action_just_pressed("offer"):
		if port>=0:
			sail_to(Ember.CONNECTION[port])
		elif site>=0:
			var fresh: bool = Ember.SITE_NAMES[site] not in ember.discovered
			ember.explore(site)
			if site in [0,1]:
				wonders.play_melody(foot+Vector3.UP*(ground+1),1.26 if site==1 else 0.84)
			var message: String = ("Ontdekt! " if fresh else "")+Ember.SITE_NAMES[site]
			hud.cottage_message(message if not fresh or save_progress() else "Opslaan lukt niet.")
		elif hud.at_cottage:
			save_at_cottage()
		elif hud.at_peak:
			open_sky()
		elif team_action!="":
			var message := teamwork.interact(team_action,carrier,foot)
			if message!="":
				hud.cottage_message(message)
		elif outing!="":
			var message := outings.interact(outing)
			hud.cottage_message(message if save_progress() else "Opslaan lukt niet. Probeer het bij het huisje.")
		elif at_nest and not beach.active and not beach.home:
			beach.start()
			hud.cottage_message("Daar zijn ze! Loop met de kleintjes mee.")
		elif wonder>=0 and not hud.target:
			var fresh := wonder not in wonders.stamps
			wonders.play(wonder)
			if fresh:
				var message := "Stempel! "+str(wonders.NAMES[wonder])
				if wonders.compass.visible:
					message = "Vijf stempels! Je kompas hangt bij het huisje."
				hud.cottage_message(message if save_progress() else "Opslaan lukt niet. Probeer het bij het huisje.")
		elif hud.target:
			previous_mouse_mode = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hud.hide()
			quiz.begin(hud.target,hud.pad,hud.single_left)
	move_camera(dt)
	land.animate(t)

func following_spots(foot: Vector3) -> Dictionary:
	var spots := {}
	var friends := creatures.filter(func(c): return c.following)
	for c in friends:
		spots[c.follow_slot] = trailing_spot(foot,c.follow_slot)
	# Trade places when both routes together become materially shorter.
	# The margin keeps neighbours in their lanes during ordinary walking.
	for i in friends.size():
		for j in i:
			var a: Node3D = friends[i]
			var b: Node3D = friends[j]
			var first: Vector3 = spots[a.follow_slot]
			var second: Vector3 = spots[b.follow_slot]
			var current := a.position.distance_to(first)+b.position.distance_to(second)
			var swapped := a.position.distance_to(second)+b.position.distance_to(first)
			if swapped+0.75<current:
				var tmp: Vector2 = a.follow_slot
				a.follow_slot = b.follow_slot
				b.follow_slot = tmp
	return spots

func trailing_spot(foot: Vector3, slot: Vector2) -> Vector3:
	var remaining := slot.y
	var back := -player.transform.basis.z
	var point := foot
	for previous in trail:
		var length := point.distance_to(previous)
		if length>0.0001:
			back = (previous-point)/length
			if remaining<=length:
				break
			remaining -= length
		point = previous
	# On the first few steps, extend the short trail behind the explorer.
	var center := point+back*remaining
	var across := Vector3(-back.z,0,back.x)
	var right := Vector3(walk_heading.z,0,-walk_heading.x)
	if across.dot(right)<0:
		across = -across
	# A folded trail can point in front of the explorer after a U-turn.
	# Keep the same passing lanes and regroup on the new trailing side.
	if (center-foot).dot(walk_heading)>-0.25*slot.y:
		var behind := foot-walk_heading*slot.y
		if land.accessible(behind):
			center = behind
			across = right
	var offset := center+across*lane_sign*slot.x
	if land.accessible(offset):
		return offset
	return center if land.accessible(center) else point

func clear_walk(a: Vector3, b: Vector3) -> bool:
	var samples := maxi(1,ceili(a.distance_to(b)/0.22))
	for i in range(1,samples+1):
		if not land.accessible(a.lerp(b,i/float(samples))):
			return false
	return true

# Sample a short arc ahead. Prefer the direct stride, then the gentlest
# walkable detour that leaves space around the other companions.
func spaced_stride(a: Vector3, goal: Vector3, follower: Node3D) -> Vector3:
	var delta := goal-a
	var reach := minf(0.65,delta.length())
	if reach<0.001:
		return goal
	var forward := delta.normalized()
	for angle in [0.0,0.36,-0.36,0.72,-0.72,1.10,-1.10,1.55,-1.55]:
		var tip: Vector3 = a+forward.rotated(Vector3.UP,angle)*reach
		if not clear_walk(a,tip):
			continue
		var free := true
		for other in creatures:
			if other==follower or not other.following:
				continue
			var relative_tip: Vector3 = tip-other.velocity*(reach/5.8)
			var nearest := a
			if relative_tip.distance_squared_to(a)>0.000001:
				nearest = Geometry3D.get_closest_point_to_segment(other.position,a,relative_tip)
			var limit := minf(1.56,a.distance_to(other.position))
			if nearest.distance_to(other.position)<limit-0.0001:
				free = false
				break
		if free:
			return tip
	return a

func follow_route(a: Vector3, b: Vector3, follower: Node3D) -> Vector3:
	if clear_walk(a,b):
		return spaced_stride(a,b,follower)
	var start := Vector2i(roundi(a.x*2),roundi(a.z*2))
	var end := Vector2i(roundi(b.x*2),roundi(b.z*2))
	if not grid.is_in_boundsv(end) or grid.is_point_solid(end):
		end = Vector2i(roundi(player.position.x*2),roundi(player.position.z*2))
	# The navigation grid leaves clearance around obstacles. A walking
	# companion can stand in that margin and need a visible entry cell.
	if grid.is_point_solid(start):
		var nearest := INF
		for dx in range(-1,2):
			for dz in range(-1,2):
				var cell := Vector2i(roundi(a.x*2)+dx,roundi(a.z*2)+dz)
				if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
					continue
				var point := Vector3(cell.x*0.5,a.y,cell.y*0.5)
				var distance := a.distance_squared_to(point)
				if distance<nearest and clear_walk(a,point):
					nearest = distance
					start = cell
		if nearest==INF:
			return a
	var path := grid.get_point_path(start,end,true)
	# Steer through visible waypoints in one stride around trees and pond banks.
	for i in range(path.size()-1,-1,-1):
		var waypoint := Vector3(path[i].x,a.y,path[i].y)
		if clear_walk(a,waypoint):
			return spaced_stride(a,waypoint,follower)
	return a

func move_camera(dt: float) -> void:
	var goal := Vector3(player.position.x,1.35+land.height_at(player.position)*0.55+player.position.y*0.45,player.position.z)
	camera_focus = camera_focus.lerp(goal,1-exp(-dt*12))
	var axis := Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	var distance := 6.25
	for i in 25:
		var d := 1.0+i*0.22
		var probe := camera_focus+axis*d
		for block in land.blockers:
			if Vector2(probe.x-block.x,probe.z-block.y).length()<block.z+0.28 and probe.y<4.4:
				distance = minf(distance,maxf(1.0,d-0.24))
				break
	# Look down over the explorer when a trunk forces the camera in close.
	var lift := maxf(0,3.8-distance)
	cam.position = camera_focus+axis*maxf(distance,1.65)+Vector3.UP*lift*0.95
	cam.look_at(camera_focus)

func practice_with(c: Node3D) -> void:
	guidebook.hide()
	quiz.begin(c,hud.pad,hud.single_left)

func close_quiz() -> void:
	quiz.hide()
	if quiz.resident.friend:
		guidebook.show()
		guidebook.queue_redraw()
		return
	hud.show()
	Input.mouse_mode = previous_mouse_mode

func finish_quiz(c: Node3D) -> void:
	close_quiz()
	if c.friend:
		guidebook.notice = "Goed gedaan! "+c.nickname+" geeft je een boks."
		guidebook.queue_redraw()
		return
	befriend(c)
	if not save_progress():
		hud.cottage_message("Opslaan lukt niet. Probeer het bij het huisje.")

func befriend(creature: Node3D) -> void:
	creature.friend = true
	if free_slot()!=-1:
		activate(creature,false)
	hud.friends += 1
	update_pennants(true)
	hud.new_friend = creature
	hud.target = null
	hud.celebration = 0
	berry = S.group(self,player.position+Vector3.UP*1.0)
	S.ball(berry,Vector3.ZERO,Vector3(0.13,0.15,0.13),"ed6354")
	S.ball(berry,Vector3(0.05,0.15,0),Vector3(0.075,0.035,0.05),"79ae51")
	var flight := create_tween()
	flight.tween_property(berry,"position",(berry.position+creature.position)/2+Vector3.UP*1.4,0.19)
	flight.tween_property(berry,"position",creature.position+Vector3.UP*1.2,0.18)
	flight.tween_callback(berry.queue_free)
	sound.play()

func friendship_song() -> AudioStreamWAV:
	var audio := AudioStreamWAV.new()
	audio.mix_rate = 22050
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	var samples := PackedByteArray()
	samples.resize(22050*2)
	for i in 22050:
		var sec := i/22050.0
		var value := 0.0
		for j in 3:
			var age := sec-j*0.14
			if age>=0:
				value += sin(age*TAU*[523.25,659.25,783.99][j])*exp(-age*8)*minf(1,age*60)*0.21
		samples.encode_s16(i*2,roundi(value*32767))
	audio.data = samples
	return audio

func travel_from_map() -> void:
	toggle_book()
	sail_to(Ember.CONNECTION[island_id])

func sail_to(port: int) -> void:
	disembark(port)
	hud.cottage_message("Welkom op "+Ember.ISLAND_NAMES[island_id]+"!" if save_progress() else "Opslaan lukt niet.")

func toggle_book() -> void:
	if guidebook.visible:
		guidebook.hide()
		hud.show()
		Input.mouse_mode = previous_mouse_mode
	else:
		previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.hide()
		guidebook.eruption_seen = ember.eruption_seen
		guidebook.explorer = player.position
		guidebook.open(hud.pad,hud.single_left)

func free_slot() -> int:
	for i in FOLLOW_SLOTS.size():
		var used := false
		for c in creatures:
			if c.following and c.follow_slot==FOLLOW_SLOTS[i]:
				used = true
				break
		if not used:
			return i
	return -1

func activate(c: Node3D, recall: bool) -> void:
	c.follow_slot = FOLLOW_SLOTS[free_slot()]
	c.following = true
	c.show()
	if recall:
		c.position = trailing_spot(Vector3(player.position.x,0,player.position.z),c.follow_slot)
	c.follow_speed = 0
	c.velocity = Vector3.ZERO

func toggle_follow(c: Node3D) -> void:
	if not c.friend:
		return
	if c.following:
		c.following = false
		c.visible = Ember.on_ember(c.home)==(island_id==1)
		c.position = c.home
		c.velocity = Vector3.ZERO
		c.follow_speed = 0
	elif free_slot()!=-1:
		activate(c,true)
	else:
		guidebook.notice = "Kies eerst een vriend die thuis mag rusten."
	guidebook.queue_redraw()

func save_progress() -> bool:
	var friends := []
	var team := []
	for c in creatures:
		if c.friend:
			friends.append(c.save_id)
		if c.following:
			team.append(c.save_id)
	var trips := outings.snapshot()
	trips["island"] = island_id
	trips["eruption_seen"] = ember.eruption_seen
	trips["ember_sites"] = ember.discovered
	trips["teamwork"] = teamwork.snapshot()
	return checkpoint.write(friends,team,finds.found,wonders.stamps,sky_book.album,beach.home,trips)

func save_at_cottage() -> void:
	if save_progress():
		if hud.friends==hud.total:
			finds.streamers.restart()
			sound.play()
		hud.cottage_message("Slaap lekker! Je spel is bewaard.")
	else:
		hud.cottage_message("Opslaan lukt niet. Probeer het nog eens.")

func restore_cottage() -> void:
	var data := checkpoint.read()
	if data.is_empty():
		if start_on_ember:
			disembark(1)
		if checkpoint.read_error:
			hud.cottage_message("Je bewaarde spel kan niet open.")
		return
	if data.get("treasures") is Array:
		for theme in data.treasures:
			if theme is String:
				finds.mark(theme)
	if data.get("outings") is Dictionary:
		outings.restore(data.outings)
		ember.eruption_seen = data.outings.get("eruption_seen")==true
		if data.outings.get("ember_sites") is Array:
			for i in Ember.SITE_NAMES.size():
				if Ember.SITE_NAMES[i] in data.outings.ember_sites:
					ember.explore(i)
		if data.outings.get("teamwork") is Dictionary:
			teamwork.restore(data.outings.teamwork)
	if data.get("turtles")==true:
		beach.restore()
	if data.get("charts") is Array:
		for chart in sky_book.CHARTS:
			if chart[0] in data.charts:
				sky_book.album.append(chart[0])
	if data.get("stamps") is Array:
		for id in data.stamps:
			if id is float or id is int:
				wonders.stamp(int(id))
	player.position = Terrain.PORCH
	player.rotation.y = PI
	trail.assign([player.position])
	camera_focus = player.position+Vector3.UP*1.35
	if outings.flying:
		outings.kite.position = player.position+Vector3(2.8,3.5,-1.65)
	move_camera(1)
	for c in creatures:
		if c.save_id in data.friends:
			c.friend = true
			hud.friends += 1
			if c.save_id in data.party and free_slot()!=-1:
				activate(c,true)
	if data.get("outings") is Dictionary and data.outings.get("island")==1:
		disembark(1)
		hud.cottage_message("Welkom terug op Emberflame Island!")
		update_pennants(false)
		return
	update_pennants(false)
	hud.cottage_message("Goedemorgen! Welkom thuis.")

func open_sky() -> void:
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	sky_book.open(finds.found.size(),hud.pad,hud.single_left)

func close_sky() -> void:
	sky_book.hide()
	hud.show()
	Input.mouse_mode = previous_mouse_mode

func save_chart(title: String) -> void:
	sky_book.album.append(title)
	if not save_progress():
		sky_book.notice = "Opslaan lukt niet. Probeer het bij het huisje."

func turtles_swim() -> void:
	var message := "Hoera! Drie schildpadjes op weg naar zee."
	hud.cottage_message(message if save_progress() else "Opslaan lukt niet. Probeer het bij het huisje.")

func update_pennants(announce: bool) -> void:
	for i in SPECIES.size():
		var kind: Resource = SPECIES[i]
		var complete := creatures.all(func(c): return c.species!=kind or c.friend)
		if complete and not finds.pennants[i].visible:
			finds.pennants[i].show()
			if announce:
				var message: String = "Een vaantje voor de "+kind.habitat+"!"
				if hud.friends==hud.total:
					message = "Twintig vrienden! Vier het bij je huisje!"
				hud.cottage_message(message)

func save_teamwork(message: String) -> void:
	hud.cottage_message(message if save_progress() else "Opslaan lukt niet. Probeer het bij het huisje.")
