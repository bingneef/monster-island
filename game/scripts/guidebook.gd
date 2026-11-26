extends Control

signal toggle_requested(creature: Node3D)
signal practice_requested(creature: Node3D)
signal close_requested
const CREAM := Color("#fff6df")
const TEAL := Color("#234d51")
const MUTED := Color("#526d67")
const GOLD := Color("#f4c769")
const TINTS := [Color("#f4c6a2"),Color("#ade1dc"),Color("#e4b4ac"),Color("#e0dfa0"),Color("#dbcae5")]
var map_open := false
var explorer := Vector3.ZERO
var stamps: Array = []
var treasures: Array = []
var species: Array
var residents: Array
var page := 0
var row := 0
var notice := ""
var pad := false
var solo := false
var font := ThemeDB.fallback_font
var bold := FontVariation.new()

func setup(kinds: Array, population: Array) -> void:
	species = kinds
	residents = population
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	bold.base_font = font
	bold.variation_embolden = 0.7
	hide()

func open(using_pad: bool, single: bool) -> void:
	pad = using_pad
	solo = single
	map_open = false
	notice = ""
	show()
	queue_redraw()

func on_page() -> Array:
	return residents.filter(func(c): return c.species==species[page])

func navigate() -> void:
	if Input.is_action_just_pressed("hop"):
		map_open = not map_open
		queue_redraw()
		return
	if map_open:
		return
	if Input.is_action_just_pressed("run"):
		practice()
		return
	var horizontal := int(pressed("east","ui_right"))-int(pressed("west","ui_left"))
	var vertical := int(pressed("south","ui_down"))-int(pressed("north","ui_up"))
	if horizontal or vertical:
		page = posmod(page+horizontal,species.size())
		row = posmod(row+vertical,on_page().size())
		notice = ""
		queue_redraw()
	if Input.is_action_just_pressed("offer") or Input.is_key_pressed(KEY_ENTER) and Input.is_action_just_pressed("ui_accept"):
		choose()

func pressed(action: String, ui_action: String) -> bool:
	return Input.is_action_just_pressed(action) or Input.is_action_just_pressed(ui_action)

func choose() -> void:
	notice = ""
	var c: Node3D = on_page()[row]
	if c.friend:
		toggle_requested.emit(c)
	else:
		notice = "Zoek "+c.nickname+" in de "+c.species.habitat+"."
	queue_redraw()

func practice() -> void:
	var chosen: Node3D = on_page()[row]
	if chosen.friend:
		practice_requested.emit(chosen)

func practice_rect() -> Rect2:
	return Rect2(origin()+Vector2(626,445),Vector2(200,38))

func origin() -> Vector2:
	return (size-Vector2(856,534))*0.5

func tab_box(i: int) -> Rect2:
	return Rect2(origin()+Vector2(30+i*103,99),Vector2(94,49))

func row_box(i: int) -> Rect2:
	return Rect2(origin()+Vector2(324,170+i*71),Vector2(502,61))

func close_box() -> Rect2:
	return Rect2(origin()+Vector2(786,26),Vector2(40,40))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		accept_event()
		if close_box().has_point(event.position):
			close_requested.emit()
			return
		if map_button().has_point(event.position):
			map_open = not map_open
			queue_redraw()
			return
		if map_open:
			return
		if practice_rect().has_point(event.position):
			practice()
			return
		for i in species.size():
			if tab_box(i).has_point(event.position):
				page = i
				row = 0
				notice = ""
				queue_redraw()
				return
		for i in on_page().size():
			if row_box(i).has_point(event.position):
				row = i
				choose()
				return

