extends Control
signal closed
signal chart_found(title: String)
# Points in connecting order. The pan is the familiar seven-star part of Ursa Major.
const CHARTS := [
	["De Steelpan",[Vector2(-220,-48),Vector2(-135,-62),Vector2(-70,-13),Vector2(0,3),Vector2(141,-28),Vector2(119,67),Vector2(16,77)]],
	["Cassiopeia",[Vector2(-205,-65),Vector2(-108,60),Vector2(-15,-39),Vector2(82,67),Vector2(193,-68)]],
	["Mijn ruimteraket",[Vector2(0,-117),Vector2(66,-20),Vector2(65,65),Vector2(126,111),Vector2(45,98),Vector2(-45,98),Vector2(-126,111),Vector2(-65,65),Vector2(-66,-20)]]
]
var charts := false
var chart := 0
var star := 0
var connected := 0
var notice := ""
var album: Array = []
const NAMES := ["Mercurius","Venus","Aarde","Mars","Jupiter","Saturnus","Uranus","Neptunus"]
const COLORS := ["c3aa93","e9b264","52aac4","de795e","dca77b","edd295","8cdad4","6387d8"]
const FACTS := ["Dit is de kleinste planeet. Hij staat dicht bij de zon.","Een dikke deken van wolken houdt Venus heet.","Dit is ons thuis. De blauwe plekken zijn zeeën.","Mars is rood door roest in zijn stof en stenen.","Dit is de grootste planeet. De rode vlek is een storm.","De ringen bestaan uit heel veel stukjes ijs en steen.","Uranus draait op zijn zij. Wat een koprol!","Hier waait het heel hard. De zon is ver weg."]
var planet := 2
var treasures := 0
var using_pad := false
var solo := false
var time := 0.0
var pill := StyleBoxFlat.new()
var font := ThemeDB.fallback_font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pill.bg_color = Color("#345867")
	pill.set_corner_radius_all(23)
	hide()

func open(count: int, pad: bool, single: bool) -> void:
	treasures = count
	using_pad = pad
	solo = single
	planet = 2
	charts = false
	reset_chart(0)
	show()
	queue_redraw()

func navigate() -> void:
	if Input.is_action_just_pressed("journal") or (Input.is_key_pressed(KEY_ESCAPE) and Input.is_action_just_pressed("ui_cancel")):
		closed.emit()
		return
	if Input.is_action_just_pressed("hop"):
		charts = not charts
		return
	var step := int(Input.is_action_just_pressed("east") or Input.is_action_just_pressed("ui_right"))-int(Input.is_action_just_pressed("west") or Input.is_action_just_pressed("ui_left"))
	if charts:
		if step:
			var order := range(points().size())
			order.sort_custom(func(a,b): return points()[a].x<points()[b].x)
			star = order[posmod(order.find(star)+step,order.size())]
		if Input.is_action_just_pressed("offer"):
			join_star(star)
	elif Input.is_action_just_pressed("offer"):
		closed.emit()
	else:
		planet = posmod(planet+step,8)

func points() -> Array:
	return CHARTS[chart][1]

func reset_chart(id: int) -> void:
	chart = id
	connected = 0
	star = 0
	notice = ""

func join_star(id: int) -> void:
	if connected==points().size():
		reset_chart((chart+1)%CHARTS.size())
	elif id==connected:
		connected += 1
		notice = ""
		if connected==points().size() and CHARTS[chart][0] not in album:
			chart_found.emit(CHARTS[chart][0])
	else:
		notice = "Zoek ster %d." % (connected+1)

func switch_rect() -> Rect2:
	return Rect2(size.x-304,28,274,52)

func star_position(i: int) -> Vector2:
	return size*Vector2(0.5,0.46)+points()[i]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		accept_event()
		if switch_rect().has_point(event.position):
			charts = not charts
		elif event.position.y>size.y-65:
			closed.emit()
		elif charts:
			if connected==points().size():
				join_star(0)
			else:
				for i in points().size():
					if event.position.distance_to(star_position(i))<32:
						star = i
						join_star(i)
						break
		else:
			planet = posmod(planet+(1 if event.position.x>=size.x/2 else -1),8)

func _process(dt: float) -> void:
	if visible:
		time += dt
		queue_redraw()

