extends SceneTree
# Run with --script res://tests/playthrough.gd. Optional -- --captures=/absolute/directory.
var errors := 0
var game
var capture_dir := ""
const TEST_PAD := 7
var active_pad := TEST_PAD

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="):
			capture_dir = arg.trim_prefix("--captures=")
	play.call_deferred()

func check(ok: bool, description: String) -> void:
	if not ok:
		errors += 1
		push_error(description)
	else:
		print("PASS ", description)

func ticks(n: int) -> void:
	for i in n:
		await physics_frame

func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func button(code: JoyButton, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = active_pad
	e.button_index = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func axis(code: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = active_pad
	e.axis = code
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func capture(name: String) -> void:
	if capture_dir.is_empty():
		return
	if "--manual-draw" in OS.get_cmdline_user_args():
		await process_frame
		RenderingServer.force_draw()
	else:
		await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(capture_dir.path_join(name+".png"))
	check(result==OK,"Saved "+name)

var checkpoint_path := "user://cottage-test-%d.json" % Time.get_ticks_usec()

func start_island() -> void:
	game = preload("res://scenes/island.tscn").instantiate()
	game.start_on_ember = false
	game.checkpoint.path = checkpoint_path
	root.add_child(game)
	current_scene = game

func play() -> void:
	test_question_bank()
	start_island()
	game.pads.install(TEST_PAD,false)
	await ticks(60)
	var first: Node3D = game.creatures[0]
	var start: Vector3 = first.position
	var height: float = first.model.position.y
	await ticks(35)
	check(first.position.distance_to(start)>0.05,"Flamelingo wanders")
	check(absf(height-first.model.position.y)>0.015,"Flamelingo floats")
	check(game.hud.target==first and game.hud.counter_text()=="0/20","Feeding prompt is available")
	await capture("fernfall-cay")
	start = game.player.position
	for frame in 12:
		key(KEY_W,true)
		await ticks(1)
	key(KEY_W,false)
	check(game.player.position.z<start.z-0.45,"W walks toward the clearing")
	key(KEY_SHIFT,true)
	await ticks(5)
	key(KEY_SHIFT,false)
	check(game.player.position.y>0.15,"Shift jumps")
	await ticks(55)
	check(game.player.position.y==0,"Explorer lands")
	key(KEY_SPACE,true)
	await ticks(2)
	key(KEY_SPACE,false)
	await ticks(2)
	await capture("vriendenproef")
	await tap_key(KEY_TAB)
	check(not first.friend and not game.quiz.visible,"Leaving a quiz never unlocks friendship")
	await tap_key(KEY_SPACE)
	await solve_quiz(first)
	check(first.friend and game.hud.counter_text()=="1/20","Space befriends Flamelingo and updates the counter")
	await ticks(23)
	await capture("first-friend")
	start = first.position
	for frame in 77:
		axis(JOY_AXIS_LEFT_X,1)
		await ticks(1)
	axis(JOY_AXIS_LEFT_X,0)
	await ticks(75)
	check(game.player.position.x>4,"Left stick moves explorer")
	check(first.position.distance_to(start)>1 and first.position.distance_to(game.player.position)<4.0,"Friend follows and catches up")
	var yaw: float = game.yaw
	axis(JOY_AXIS_RIGHT_X,0.8)
	await ticks(12)
	axis(JOY_AXIS_RIGHT_X,0)
	check(absf(game.yaw-yaw)>0.1,"Right stick orbits camera")
	var mouse := InputEventMouseMotion.new()
	mouse.button_mask = MOUSE_BUTTON_MASK_RIGHT
	mouse.relative = Vector2(30,0)
	yaw = game.yaw
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	await ticks(2)
	check(absf(game.yaw-yaw)>0.08,"Mouse drag orbits camera")
	button(JOY_BUTTON_A,true)
	await ticks(5)
	button(JOY_BUTTON_A,false)
	check(game.player.position.y>0.15,"Nintendo B jumps")
	# Visit every habitat using the same two stick axes as a controller.
	for i in range(1,game.SPECIES.size()):
		var creature: Node3D = game.creatures[i]
		var name_text: String = creature.species.display_name
		var side := 0.55
		await walk_to(creature.home+Vector3(side,0,1.0))
		await frame_habitat()
		await ticks(12)
		check(game.hud.target==creature,"Nearby prompt selects "+name_text)
		await capture(name_text.to_lower())
		var offer_button := JOY_BUTTON_B
		if i==1:
			var connected_left = game.pads.single_left.find_key(true)
			if connected_left!=null:
				active_pad = connected_left
				print("Testing detected single-controller profile: ",Input.get_joy_name(active_pad))
			else:
				game.pads.remove(TEST_PAD)
				game.pads.install(TEST_PAD,true)
			await check_solo_controls()
			await check_solo_menu(first)
			offer_button = JOY_BUTTON_RIGHT_SHOULDER
		button(offer_button,true)
		await ticks(2)
		button(offer_button,false)
		await ticks(2)
		await solve_quiz(creature,offer_button)
		check(creature.friend and game.hud.pad,"Controller befriends "+name_text)
		check(game.hud.counter_text()=="%d/20" % (i+1),"HUD reads "+game.hud.counter_text())
		button(offer_button,true)
		await ticks(2)
		button(offer_button,false)
		check(game.hud.friends==i+1,"Repeat offer leaves count unchanged")
		if i==1:
			if active_pad==TEST_PAD:
				game.pads.remove(TEST_PAD)
				game.pads.install(TEST_PAD,false)
			active_pad = TEST_PAD
	await walk_to(Vector3(-0.5,0,3.5))
	await frame_habitat(0.46)
	await ticks(160)
	for creature in party():
		check(creature.friend and creature.position.distance_to(game.player.position)<5.8,creature.name+" follows the explorer")
	check(game.hud.counter_text()=="5/20" and party().size()==5,"One resident of every species follows")
	await check_following_leg(1,"walking east")
	await check_following_leg(-1,"doubling back west")
	await capture("five-friends")
	# Turn the whole party through a square corner before checking steady speed.
	axis(JOY_AXIS_LEFT_Y,-1)
	var corner_spacing := INF
	for i in 23:
		await ticks(1)
		corner_spacing = minf(corner_spacing,friend_spacing())
	axis(JOY_AXIS_LEFT_Y,0)
	axis(JOY_AXIS_LEFT_X,1)
	for i in 48:
		await ticks(1)
		corner_spacing = minf(corner_spacing,friend_spacing())
	axis(JOY_AXIS_LEFT_X,0)
	check(corner_spacing>1.48,"Room through a right-angle corner (minimum %.2f)" % corner_spacing)
	await check_steady_pace(0.45)
	await check_steady_pace(1.0)
	await ticks(80)
	axis(JOY_AXIS_RIGHT_X,1)
	await ticks(65)
	axis(JOY_AXIS_RIGHT_X,0)
	for creature in party():
		var to_player: Vector3 = game.player.position-creature.position
		check(creature.model.transform.basis.z.dot(to_player.normalized())>0.95,
			creature.name+" watches the stopped explorer during a camera orbit")
	if game.sound.playing:
		await game.sound.finished
	check(not game.sound.playing and not is_instance_valid(game.berry),"Feeding chime and berry animation complete")
	await collect_remaining()
	await check_treasures()
	await check_outings()
	await check_helpers()
	await check_beach()
	await check_cottage()
	if game.sound.playing:
		await game.sound.finished
	print("Playthrough failures: ",errors)
	quit(1 if errors else 0)

func walk_to(goal: Vector3) -> void:
	var start := Vector2i(roundi(game.player.position.x*2),roundi(game.player.position.z*2))
	var end := Vector2i(roundi(goal.x*2),roundi(goal.z*2))
	var path: PackedVector2Array = game.grid.get_point_path(start,end)
	check(not path.is_empty(),"Habitat route is walkable")
	for waypoint in path:
		for frame in 24:
			var delta := Vector3(waypoint.x-game.player.position.x,0,waypoint.y-game.player.position.z)
			if delta.length()<0.12:
				break
			var stick := delta.normalized().rotated(Vector3.UP,-game.yaw)
			axis(JOY_AXIS_LEFT_X,stick.x)
			axis(JOY_AXIS_LEFT_Y,stick.z)
			await ticks(1)
	axis(JOY_AXIS_LEFT_X,0)
	axis(JOY_AXIS_LEFT_Y,0)
	check(Vector2(game.player.position.x-goal.x,game.player.position.z-goal.z).length()<0.55,"Explorer arrived by walking")

func frame_habitat(elevation := 0.32) -> void:
	for i in 150:
		var angle: float = wrapf(game.yaw,-PI,PI)
		var tilt: float = elevation-game.pitch
		if absf(angle)<0.035 and absf(tilt)<0.025:
			break
		axis(JOY_AXIS_RIGHT_X,signf(angle) if absf(angle)>0.035 else 0)
		axis(JOY_AXIS_RIGHT_Y,signf(tilt) if absf(tilt)>0.025 else 0)
		await ticks(1)
	axis(JOY_AXIS_RIGHT_X,0)
	axis(JOY_AXIS_RIGHT_Y,0)
	await ticks(43)

func check_following_leg(direction: int, description: String) -> void:
	var start: Vector3 = game.player.position
	var walked_forward := true
	var closest := INF
	var moved := PackedFloat32Array()
	moved.resize(party().size())
	for frame in (103 if direction>0 else 141):
		axis(JOY_AXIS_LEFT_X,direction)
		var before: Array[Vector3] = []
		for creature in party():
			before.append(creature.position)
		await ticks(1)
		closest = minf(closest,friend_spacing())
		for i in party().size():
			var creature: Node3D = party()[i]
			var stride := creature.position-before[i]
			if stride.length()>0.001:
				moved[i] += stride.length()
				walked_forward = walked_forward and creature.model.transform.basis.z.dot(stride.normalized())>0.69
	axis(JOY_AXIS_LEFT_X,0)
	var heading: Vector3 = (game.player.position-start).normalized()
	check(game.player.position.distance_to(start)>6.0,"Explorer covered a straight stretch "+description)
	check(closest>1.48,"Companions leave room "+description+" (minimum %.2f)" % closest)
	check(walked_forward,"Every moving companion faces its own stride "+description)
	for i in party().size():
		var creature: Node3D = party()[i]
		var to_player: Vector3 = game.player.position-creature.position
		var minimum_walk := 1.0 if direction<0 else 3.0 # Companions yield while the explorer passes.
		check(moved[i]>minimum_walk and to_player.dot(heading)>1.0 and creature.model.transform.basis.z.dot(heading)>0.9,
			creature.name+" trails behind and faces forward "+description)


func check_steady_pace(strength: float) -> void:
	for frame in (124 if strength<1 else 35):
		axis(JOY_AXIS_LEFT_X,strength)
		await ticks(1)
	var worst_difference := 0.0
	var distance_walked := 0.0
	for frame in 30:
		axis(JOY_AXIS_LEFT_X,strength)
		var explorer_before: Vector3 = game.player.position
		var before: Array[Vector3] = []
		for creature in party():
			before.append(creature.position)
		await ticks(1)
		var explorer_step := explorer_before.distance_to(game.player.position)
		distance_walked += explorer_step
		for i in party().size():
			var step := before[i].distance_to(party()[i].position)
			worst_difference = maxf(worst_difference,absf(step-explorer_step))
	axis(JOY_AXIS_LEFT_X,0)
	check(distance_walked>0.5 and worst_difference<0.004,"All five maintain the explorer's steady pace at %.0f%% stick input" % (strength*100))

func friend_spacing() -> float:
	var nearest := INF
	for i in party().size():
		for j in i:
			nearest = minf(nearest,party()[i].position.distance_to(party()[j].position))
	return nearest

func check_solo_controls() -> void:
	var start: Vector3 = game.player.position
	for code in [JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
		var before: Vector3 = game.player.position
		button(code,true)
		await ticks(5)
		button(code,false)
		var delta: Vector3 = (game.player.position-before).rotated(Vector3.UP,-game.yaw)
		var directions := {JOY_BUTTON_DPAD_RIGHT:Vector3.RIGHT,JOY_BUTTON_DPAD_LEFT:Vector3.LEFT,
			JOY_BUTTON_DPAD_UP:Vector3.FORWARD,JOY_BUTTON_DPAD_DOWN:Vector3.BACK}
		check(delta.dot(directions[code])>0.20,"Single Joy-Con stick walks "+str(directions[code]))
	var yaw: float = game.yaw
	button(JOY_BUTTON_X,true)
	await ticks(5)
	button(JOY_BUTTON_X,false)
	check(game.yaw>yaw and game.player.position.y==0,"Solo face button orbits without jumping")
	button(JOY_BUTTON_B,true)
	await ticks(5)
	button(JOY_BUTTON_B,false)
	check(game.hud.friends==1,"Solo camera input does not offer a berry")
	button(JOY_BUTTON_DPAD_RIGHT,true)
	await ticks(6)
	var walked := start.distance_to(game.player.position)
	var from: Vector3 = game.player.position
	button(JOY_BUTTON_LEFT_SHOULDER,true)
	await ticks(6)
	var ran := from.distance_to(game.player.position)
	check(ran>walked*1.35 and game.player.position.y==0,"Holding SL runs")
	from = game.player.position
	button(JOY_BUTTON_LEFT_SHOULDER,false)
	await ticks(6)
	check(absf(from.distance_to(game.player.position)-walked)<0.10,"Releasing SL resumes walking")
	button(JOY_BUTTON_DPAD_RIGHT,false)
	button(JOY_BUTTON_DPAD_LEFT,true)
	await ticks(22)
	button(JOY_BUTTON_DPAD_LEFT,false)
	button(JOY_BUTTON_LEFT_STICK,true)
	await ticks(5)
	button(JOY_BUTTON_LEFT_STICK,false)
	check(game.player.position.y>0.15,"Stick-click jumps")
	await ticks(50)
	button(JOY_BUTTON_LEFT_SHOULDER,true)
	await ticks(2)
	button(JOY_BUTTON_RIGHT_SHOULDER,true)
	await ticks(4)
	button(JOY_BUTTON_RIGHT_SHOULDER,false)
	button(JOY_BUTTON_LEFT_SHOULDER,false)
	check(game.player.position.y>0.15 and game.hud.friends==1,"SL plus SR jumps without feeding")
	await ticks(55)
	check(game.player.position.distance_to(start)<0.2,"Single Joy-Con movement releases cleanly")

func party() -> Array:
	return game.creatures.filter(func(c): return c.following)

func tap_key(code: Key) -> void:
	key(code,true)
	await ticks(2)
	key(code,false)
	await ticks(2)

func tap_button(code: JoyButton) -> void:
	button(code,true)
	await ticks(2)
	button(code,false)
	await ticks(2)

func check_solo_menu(first: Node3D) -> void:
	await tap_button(JOY_BUTTON_START)
	check(game.guidebook.visible,"Single Joy-Con opens field guide")
	var start: Vector3 = game.player.position
	await tap_button(JOY_BUTTON_RIGHT_SHOULDER)
	check(first.friend and not first.following and first.position.distance_to(first.home)<0.01,"SR sends the selected friend home")
	await tap_button(JOY_BUTTON_DPAD_RIGHT)
	check(game.guidebook.page==1,"Solo stick changes habitat in guide")
	await tap_button(JOY_BUTTON_DPAD_LEFT)
	await tap_button(JOY_BUTTON_RIGHT_SHOULDER)
	check(first.following and first.position.distance_to(game.player.position)<4,"SR recalls a resting friend across the island")
	await tap_button(JOY_BUTTON_START)
	check(not game.guidebook.visible and game.player.position.distance_to(start)<0.01,"Closing the guide resumes at the same spot")

func collect_remaining() -> void:
	for kind in game.SPECIES:
		var group: Array = game.creatures.filter(func(c): return c.species==kind)
		check(group.size()==4 and group.filter(func(c): return c.shiny).size()==1,"Four residents and one shiny in "+kind.habitat)
		for c in group:
			if c.friend:
				continue
			await walk_to(c.home+Vector3(0.4,0,0.9))
			await ticks(2)
			check(game.hud.target==c,"Found "+c.nickname+" at home")
			await tap_key(KEY_SPACE)
			await solve_quiz(c)
			check(c.friend and not c.following,"New friend rests when five are following")
			if c.shiny and kind==game.SPECIES[4]:
				await capture("shiny-etherflutter")
	check(game.finds.pennants.all(func(flag): return flag.visible),"Five species pennants earned for the cottage")
	check(game.hud.counter_text()=="20/20" and party().size()==5,"All 20 residents befriended")
	await tap_key(KEY_TAB)
	await tap_key(KEY_W)
	await tap_key(KEY_SPACE)
	check(party().size()==5 and game.guidebook.notice!="","Full team asks for a free place")
	await tap_key(KEY_S)
	await tap_key(KEY_SPACE)
	await tap_key(KEY_W)
	await tap_key(KEY_SPACE)
	check(game.creatures[15].following and not game.creatures[0].following,"Shiny replaces an individual companion")
	await capture("field-guide")
	for page in 5:
		for r in 4:
			var resident: Node3D = game.guidebook.on_page()[game.guidebook.row]
			if resident.following:
				await tap_key(KEY_SPACE)
			await tap_key(KEY_S)
		await tap_key(KEY_D)
	check(party().is_empty() and game.hud.counter_text()=="20/20","All companions can rest without losing friendship")
	await tap_key(KEY_TAB)

func check_cottage() -> void:
	var shiny: Node3D = game.creatures[15]
	var other: Node3D = game.creatures[1]
	game.toggle_follow(shiny)
	game.toggle_follow(other)
	var expected := [shiny.nickname,other.nickname]
	await walk_to(game.land.PORCH)
	await ticks(3)
	check(game.hud.at_cottage,"Porch prompt appears at the cottage")
	await tap_key(KEY_SPACE)
	check(game.hud.cottage_text.begins_with("Slaap lekker"),"Tucking in confirms a successful save")
	await capture("cottage-save")
	game.toggle_follow(shiny)
	game.queue_free()
	await process_frame
	await process_frame
	start_island()
	await ticks(2)
	check(game.hud.at_cottage and game.hud.counter_text()=="20/20","New session starts at the cottage with all 20 friends")
	check(party().size()==2 and party().all(func(c): return c.nickname in expected),"Saved shiny and companion follow again")
	check(game.creatures[0].friend and not game.creatures[0].following,"Resting friend stays in its habitat")
	check(game.finds.found.size()==5,"All treasures survive a restart")
	check(game.finds.pennants.all(func(flag): return flag.visible),"Cottage pennants return after loading")
	check(game.outings.rainbow.visible and game.outings.flying,"Rainbow and flying kite survive reopening")
	check(game.teamwork.notes.count(true)==3 and game.teamwork.delivered==2,"Teamwork rewards survive reopening")
	check(game.beach.home,"Turtles remember their trip to the sea")
	check(game.sky_book.album.size()==3,"Star drawings survive a restart")
	check(game.wonders.stamps.size()==5 and game.wonders.compass.visible,"Discovery passport survives a restart")
	await tap_key(KEY_TAB)
	await tap_key(KEY_CTRL)
	check(game.quiz.visible and game.quiz.resident.nickname=="Pip","Saved friends can practise again")
	if game.quiz.visible:
		for j in game.quiz.cards.size():
			var card: Dictionary = game.quiz.cards[j]
			while game.quiz.selected!=card.choices.find(card.answer):
				await tap_key(KEY_S)
			await tap_key(KEY_SPACE)
	check(game.hud.counter_text()=="20/20" and party().size()==2 and game.guidebook.visible,"Practice preserves the team and friendships")
	await tap_key(KEY_TAB)
	var old := FileAccess.open(checkpoint_path,FileAccess.WRITE)
	old.store_string(JSON.stringify({"version":1,"friends":["Dew","Ruby"],"party":["Ruby"]}))
	old.close()
	game.queue_free()
	await process_frame
	await process_frame
	start_island()
	await ticks(2)
	check(game.hud.counter_text()=="2/20" and party().size()==1 and party()[0].nickname=="Ruby","Original cottage saves keep the same friends")
	check(game.teamwork.notes.count(true)==0 and game.teamwork.delivered==0,"Older saves can start both team adventures")
	check(not game.outings.rainbow.visible and game.outings.collected.count(true)==0,"Older saves can discover both outings")
	check(game.finds.found.is_empty() and game.wonders.stamps.is_empty() and game.sky_book.album.is_empty() and not game.beach.home,"New discoveries start available with an old save")
	await check_emberflame()
	DirAccess.remove_absolute(checkpoint_path)

func check_emberflame() -> void:
	var ports: Array = game.Ember.PORTS
	game.pads.install(TEST_PAD,false)
	check(not game.land.accessible(ports[0].lerp(ports[1],0.5)),"The sea separates the two islands")
	await walk_to(ports[0])
	await tap_key(KEY_SPACE)
	check(game.island_id==1 and game.hud.counter_text()=="0/20","Boarded for Emberflame")
	check(party().all(func(c): return c.position.distance_to(game.player.position)<7),"Companions arrive on the same ferry")
	for i in range(20,40):
		var c: Node3D = game.creatures[i]
		var rank := (i-20)%4+1
		check(c.level==rank and c.shiny==(rank==4) and c.species.display_name==game.ember.pages[(i-20)/4].display_name,"Habitat species, rank and shiny for "+c.nickname)
		var cell := Vector2i(roundi(c.home.x*2),roundi(c.home.z*2))
		var start := Vector2i(roundi(game.player.position.x*2),roundi(game.player.position.z*2))
		check(not game.grid.get_point_path(start,cell).is_empty(),"Reachable resident "+c.nickname)
	await walk_to(game.creatures[20].home)
	await tap_key(KEY_SPACE)
	await solve_quiz(game.creatures[20])
	check(not game.ember.eruption_seen,"Volcano discovery starts hidden")
	await walk_to(game.Ember.CENTER+game.Ember.PEAKS[0]+Vector3(0,0,11))
	check(game.ember.eruption_seen and not game.ember.eruption_armed,"Approaching Fire Ridge triggers the eruption")
	check(game.checkpoint.read().outings.get("eruption_seen")==true,"Volcano discovery automatically saved")
	await tap_key(KEY_TAB)
	await tap_key(KEY_SHIFT)
	check(game.guidebook.map_open and game.guidebook.on_page().size()==4,"Emberflame guide and map open")
	check(game.guidebook.species==game.ember.pages,"Guide only contains Emberflame habitats")
	await capture("emberflame-kaart")
	await tap_key(KEY_TAB)
	for i in game.Ember.SITES.size():
		await walk_to(game.Ember.CENTER+game.Ember.SITES[i])
		await tap_key(KEY_SPACE)
		check(game.Ember.SITE_NAMES[i] in game.ember.discovered,"Interacted with "+game.Ember.SITE_NAMES[i])
		if i==1:
			check(game.player.position.y>2,"Climbed the crystal terrace")
	game.queue_free()
	await process_frame
	await process_frame
	start_island()
	await ticks(3)
	check(game.ember.discovered.size()==4,"Four new discoveries survive restart")
	check(game.ember.eruption_seen,"Volcano discovery survives restart")
	check(game.island_id==1 and game.hud.counter_text()=="1/20" and game.creatures[20].following,"Emberflame friendships and landing survive restart")
	game.pads.install(TEST_PAD,false)
	await walk_to(ports[1])
	await tap_key(KEY_SPACE)
	check(game.island_id==0 and game.hud.counter_text()=="2/20" and game.creatures[20].visible,"Return ferry brings the new friend home")
	await tap_key(KEY_TAB)
	check(game.guidebook.species==game.SPECIES,"Guide only contains Vareneiland habitats")
	await tap_key(KEY_SHIFT)
	await tap_key(KEY_SPACE)
	check(game.island_id==1 and not game.guidebook.visible and game.creatures[20].following,"Map travel switches island with companions")

func solve_quiz(c: Node3D, offer := -1) -> void:
	check(game.quiz.visible and not c.friend,"Meeting starts a quiz for "+c.nickname)
	if not game.quiz.visible:
		return
	var count := 5 if c.shiny else 3
	check(game.quiz.cards.size()==count,"Right number of questions")
	var first: Dictionary = game.quiz.cards[0]
	var wrong: int = (first.choices.find(first.answer)+1)%3
	for j in wrong:
		await tap_key(KEY_S)
	await tap_key(KEY_SPACE)
	check(game.quiz.index==0 and not c.friend and not game.quiz.missed.is_empty(),"Wrong answer allows another try")
	if c.shiny and c.species.theme=="Vlaggen":
		await capture("vlaggenproef")
	for j in count:
		var card: Dictionary = game.quiz.cards[j]
		var target: int = card.choices.find(card.answer)
		while game.quiz.selected!=target:
			await tap_key(KEY_S)
		check(not c.friend,"Friendship waits until the last answer")
		if offer>=0:
			await tap_button(offer)
		else:
			await tap_key(KEY_SPACE)
	check(not game.quiz.visible and c.friend,"Quiz completed")
	check(c.save_id in game.checkpoint.read().friends,"Friendship automatically saved")

func check_treasures() -> void:
	for id in 5:
		await walk_to(game.wonders.PLACES[id])
		await ticks(2)
		check(game.hud.wonder_action!="","Discovery has an action prompt")
		await tap_key(KEY_SPACE)
		check(id in game.wonders.stamps and game.wonders.active==id,"Earned a discovery stamp")
	check(game.wonders.compass.visible,"Five stamps reveal the golden compass")
	await tap_key(KEY_TAB)
	await tap_key(KEY_SHIFT)
	check(game.guidebook.map_open,"Field guide opens the island map")
	await capture("eilandkaart")
	await tap_key(KEY_TAB)
	for kind in game.SPECIES:
		await walk_to(kind.relic_position)
		await ticks(2)
		check(kind.theme in game.finds.found,"Found "+kind.relic)
	check(game.checkpoint.read().treasures.size()==5,"Five treasures automatically saved")
	await walk_to(game.finds.PEAK+Vector3(0,0,1.65))
	check(game.player.position.y>5.9,"Walked to the top of the hill")
	await capture("sterrenheuvel")
	await tap_key(KEY_SPACE)
	check(game.sky_book.visible and game.sky_book.treasures==5,"Summit telescope unlocks the meteor shower")
	await tap_key(KEY_D)
	check(game.sky_book.planet==3,"Turned telescope toward Mars")
	await capture("sterrenkijker")
	await tap_key(KEY_SHIFT)
	check(game.sky_book.charts,"Opened the star drawing book")
	await tap_key(KEY_D)
	await tap_key(KEY_SPACE)
	check(game.sky_book.connected==0,"Child can retry a star in the wrong order")
	for chart in 3:
		for j in game.sky_book.points().size():
			for attempt in game.sky_book.points().size():
				if game.sky_book.star==j:
					break
				await tap_key(KEY_D)
			await tap_key(KEY_SPACE)
		check(game.sky_book.connected==game.sky_book.points().size(),"Connected all stars in "+str(game.sky_book.CHARTS[chart][0]))
		if chart==0:
			await capture("sterrenboek")
		await tap_key(KEY_SPACE)
	check(game.checkpoint.read().charts.size()==3,"Three star pictures saved")
	await tap_key(KEY_TAB)

func test_question_bank() -> void:
	var book := preload("res://scripts/questions.gd")
	for kind: String in book.bank:
		for level in range(1,5):
			var valid := true
			for attempt in 30:
				var count := 5 if level==4 else 3
				var topics := {}
				var seen := {}
				var deck: Array = book.deck(kind,level,count)
				valid = valid and deck.size()==count
				for card: Dictionary in deck:
					var identity: String = card.flag[0] if card.has("flag") else card.q
					valid = valid and not seen.has(identity)
					seen[identity] = true
					valid = valid and card.choices.size()==3 and card.choices.count(card.answer)==1
					valid = valid and card.choices[0]!=card.choices[1] and card.choices[1]!=card.choices[2] and card.choices[0]!=card.choices[2]
					if card.has("som"):
						var parts: PackedStringArray = card.q.split(" ")
						var x := int(parts[0])
						var y := int(parts[2])
						var answer := int(card.answer)
						topics[parts[1]] = true
						match parts[1]:
							"+": valid = valid and answer==x+y
							"−": valid = valid and answer==x-y and answer>=0
							"×": valid = valid and answer==x*y
							"÷": valid = valid and y>0 and answer*y==x
				if kind in ["Flamelingo","CycloVolt"]:
					valid = valid and topics.size()==2
			check(valid,"Reviewed choices and answers for "+kind+" level "+str(level))

func check_beach() -> void:
	await walk_to(game.beach.NEST)
	await tap_key(KEY_SPACE)
	check(game.beach.active and not game.beach.eggs.visible,"Three young turtles hatch")
	await walk_to(game.beach.NEST+Vector3(0,0,-5.9))
	await ticks(12)
	var paused: float = game.beach.progress
	await ticks(28)
	check(is_equal_approx(game.beach.progress,paused),"Turtles wait for the explorer")
	for j in range(1,9):
		var p: Vector3 = game.beach.route(j*0.09)
		await walk_to(p+Vector3(0.6,0,0))
		await ticks(48)
		if j==4:
			await capture("schildpadstrand")
	await ticks(60)
	check(game.beach.home and game.checkpoint.read().get("turtles")==true,"Turtle journey automatically saved")

func check_outings() -> void:
	var out = game.outings
	await walk_to(out.CAMP)
	await tap_key(KEY_SPACE)
	check(not out.flying and game.hud.cottage_text.contains("strikken"),"Kite shows its missing tail")
	for i in [2,0,1]:
		await walk_to(out.BOWS[i])
		await tap_key(KEY_SPACE)
		check(out.tails[i].visible and not out.bows[i].visible,"Found and attached a kite bow")
	game.toggle_follow(game.creatures[0])
	await walk_to(out.CAMP)
	await tap_key(KEY_SPACE)
	await walk_to(out.CAMP+Vector3(3,0,4))
	await ticks(40)
	var hand: Vector3 = game.creatures[0].model.global_position
	check(out.flying and out.string.visible and out.kite.position.distance_to(hand)<5,"Companion carries the kite on a walk")
	await frame_habitat(0.39)
	await capture("vliegerwei")
	await walk_to(out.CAMP)
	await tap_key(KEY_SPACE)
	check(not out.flying and not out.string.visible,"Can reel the kite in")
	await tap_key(KEY_SPACE)
	game.toggle_follow(game.creatures[0])
	for i in [1,2,0]:
		await walk_to(out.SPRING+out.PRISMS[i])
		for attempt in 4:
			if out.turns[i]==0:
				break
			await tap_key(KEY_SPACE)
		check(out.turns[i]==0,"Light aimed at the spring")
	check(out.rainbow.visible and game.checkpoint.read().outings.turns.all(func(value): return value==0),"Rainbow appears and saves")
	await walk_to(out.SPRING+Vector3(0,0,3.2))
	await frame_habitat()
	await capture("regenboogbron")

func check_helpers() -> void:
	var tasks = game.teamwork
	await walk_to(tasks.POST+Vector3.FORWARD)
	await tap_key(KEY_SPACE)
	check(not tasks.carrying and game.hud.cottage_text.contains("vriend"),"Post needs an actual travelling friend")
	var pip: Node3D = game.creatures[0]
	var dew: Node3D = game.creatures[1]
	game.toggle_follow(pip)
	game.toggle_follow(dew)
	for i in range(2,5):
		game.toggle_follow(game.creatures[i])
	await tap_key(KEY_SPACE)
	await ticks(10)
	check(tasks.carrying and tasks.letter.position.distance_to(pip.model.global_position)<0.8,"Pip carries the stamped envelope")
	check(game.checkpoint.read().outings.teamwork.carrying==true,"Unfinished postal trip is saved")
	await walk_to(tasks.BOXES[1]+Vector3.BACK)
	await tap_key(KEY_SPACE)
	check(tasks.delivered==0 and tasks.carrying,"Wrong address keeps the letter")
	game.toggle_follow(pip)
	for i in 2:
		if i:
			await walk_to(tasks.POST+Vector3.FORWARD)
			await tap_key(KEY_SPACE)
		await walk_to(tasks.BOXES[i]+Vector3(1.3,0,0.7))
		await tap_key(KEY_SPACE)
		check(tasks.helper==dew,"Active companion takes the delivery job")
		for frame in 480:
			if tasks.near_time>=0.45:
				break
			await ticks(1)
		check(dew.model.position.y>dew.species.hover_height+0.5,"Companion lifts the letter to the high mailbox")
		if i==0:
			await capture("vogelpost")
		await ticks(100)
		check(tasks.delivered==i+1 and not tasks.carrying and tasks.flags[i].visible,"Bird receives its own letter")
	for i in [2,0,1]:
		await walk_to(tasks.BELLS[i]+Vector3.BACK*0.8)
		await tap_key(KEY_SPACE)
		if i==2:
			game.toggle_follow(dew)
			for j in range(2,5):
				game.toggle_follow(game.creatures[j])
			await ticks(60)
			check(not tasks.notes[i] and not tasks.helper,"Resting friend cannot play a remote echo")
			game.toggle_follow(dew)
			await tap_button(JOY_BUTTON_B)
		for frame in 480:
			if not tasks.helper:
				break
			await ticks(1)
		check(tasks.notes[i] and tasks.birds[i].visible,"Companion reaches the drum and answers the bell")
	await frame_habitat(0.40)
	await capture("echobos")
	check(game.checkpoint.read().outings.teamwork.delivered==2,"Completed deliveries autosaved")
	game.toggle_follow(dew)
