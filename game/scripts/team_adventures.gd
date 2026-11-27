extends Node3D

signal milestone(message: String)
const S = preload("res://scripts/shapes.gd")
const BELLS := [Vector3(-14,0,14),Vector3(-12,0,16),Vector3(-10,0,14)]
const DRUM := Vector3(-12,0,10)
const POST := Vector3(9,0,-17)
const BOXES := [Vector3(18,0,-20),Vector3(-3,0,-22)]
const BOX_NAMES := ["Zonnehuis","Maanhuis"]
const COLORS := ["ec9b72","edc561","7fc9b7"]

var notes := [false,false,false]
var delivered := 0
var carrying := false
var helper: Node3D
var job := ""
var goal := Vector3.ZERO
var struck := false
var chirp_delay := -1.0
var chirp_id := 0
var chirp_at := Vector3.ZERO
var near_time := 0.0
var stop_anchor := Vector3.ZERO
var bells: Array[Node3D] = []
var birds: Array[Node3D] = []
var flags: Array[Node3D] = []
var drum_skin: Node3D
var letter: Node3D
var post_sign: Label3D
var echo_sign: Label3D
var sounds: Array[AudioStreamWAV] = []
var voice := AudioStreamPlayer3D.new()
var beat := 0.0
var last_bell := -1

func build(land: Node3D) -> void:
	add_child(voice)
	voice.unit_size = 8
	for i in 3:
		sounds.append(tone([392.0,493.88,587.33][i],false))
	for i in 3:
		sounds.append(tone([196.0,246.94,293.66][i],true))
	land.flat_disc(self,DRUM+Vector3(0,0.05,2.1),4.15,3.9,"d7c19a")
	S.tube(self,DRUM,DRUM+Vector3.UP*0.82,0.56,0.71,"b98167",12)
	drum_skin = S.tube(self,DRUM+Vector3.UP*0.81,DRUM+Vector3.UP*0.90,0.74,0.74,"f3dbb2",12)
	for i in 10:
		var a := TAU*i/10
		S.tube(self,DRUM+Vector3(sin(a)*0.56,0.07,cos(a)*0.56),DRUM+Vector3(sin(a+0.23)*0.71,0.8,cos(a+0.23)*0.71),0.024,0.024,"f7c979")
	echo_sign = sign_at(DRUM+Vector3(0,2.6,-1.1),"Het echobos")
	for i in 3:
		var p: Vector3 = BELLS[i]
		S.tube(self,p+Vector3(-0.45,0,0),p+Vector3(-0.45,1.62,0),0.083,0.071,"927455")
		S.tube(self,p+Vector3(-0.51,1.58,0),p+Vector3(0.4,1.58,0),0.069,0.069,"a28862")
		var bell := S.group(self,p+Vector3.UP*1.55)
		bells.append(bell)
		S.tube(bell,Vector3.DOWN*0.65,Vector3.DOWN*0.19,0.35,0.12,COLORS[i],10)
		S.tube(bell,Vector3.DOWN*0.22,Vector3.ZERO,0.025,0.025,"856d54")
		S.ball(bell,Vector3.DOWN*0.69,Vector3.ONE*0.095,"c39555")
		birds.append(make_bird(DRUM+Vector3((i-1)*0.94,1.25,-1.25),COLORS[i]))
		S.tube(self,DRUM+Vector3((i-1)*0.94,0,-1.25),DRUM+Vector3((i-1)*0.94,1.23,-1.25),0.09,0.067,"94785a")
	S.box(self,POST+Vector3.UP*0.62,Vector3(1.4,1.22,0.77),"5faba9")
	S.box(self,POST+Vector3.UP*1.30,Vector3(1.63,0.17,0.97),"eabb77")
	post_sign = sign_at(POST+Vector3.UP*2.1,"Vogelpost")
	letter = S.group(self)
	S.box(letter,Vector3.ZERO,Vector3(0.80,0.51,0.08),"fff1bd")
	for side in [-1,1]:
		S.tube(letter,Vector3(side*0.38,0.22,0.05),Vector3(0,-0.04,0.05),0.019,0.019,"ab8767")
	S.ball(letter,Vector3(0,-0.05,0.06),Vector3(0.080,0.078,0.025),"e57c61")
	for i in 2:
		var p: Vector3 = BOXES[i]
		S.tube(self,p,p+Vector3.UP*2.75,0.26,0.18,"9a7852",9)
		S.ball(self,p+Vector3(0.7,3.55,-0.3),Vector3(1.35,0.85,1.04),"89bd71",9)
		S.ball(self,p+Vector3(-0.7,3.46,-0.4),Vector3(1.10,0.73,0.94),"74ae78",9)
		S.box(self,p+Vector3.UP*2.58,Vector3(1.02,0.86,0.78),["e3ad62","789ab7"][i])
		for side in [-1,1]:
			var roof := S.box(self,p+Vector3(side*0.31,3.10,0),Vector3(0.79,0.13,0.99),"ae6d53")
			roof.rotation.z = -side*0.36
		S.ball(self,p+Vector3(0,2.69,0.40),Vector3(0.18,0.18,0.035),"554c43")
		S.box(self,p+Vector3(0,2.36,0.41),Vector3(0.55,0.063,0.055),"675345")
		flags.append(make_bird(p+Vector3(0.8,3.92,0),COLORS[i]))
		sign_at(p+Vector3(0,1.68,0.5),BOX_NAMES[i])
		for j in 5:
			var spot := POST.lerp(p,(j+1)/6.0)+Vector3.UP*0.06
			S.ball(self,spot,Vector3(0.20,0.075,0.16),["e9bc6d","96bbd7"][i],7)
	refresh()

