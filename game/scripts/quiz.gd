extends Control

signal finished(resident: Node3D)
signal closed
const Book = preload("res://scripts/questions.gd")
const INK := Color("#214c50")
const PAPER := Color("#fff6df")
const GOLD := Color("#f5c96f")
var resident: Node3D
var cards: Array
var index := 0
var selected := 0
var missed := []
var pad := false
var solo := false
var font := ThemeDB.fallback_font
var bold := FontVariation.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bold.base_font = font
	bold.variation_embolden = 0.75
	hide()

func begin(c: Node3D, using_pad: bool, single: bool) -> void:
	resident = c
	pad = using_pad
	solo = single
	cards = Book.deck(c.species.display_name,c.level,5 if c.shiny else 3)
	index = 0
	selected = 0
	missed.clear()
	show()
	queue_redraw()

func navigate() -> void:
	if Input.is_action_just_pressed("journal") or (Input.is_key_pressed(KEY_ESCAPE) and Input.is_action_just_pressed("ui_cancel")):
		closed.emit()
		return
	var step := int(Input.is_action_just_pressed("south") or Input.is_action_just_pressed("ui_down"))-int(Input.is_action_just_pressed("north") or Input.is_action_just_pressed("ui_up"))
	if step:
		selected = posmod(selected+step,3)
		queue_redraw()
	if Input.is_action_just_pressed("offer") or (Input.is_key_pressed(KEY_ENTER) and Input.is_action_just_pressed("ui_accept")):
		choose(selected)

func choose(i: int) -> void:
	if not visible:
		return
	if cards[index].choices[i]!=cards[index].answer:
		if i not in missed:
			missed.append(i)
	else:
		index += 1
		missed.clear()
		selected = 0
		if index==cards.size():
			finished.emit(resident)
			return
	queue_redraw()

func origin() -> Vector2:
	return (size-Vector2(870,474))*0.5

func row_rect(i: int) -> Rect2:
	return Rect2(origin()+Vector2(287,162+69*i),Vector2(548,56))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		accept_event()
		if Rect2(origin()+Vector2(798,12),Vector2(55,49)).has_point(event.position):
			closed.emit()
			return
		for i in 3:
			if row_rect(i).has_point(event.position):
				choose(i)
				return

func box(r: Rect2, color: Color, radius := 18) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style,r)

func label(s: String, x: int, y: int, px: int, ink: Color, strong := false) -> void:
	draw_string(bold if strong else font,origin()+Vector2(x,y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,px,ink)

func flag_picture(flag: Array, r: Rect2) -> void:
	draw_rect(r.grow(2),INK)
	if flag[1]=="dot":
		draw_rect(r,Color(flag[2]))
		draw_circle(r.get_center(),r.size.y*0.3,Color(flag[3]),true,-1,true)
		return
	var count := flag.size()-2
	for i in count:
		var stripe := r
		if flag[1]=="v":
			stripe.size.x /= count
			stripe.position.x += i*stripe.size.x
		else:
			stripe.size.y /= count
			stripe.position.y += i*stripe.size.y
		draw_rect(stripe,Color(flag[i+2]))

func _draw() -> void:
	if not resident or index>=cards.size():
		return
	var o := origin()
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.04,0.13,0.15,0.56))
	box(Rect2(o+Vector2(0,7),Vector2(870,474)),INK,26)
	box(Rect2(o,Vector2(870,474)),PAPER,26)
	box(Rect2(o+Vector2(18,18),Vector2(242,438)),Color("#c5e5d4"))
	label(resident.species.theme,38,59,27,INK,true)
	label("Niveau %d" % resident.level,39,85,18,INK)
	if cards[index].has("flag"):
		flag_picture(cards[index].flag,Rect2(o+Vector2(49,155),Vector2(180,112)))
	elif not missed.is_empty() and cards[index].has("som"):
		draw_math_hint(cards[index].som)
	else:
		draw_circle(o+Vector2(137,208),87,Color("#e8f3cf"),true,-1,true)
		draw_texture_rect(resident.species.portrait,Rect2(o+Vector2(69,140),Vector2(136,136)),false)
	label(resident.nickname+(" ★" if resident.shiny else ""),39,344,28,INK,true)
	label("Samen oefenen" if resident.friend else "Vriendenproef",40,372,18,INK)
	for i in cards.size():
		draw_circle(o+Vector2(51+i*34,408),10,INK,true,-1,true)
		draw_circle(o+Vector2(51+i*34,408),7,GOLD if i<index else PAPER,true,-1,true)
	label("Vraag %d van %d" % [index+1,cards.size()],287,55,20,INK,true)
	label("×",814,50,28,INK)
	draw_multiline_string(bold,o+Vector2(287,102),cards[index].q,HORIZONTAL_ALIGNMENT_LEFT,545,25,-1,INK)
	for i in 3:
		var r := row_rect(i)
		box(r,INK if selected==i else Color("#ebe7d1"),14)
		var ink := PAPER if selected==i else INK
		draw_circle(r.position+Vector2(27,28),12,GOLD if selected==i else Color("#b7cbb6"),true,-1,true)
		label("·" if i in missed else str(i+1),307,199+i*69,16,INK,true)
		label(cards[index].choices[i],340,200+i*69,22,ink,true)
	label("Probeer een ander antwoord." if missed else "Welk antwoord kies jij?",287,396,19,INK,true)
	var key := ("SR" if solo else "A") if pad else "Spatie"
	var back := ("−" if solo else "Menu") if pad else "Tab"
	label("Omhoog / omlaag       %s   Antwoord       %s   Terug" % [key,back],287,438,16,INK)

func draw_math_hint(som: Array) -> void:
	var a := int(som[0])
	var b := int(som[1])
	var op := str(som[2])
	var o := origin()
	label("Samen tellen",38,133,21,INK,true)
	if resident.level<=2:
		var count := a*b if op in ["×","÷"] else a+b
		var columns := b if op=="×" else (a if op=="÷" else 6)
		var rows := ceili(float(count)/columns)
		var space := minf(25, minf(180.0/maxi(columns,1),118.0/maxi(rows,1)))
		for j in count:
			var p := o+Vector2(139+(j%columns-(columns-1)*0.5)*space,211+(floori(float(j)/columns)-(rows-1)*0.5)*space)
			var second := j>=a if op in ["+","−"] else floori(float(j)/columns)%2==1
			draw_circle(p,space*0.35,GOLD if second else INK,true,-1,true)
			if op=="−" and second:
				draw_line(p-Vector2.ONE*space*0.29,p+Vector2.ONE*space*0.29,INK,2,true)
		var hint := {"+":"Tel alle stippen.","−":"Wat blijft er over?","×":"Tel de rijen bij elkaar.","÷":"Hoeveel in één rij?"}
		label(hint[op],38,303,17,INK,true)
	else:
		var prompt: String
		var sub: String
		match op:
			"+":
				var tens := floori(b/10.0)*10
				prompt = "Tel eerst %d erbij." % tens if tens else "Begin bij %d." % a
				sub = "Dan nog %d." % (b-tens)
			"−":
				var tens := floori(b/10.0)*10
				prompt = "Haal eerst %d weg." % tens if tens else "Begin bij %d." % (a+b)
				sub = "Dan nog %d eraf." % (b-tens)
			"×":
				prompt = "Denk aan %d × %d." % [a-1,b]
				sub = "Tel er nog %d bij." % b
			"÷":
				prompt = "%d × iets = %d" % [b,a*b]
				sub = "Welk getal past?"
		label(prompt,34,205,18,INK,true)
		label(sub,34,240,18,INK)