func panel(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func words(s: String, pos: Vector2, px: int, ink: Color, heavy := false) -> void:
	draw_string(bold if heavy else font,origin()+pos,s,HORIZONTAL_ALIGNMENT_LEFT,-1,px,ink)

func _draw() -> void:
	if species.is_empty():
		return
	var o := origin()
	var kind: Resource = species[page]
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.035,0.12,0.14,0.59))
	panel(Rect2(o+Vector2(0,6),Vector2(856,534)),Color("#324a45"),28)
	panel(Rect2(o,Vector2(856,534)),CREAM,28)
	words("Eilandkaart" if map_open else "Mijn eilandboek",Vector2(32,61),34,TEAL,true)
	var following := residents.filter(func(c): return c.following).size()
	words("%d / 5 mee" % following,Vector2(615,54),19,TEAL,true)
	panel(close_box(),Color("#e6e6cf"),20)
	words("×",Vector2(797,55),24,TEAL,true)
	panel(map_button(),Color("#d9e5cc"),14)
	var binding := ("Stickklik" if solo else "B") if pad else "Shift"
	words(binding+(" · Boek" if map_open else " · Kaart"),Vector2(444,55),15,TEAL,true)
	if map_open:
		draw_map()
		return
	for i in species.size():
		var r := tab_box(i)
		panel(r,TEAL if i==page else Color("#ebe7d2"),17)
		draw_texture_rect(species[i].portrait,Rect2(r.get_center()-Vector2(21,21),Vector2(42,42)),false)
	panel(Rect2(o+Vector2(30,170),Vector2(274,274)),TINTS[page],20)
	draw_circle(o+Vector2(167,274),77,Color(1,1,1,0.36),true,-1,true)
	draw_texture_rect(kind.portrait,Rect2(o+Vector2(104,211),Vector2(126,126)),false)
	words(kind.display_name,Vector2(48,390),25,TEAL,true)
	words(kind.habitat,Vector2(49,419),17,TEAL)
	words(("Gevonden: "+kind.relic) if kind.theme in treasures else kind.clue,Vector2(32,469),15,TEAL,true)
	words("Schatten   %d / 5" % treasures.size(),Vector2(568,131),17,TEAL,true)
	var group := on_page()
	for i in group.size():
		var c: Node3D = group[i]
		var selected := row==i
		var r := row_box(i)
		panel(r,TEAL if selected else Color("#eee9d5"),13)
		var ink := CREAM if selected else TEAL
		var badge := Color("#a7d2b0") if c.following else Color("#d6d6be")
		draw_circle(r.position+Vector2(30,30),15,badge,true,-1,true)
		if c.following:
			draw_polyline(PackedVector2Array([r.position+Vector2(22,30),r.position+Vector2(28,36),r.position+Vector2(38,23)]),TEAL,3,true)
		var title: String = c.nickname+"  ★" if c.shiny else c.nickname
		words(title,Vector2(379,196+i*71),19,ink,true)
		words(("Niveau %d · %s" % [c.level,kind.theme]),Vector2(379,216+i*71),13,GOLD if selected else MUTED)
		var status := "Gaat mee" if c.following else ("Thuis" if c.friend else "Zoek mij")
		words(status,Vector2(700,207+i*71),15,ink,true)
	if group[row].friend:
		panel(practice_rect(),Color("#d9e5cc"),12)
		var key := ("SL" if solo else "L") if pad else "Ctrl"
		words(key+" · Oefen samen",Vector2(645,470),16,TEAL,true)
	var hint := "A/D  Gebied      W/S  Vriend      Spatie  Kies      Tab  Dicht"
	if pad:
		hint = "Stick  Blader       SR  Kies       −  Dicht" if solo else "Stick  Blader       A  Kies       Menu  Dicht"
	words(notice if notice!="" else hint,Vector2(33,500),17,TEAL,notice!="")

func map_button() -> Rect2:
	return Rect2(origin()+Vector2(430,25),Vector2(145,42))

func map_point(p: Vector3) -> Vector2:
	return origin()+Vector2(249+p.x*2.62,282+p.z*2.62)

func draw_map() -> void:
	var o := origin()
	panel(Rect2(o+Vector2(25,98),Vector2(452,375)),Color("#9bdbd6"),25)
	var coast := PackedVector2Array()
	for j in 80:
		var a := TAU*j/80
		var shape := 1+0.025*sin(a*5)
		coast.append(map_point(Vector3(78*cos(a)*shape,0,64*sin(a)*shape)))
	draw_colored_polygon(coast,Color("#f6d597"))
	for j in coast.size():
		coast[j] = map_point(Vector3.ZERO).lerp(coast[j],0.94)
	draw_colored_polygon(coast,Color("#a8c876"))
	var hill := map_point(Vector3(47,0,32))
	draw_circle(hill,32,Color("#8bb76d"),true,-1,true)
	draw_circle(hill,5,GOLD,true,-1,true)
	draw_circle(map_point(Vector3(-37,0,-14)),11,Color("#6dbebf"),true,-1,true)
	for j in species.size():
		var p := map_point(species[j].home)
		draw_circle(p,15,TEAL,true,-1,true)
		draw_texture_rect(species[j].portrait,Rect2(p-Vector2(14,14),Vector2(28,28)),false)
		var place := map_point(preload("res://scripts/wonders.gd").PLACES[j])
		draw_circle(place,6,TEAL,true,-1,true)
		draw_circle(place,4,GOLD if j in stamps else CREAM,true,-1,true)
	var beach := map_point(Vector3(-3,0,43))
	draw_circle(beach,6,Color("#faf3d4"),true,-1,true)
	words("Schildpadstrand",beach-origin()+Vector2(-50,18),12,TEAL,true)
	var me := map_point(explorer)
	draw_circle(me,8,CREAM,true,-1,true)
	draw_circle(me,5,Color("#bf5041"),true,-1,true)
	words("Ontdekplekjes",Vector2(510,132),24,TEAL,true)
	for j in 5:
		draw_circle(o+Vector2(523,175+j*39),9,TEAL,true,-1,true)
		draw_circle(o+Vector2(523,175+j*39),6,GOLD if j in stamps else CREAM,true,-1,true)
		words(preload("res://scripts/wonders.gd").NAMES[j],Vector2(545,182+j*39),18,TEAL)
	words("Stempels   %d / 5" % stamps.size(),Vector2(510,382),21,TEAL,true)
	words("Alle vijf? Kijk dan bij je huisje!",Vector2(510,415),16,TEAL)
	words("Rood = jij     Goud op de heuvel = sterrenkijker",Vector2(31,501),17,TEAL)