func sign_at(at: Vector3, title: String) -> Label3D:
	var tag := Label3D.new()
	add_child(tag)
	tag.position = at
	tag.text = title
	tag.font_size = 36
	tag.pixel_size = 0.007
	tag.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	tag.outline_size = 7
	return tag

func make_bird(at: Vector3, color: String) -> Node3D:
	var bird := S.group(self,at)
	S.ball(bird,Vector3.UP*0.21,Vector3(0.24,0.23,0.31),color,9)
	S.ball(bird,Vector3(0,0.49,0.13),Vector3.ONE*0.19,color,9)
	for side in [-1,1]:
		S.ball(bird,Vector3(side*0.106,0.52,0.26),Vector3.ONE*0.034,"443c40")
		S.ball(bird,Vector3(side*0.21,0.23,-0.03),Vector3(0.067,0.13,0.21),"b98172")
	S.tube(bird,Vector3(0,0.45,0.27),Vector3(0,0.44,0.46),0.077,0.007,"edb153",5)
	return bird

func tone(hz: float, drum: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = 22050
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	var data := PackedByteArray()
	data.resize(22050)
	for i in 11025:
		var t := i/22050.0
		var wave := sin(TAU*hz*t)+0.21*sin(TAU*hz*t*(1.52 if drum else 2.87))
		data.encode_s16(i*2,int(8500*wave*minf(1,t*90)*exp(-t*(11 if drum else 7))*minf(1,(0.5-t)*60)))
	wav.data = data
	return wav

func nearby(foot: Vector3) -> String:
	for i in 3:
		if foot.distance_to(BELLS[i])<1.55:
			return "bell"+str(i)
	if foot.distance_to(POST)<2:
		return "post"
	for i in 2:
		if foot.distance_to(BOXES[i])<2:
			return "box"+str(i)
	return ""

func prompt(action: String) -> String:
	if action.begins_with("bell"):
		return "Speel samen"
	return "Kijk bij de post" if action=="post" else "Geef de brief"

func play_note(id: int, at: Vector3) -> void:
	voice.position = at
	voice.stream = sounds[id]
	voice.play()

func interact(action: String, friend: Node3D, foot: Vector3) -> String:
	if helper:
		return helper.nickname+" is bezig!"
	if action=="post" and delivered==2:
		return "Beide vogels hebben hun brief!"
	if not friend:
		return "Neem een vriend mee uit je eilandboek!"
	if action=="post":
		if not carrying:
			carrying = true
			refresh()
			milestone.emit(friend.nickname+" draagt de brief. Zoek het "+BOX_NAMES[delivered]+".")
			return ""
		return "Volg de "+("gele" if delivered==0 else "blauwe")+" stenen naar het "+BOX_NAMES[delivered]+"."
	if action.begins_with("box"):
		if delivered>=2 or int(action.right(1))<delivered:
			return "De vogel heeft zijn post al!"
		if not carrying:
			return "Haal samen een brief bij de Vogelpost."
		if int(action.right(1))!=delivered:
			return "Deze brief is voor het "+BOX_NAMES[delivered]+"."
		goal = BOXES[delivered]+Vector3(0,0,0.76)
	else:
		last_bell = int(action.right(1))
		play_note(last_bell,BELLS[last_bell])
		goal = DRUM+Vector3(0,0,0.69)
	helper = friend
	job = action
	stop_anchor = foot
	near_time = 0
	struck = false
	return helper.nickname+(" brengt de brief omhoog!" if action.begins_with("box") else " speelt de echo!")

func animate(dt: float, time: float, foot: Vector3, carrier: Node3D) -> void:
	if chirp_delay>=0:
		chirp_delay -= dt
		if chirp_delay<0:
			play_note(chirp_id,chirp_at)
	beat = maxf(0,beat-dt)
	drum_skin.scale.y = 0.09*(1+beat)
	if last_bell>=0:
		bells[last_bell].rotation.z = sin(time*14)*0.20 if helper and job.begins_with("bell") else 0.0
	if helper:
		if not helper.following or stop_anchor.distance_to(foot)>12:
			helper = null
			job = ""
		elif helper.position.distance_to(goal)<0.95:
			near_time += dt
			var lift := sin(PI*minf(near_time,1))
			if job.begins_with("box"):
				helper.model.position.y += lift*maxf(0.6,2.36-helper.species.hover_height)
			else:
				helper.model.position.y += lift*0.49
			if not struck and near_time>=0.53:
				struck = true
				chirp_delay = 0.32
				chirp_at = goal
				chirp_id = (last_bell+1)%3
				var who: String = helper.nickname
				if job.begins_with("box"):
					delivered += 1
					carrying = false
					refresh()
					milestone.emit("Post bezorgd! "+("Nog een brief bij de Vogelpost." if delivered==1 else "Beide vogels zingen voor jullie!"))
					play_note(delivered,goal)
				else:
					notes[last_bell] = true
					beat = 0.46
					play_note(last_bell+3,DRUM)
					refresh()
					milestone.emit("Een vogel voor elke bel. Het koor is compleet!" if notes.count(true)==3 else who+" trommelt! Een vogel zingt mee.")
			if near_time>=1.0:
				helper = null
				job = ""
	var holder := helper if helper and job.begins_with("box") else carrier
	letter.visible = carrying or delivered<2
	if carrying and holder:
		letter.position = holder.model.global_position+Vector3(0.33,0.24,0.31)
		if job.begins_with("box") and helper:
			letter.position = letter.position.lerp(BOXES[delivered]+Vector3(0,2.36,0.46),smoothstep(0.24,0.53,near_time))
	else:
		letter.position = POST+Vector3(0,1.65+0.06*sin(time*2),0)
	letter.rotation.z = 0.1*sin(time*2)
	for i in 3:
		birds[i].rotation.z = 0.10*sin(time*4+i)

func refresh() -> void:
	for i in 3:
		birds[i].visible = notes[i]
	for i in 2:
		flags[i].visible = delivered>i
	post_sign.text = "Vogelpost" if delivered<2 else "Vogelpost · Alles bezorgd!"
	echo_sign.text = "Het echobos" if notes.count(true)<3 else "Het vogelkoor"

func snapshot() -> Dictionary:
	return {"notes":notes,"delivered":delivered,"carrying":carrying}

func restore(data: Dictionary) -> void:
	var saved: Variant = data.get("notes")
	if saved is Array and saved.size()==3:
		for i in 3:
			notes[i] = saved[i]==true
	var count: Variant = data.get("delivered")
	if count is int or count is float:
		delivered = clampi(int(count),0,2)
	carrying = delivered<2 and data.get("carrying")==true
	refresh()