func centered(s: String, y: float, px: int, color := Color("#fff2ce")) -> void:
	draw_string(font,Vector2(0,y),s,HORIZONTAL_ALIGNMENT_CENTER,size.x,px,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#183445"))
	for i in 120:
		var p := Vector2(fposmod(i*391.12,size.x),fposmod(i*i*29.71,size.y))
		draw_circle(p,1.2+0.9*sin(i+time),Color("#c9e9e1"),true,-1,true)
	if treasures==5:
		for i in 3:
			var tip := Vector2(fposmod(time*190+i*419,size.x+180)-90,fposmod(time*68+i*141,size.y+70)-35)
			draw_line(tip-Vector2(55,20),tip,Color("#f6d58d"),2,true)
	var mode_key := ("Stickklik" if solo else "B") if using_pad else "Shift"
	draw_style_box(pill, switch_rect())
	var mode_text := "Planeten" if charts else "Sterren tekenen"
	draw_string(font,switch_rect().position+Vector2(14,34),mode_key+" · "+mode_text,HORIZONTAL_ALIGNMENT_CENTER,246,19,Color("#fff0ce"))
	if charts:
		draw_chart()
		return
	centered("Sterrenkijker",82,21)
	centered(NAMES[planet],147,47)
	var c := size*Vector2(0.5,0.47)
	var r: float = [47,67,70,56,107,92,76,74][planet]
	draw_circle(c,r,Color(COLORS[planet]),true,-1,true)
	if planet==2:
		for p in [Vector2(-24,-17),Vector2(-11,-6),Vector2(16,19),Vector2(13,32),Vector2(31,-32)]:
			draw_circle(c+p,14,Color("#85c675"),true,-1,true)
	elif planet==0 or planet==3:
		for j in 9:
			var a := j*2.399
			var offset := Vector2(cos(a),sin(a))*(0.32+0.40*fmod(j*0.37,1.0))*r
			draw_circle(c+offset,r*(0.06+0.05*fmod(j*0.27,1.0)),Color("#9e8979") if planet==0 else Color("#c56b57"),true,-1,true)
		if planet==3:
			draw_set_transform(c+Vector2(0,-r*0.82),0,Vector2(1,0.32))
			draw_circle(Vector2.ZERO,r*0.33,Color("#f2d5bc"),true,-1,true)
			draw_set_transform(Vector2.ZERO)
	elif planet==1 or planet==7:
		for j in 3:
			var wave := PackedVector2Array()
			for k in 27:
				var x := (k/26.0-0.5)*1.48
				wave.append(c+r*Vector2(x,(j-1)*0.29+0.10*sin(x*3+j)))
			draw_polyline(wave,Color("#eec58d") if planet==1 else Color("#7b9fe4"),4,true)
	elif planet==5 or planet==6:
		var ring := PackedVector2Array()
		for j in 81:
			var a := TAU*j/80
			ring.append(c+Vector2(cos(a)*r*1.58,sin(a)*r*0.26).rotated(-0.34 if planet==5 else 1.16))
		draw_polyline(ring,Color("#e0ce9e"),7,true)
	elif planet==4:
		for j in 4:
			var y := -57+j*34
			var half := sqrt(r*r-y*y)-4
			draw_line(c+Vector2(-half,y),c+Vector2(half,y),Color("#c38b72"),10,true)
		draw_circle(c+Vector2(37,18),12,Color("#bc6857"),true,-1,true)
	centered(FACTS[planet],size.y*0.73,23)
	for i in 8:
		draw_circle(Vector2(size.x*0.5+(i-3.5)*36,size.y*0.81),10 if i==planet else 5,Color(COLORS[i]),true,-1,true)
	centered("Vijf schatten! Kijk naar de vallende sterren." if treasures==5 else "Vind vijf schatten voor een sterrenregen.",size.y*0.89,17)
	var back := ("SR" if solo else "A") if using_pad else "Spatie"
	centered("Links / rechts   Andere planeet       "+back+"  Terug",size.y-28,19)

func draw_chart() -> void:
	var done := connected==points().size()
	centered("Mijn sterrenboek   %d / 3" % album.size(),82,21)
	centered(CHARTS[chart][0],149,40)
	for i in range(1,connected):
		draw_line(star_position(i-1),star_position(i),Color("#f3c87e"),3,true)
	if done and chart==0:
		draw_line(star_position(6),star_position(3),Color("#f3c87e"),3,true)
	if done and chart==2:
		draw_line(star_position(8),star_position(0),Color("#f3c87e"),3,true)
	for i in points().size():
		var p := star_position(i)
		if i==star and not done:
			draw_arc(p,26,0,TAU,36,Color("#94d6cd"),3,true)
		draw_circle(p,16,Color("#f9d891") if i<connected else Color("#557d89"),true,-1,true)
		draw_string(font,p+Vector2(-16,6),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,32,17,Color("#193b44") if i<connected else Color.WHITE)
	var msg := "Zoek ster %d van %d." % [connected+1,points().size()]
	if done:
		msg = ["Je ziet de steel en het bakje van de Grote Beer!","Vijf sterren maken samen een W.","Je eigen sterrenraket is klaar!"][chart]
	centered(notice if notice!="" else msg,size.y*0.74,23)
	var action := ("SR" if solo else "A") if using_pad else "Spatie"
	centered(action+"   Volgende figuur" if done else "Links / rechts   Kies een ster      "+action+"   Verbind",size.y*0.85,20)
	centered(("−" if solo else "Menu") +"   Terug" if using_pad else "Tab   Terug",size.y-28,19)
