extends Node3D

const S = preload("res://scripts/shapes.gd")
const NAMES := ["Vuurvliegjes","Zingende schelpen","Springstenen","Windbloemen","Vlinderdans"]
const ACTIONS := ["Roep de lichtjes","Speel een liedje","Laat ze springen","Roep de wind","Lok de vlinders"]
const PLACES := [Vector3(10,0,7),Vector3(-32,0,-12),Vector3(-4,0,-32),Vector3(35,0,-15),Vector3(-20,0,25)]
var hosts: Array[Node3D] = []
var moving: Array = []
var stamps: Array = []
var active := -1
var age := 0.0
var tune := AudioStreamPlayer3D.new()
var song: AudioStreamWAV
var compass: Node3D

func build(land: Node3D) -> void:
	for i in PLACES.size():
		var base: Vector3 = PLACES[i]
		var host := S.group(self,base)
		hosts.append(host)
		var pieces := []
		moving.append(pieces)
		land.flat_disc(host,Vector3.UP*0.075,2.2,1.72,["d4c689","afdac7","b69c95","d1cf89","dbbcd0"][i])
		var label := Label3D.new()
		label.text = NAMES[i]
		label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		label.pixel_size = 0.006
		label.font_size = 37
		label.outline_size = 7
		label.position = Vector3(0,1.76,-1.55)
		host.add_child(label)
		for j in (14 if i==0 else 7):
			var angle := TAU*j/(14 if i==0 else 7)
			var p := Vector3(1.42*cos(angle),0,1.1*sin(angle))
			var part := S.group(host,p)
			pieces.append(part)
			match i:
				0:
					S.ball(part,Vector3.ZERO,Vector3.ONE*0.092,"fff29a",8)
					part.position.y = 0.8+0.3*sin(angle*2)
				1:
					part.rotation.y = -angle
					S.ball(part,Vector3.ZERO,Vector3(0.34,0.17,0.46),["fac99f","efa89b","ffc98b"][j%3])
					for k in 4:
						var tip := Vector3((k-1.5)*0.133,0.09,0.24)
						S.tube(part,Vector3(0,0.12,-0.29),tip,0.018,0.035,"ffe5ba")
				2:
					S.ball(part,Vector3.ZERO,Vector3(0.36,0.32,0.31),"7e687b",7)
					S.ball(part,Vector3(0,0.2,0),Vector3(0.15,0.15,0.15),"ffb663",7)
				3:
					S.tube(host,p,p+Vector3.UP*0.98,0.046,0.031,"679263")
					part.position.y = 0.98
					for k in 6:
						var b := TAU*k/6
						var petal := S.ball(part,Vector3(cos(b)*0.22,sin(b)*0.22,0),Vector3(0.18,0.09,0.047),"ffe08a")
						petal.rotation.z = b+0.42
					S.ball(part,Vector3.ZERO,Vector3.ONE*0.11,"af754f")
				4:
					var wing_color: String = ["e68aa6","e8b45a","8cbdfa"][j%3]
					for side in [-1,1]:
						var wing := S.ball(part,Vector3(side*0.15,0.08,0),Vector3(0.15,0.21,0.045),wing_color)
						wing.rotation.z = -side*0.5
					S.ball(part,Vector3.ZERO,Vector3(0.038,0.13,0.043),"725869")
	add_child(tune)
	tune.max_distance = 20
	song = shell_song()
	compass = S.group(self,Vector3(6.65,1.2,-4.3))
	S.ball(compass,Vector3.ZERO,Vector3(0.36,0.36,0.1),"f4cc69")
	S.ball(compass,Vector3(0,0,0.08),Vector3(0.28,0.28,0.06),"4b9092")
	var needle := S.box(compass,Vector3(0,0,0.15),Vector3(0.065,0.41,0.04),"ffe5ad")
	needle.rotation.z = -0.4
	compass.hide()

func shell_song() -> AudioStreamWAV:
	var audio := AudioStreamWAV.new()
	audio.mix_rate = 22050
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	var notes := [523.25,659.25,783.99,1046.5,880.0,659.25,783.99]
	var samples := PackedByteArray()
	samples.resize(2*22050*3)
	for i in samples.size()/2:
		var sec := i/22050.0
		var note := mini(floori(sec/0.36),6)
		var local := sec-note*0.36
		var wave := sin(local*TAU*notes[note])+0.25*sin(local*TAU*notes[note]*2)
		samples.encode_s16(i*2,roundi(wave*minf(1,local*70)*exp(-local*8)*7800))
	audio.data = samples
	return audio

func nearest(foot: Vector3) -> int:
	for i in PLACES.size():
		if foot.distance_squared_to(PLACES[i])<5.0:
			return i
	return -1

func stamp(id: int) -> void:
	if id>=0 and id<NAMES.size() and id not in stamps:
		stamps.append(id)
	compass.visible = stamps.size()==NAMES.size()

func play(id: int) -> void:
	active = id
	age = 0
	stamp(id)
	if id==1:
		tune.position = PLACES[id]+Vector3.UP
		tune.stream = song
		tune.play()

func animate(dt: float, t: float) -> void:
	age += dt
	for i in moving.size():
		var strength := clampf(minf(age*2,(7.0-age)*1.5),0,1) if active==i else 0.0
		for j in moving[i].size():
			var part: Node3D = moving[i][j]
			var a: float = TAU*j/moving[i].size()
			match i:
				0:
					var heart := Vector3(1.40*pow(sin(a),3),1.96+0.085*(13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a)),0)
					var rest := Vector3(1.44*cos(a+t*0.28),0.95+0.34*sin(t+j),1.1*sin(a+t*0.28))
					part.position = rest.lerp(heart,strength)
				1:
					part.position.y = 0.2+strength*0.6*maxf(0,1-absf(age-j*0.36)*4)
				2:
					part.position.y = 0.22+strength*1.6*pow(maxf(0,sin(age*4-j*0.84)),2)
				3:
					part.rotation.z += dt*(0.35+strength*(5+j*0.24))
				4:
					part.position = Vector3(cos(a+t*0.28)*(1.25+strength),0.72+sin(t*2+j)*0.22+strength*1.3,sin(a+t*0.28)*(0.9+strength))
					part.rotation.y = -a-t*0.28
					part.scale.x = 0.70+0.26*sin(t*(8+strength*4)+j)
