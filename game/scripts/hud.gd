extends Control
var regular: Font = ThemeDB.fallback_font
var bold := FontVariation.new()
var camera: Camera3D
var target: Node3D
var new_friend: Node3D
var place := "Vareneiland"
var friends := 0
var total := 0
var wonder_action := ""
var at_peak := false
var at_cottage := false
var cottage_text := ""
var cottage_until := 0.0
var pad := false
var single_left := false
var celebration := -1.0
var time := 0.0
const INK := Color("#263e40")
const CREAM := Color("#fff5d9")
const TEAL := Color("#27565a")
const GOLD := Color("#f8ca6c")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bold.base_font = regular
	bold.variation_embolden = 0.65

func panel(rect: Rect2, color: Color, radius: int, shadow := true) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0.06,0.17,0.16,0.16)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0,3)
	draw_style_box(style,rect)

func words(s: String, pos: Vector2, sz: int, color: Color, heavy := false) -> void:
	draw_string(bold if heavy else regular,pos,s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)

func heart(c: Vector2, r: float, color: Color) -> void:
	if not Rect2(Vector2.ZERO,size).grow(r*2).has_point(c):
		return
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU*i/48
		pts.append(c+Vector2(16*pow(sin(a),3),-(13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a)))*r/17)
	draw_colored_polygon(pts,color)

func badge(c: Vector2) -> void:
	draw_circle(c,23,TEAL,true,-1,true)
	draw_circle(c+Vector2(8,-8),4,GOLD,true,-1,true)
	draw_colored_polygon(PackedVector2Array([c+Vector2(-15,7),c+Vector2(-6,-9),c+Vector2(-1,-5),c+Vector2(3,-12),c+Vector2(15,7)]),Color("#f9c57b"))
	draw_colored_polygon(PackedVector2Array([c+Vector2(-15,7),c+Vector2(-8,-3),c+Vector2(-4,0),c+Vector2(0,-3),c+Vector2(7,7)]),Color("#89c296"))
	draw_line(c+Vector2(-12,11),c+Vector2(11,11),Color("#a6ded0"),2,true)

func counter_text() -> String:
	return "%d/%d" % [friends,total]

func book_rect() -> Rect2:
	return Rect2(size.x-231,22,207,50)

func cottage_message(message: String) -> void:
	cottage_text = message
	cottage_until = time+3.0
	queue_redraw()

func _draw() -> void:
	panel(Rect2(24,22,209,61),CREAM,16)
	badge(Vector2(55,52))
	words("Monstereiland",Vector2(86,51),19,INK,true)
	words(place.to_upper(),Vector2(87,69),11,Color("#527578"),true)
	panel(book_rect(),CREAM,25)
	words(("−" if single_left else "Menu") if pad else "Tab",Vector2(size.x-215,52),13,TEAL,true)
	draw_circle(Vector2(size.x-153,47),16,Color("#f7dbaf"),true,-1,true)
	heart(Vector2(size.x-153,47),9,Color("#c66a50"))
	words("Vrienden",Vector2(size.x-135,53),14,INK,true)
	words(counter_text(),Vector2(size.x-66,53),14,TEAL,true)
	if not camera:
		return
	if target:
		var anchor: Vector3 = target.marker.global_position+Vector3.UP*0.08*sin(time*2.3)
		if not camera.is_position_behind(anchor):
			var p := camera.unproject_position(anchor)
			var name_text: String = target.encounter_name()+" · Niveau "+str(target.level)
			var habitat: String = target.species.habitat
			var width := maxf(bold.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT,-1,16).x,regular.get_string_size(habitat,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)+26
			panel(Rect2(p.x-width/2,p.y-39,width,44),TEAL,16)
			draw_string(bold,p+Vector2(-width/2,-20),name_text,HORIZONTAL_ALIGNMENT_CENTER,width,16,CREAM)
			draw_string(regular,p+Vector2(-width/2,-4),habitat,HORIZONTAL_ALIGNMENT_CENTER,width,12,GOLD)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-5,4),p+Vector2(5,4),p+Vector2(0,10)]),TEAL)
	if time<cottage_until:
		var width := bold.get_string_size(cottage_text,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+52
		var x := (size.x-width)/2
		panel(Rect2(x,size.y-80,width,52),TEAL,26)
		words(cottage_text,Vector2(x+26,size.y-47),18,CREAM,true)
	elif target or at_cottage or at_peak or wonder_action!="":
		var label: String = "Slaap lekker" if at_cottage else ("Kijk in de kijker" if at_peak else (wonder_action if wonder_action!="" else "Praat met "+target.nickname))
		var w := 240.0 if pad else 270.0
		var x := (size.x-w)*0.5
		var y := size.y-80
		panel(Rect2(x,y,w,52),TEAL,26)
		panel(Rect2(x+9,y+9,34 if pad else 60,34),GOLD,17,false)
		var binding := ("SR" if single_left else "A") if pad else "Spatie"
		words(binding,Vector2(x+(15 if pad and single_left else 20),y+32),15,INK,true)
		words(label,Vector2(x+(54 if pad else 83),y+33),17,CREAM,true)
	if new_friend and celebration>=0 and celebration<2.8:
		var p := camera.unproject_position(new_friend.global_position+Vector3.UP*2.1)
		for i in 5:
			var age := celebration-i*0.15
			if age>0 and age<1.85 and not camera.is_position_behind(new_friend.global_position):
				var col := Color("#ff6d79")
				col.a = minf(1,(1.85-age)*2.5)
				heart(p+Vector2(sin(i*18+age)*age*36,-age*69),11+3*sin(i),col)
		if not target and not at_cottage and not at_peak and wonder_action=="" and time>=cottage_until:
			var message := "%s is je vriend!" % new_friend.nickname
			var width := bold.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+75
			var left := (size.x-width)/2
			panel(Rect2(left,size.y-80,width,51),TEAL,26)
			heart(Vector2(left+27,size.y-55),10,GOLD)
			words(message,Vector2(left+49,size.y-48),17,CREAM,true)

func _process(dt: float) -> void:
	time += dt
	if celebration>=0:
		celebration += dt
	queue_redraw()
