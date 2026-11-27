extends Node3D
const S = preload("res://scripts/shapes.gd")
var species: Resource
var model: Node3D
var home: Vector3
var friend := false
var following := false
var shiny := false
var level := 1
var palette := 0
var nickname := ""
var save_id := ""

func encounter_name() -> String:
	return species.shiny_name+" ★" if shiny else species.display_name
var clock := 0.0
var marker: Node3D
var follow_slot := Vector2.ZERO
var follow_speed := 0.0
var velocity := Vector3.ZERO

func _ready() -> void:
	home = position
	model = species.model.new()
	add_child(model)
	model.build(species)
	model.scale *= 1.0+(level-1)*0.045
	if shiny:
		make_shiny()
	marker = S.group(self,Vector3.UP*(species.hover_height+1.18))

func step(dt: float, player: Vector3, guide: Callable, destination: Vector3, running: bool) -> void:
	clock += dt
	model.position.y = species.hover_height+sin(clock*2.3)*0.13
	model.rotation.z = sin(clock*(1.65+level*0.15))*(0.035+level*0.012)
	model.rotation.x = sin(clock*1.4)*0.018+(level-1)*0.033
	var goal := home + Vector3(sin(clock*0.47)*0.75,0,sin(clock*0.77)*0.40)
	var speed := 0.56
	var look := player-position if position.distance_to(player)<7 else goal-position
	if following:
		goal = guide.call(position,destination)
		var stride := goal-position
		if stride.length_squared()>0.0001:
			look = stride
		else:
			goal = position
			look = player-position
		# A moving target opens a small gap that naturally sets the walking speed.
		var desired_speed := minf(8.8 if running else 5.8,position.distance_to(destination)*8.0)
		follow_speed = move_toward(follow_speed,desired_speed,dt*18.0)
		speed = follow_speed
	if Vector2(look.x,look.z).length_squared()>0.000001:
		var heading := atan2(look.x,look.z)
		model.rotation.y = rotate_toward(model.rotation.y,heading,dt*8.0)
		if following:
			# Pivot before setting off, especially when the explorer doubles back.
			speed *= smoothstep(0.70,0.97,cos(model.rotation.y-heading))
	var next := position.move_toward(goal,dt*speed)
	velocity = (next-position)/dt
	position = next

func make_shiny() -> void:
	if palette>=0:
		apply_shiny_palette()
	var stars := CPUParticles3D.new()
	model.add_child(stars)
	stars.amount = 9
	stars.lifetime = 1.35
	stars.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	stars.emission_sphere_radius = 0.89
	stars.gravity = Vector3(0,0.26,0)
	stars.scale_amount_min = 0.6
	var gem := PrismMesh.new()
	gem.size = Vector3(0.10,0.16,0.07)
	gem.material = S.mat("ffe896")
	stars.mesh = gem

func apply_shiny_palette() -> void:
	var variants := {}
	for part: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var original := part.get_active_material(0) as StandardMaterial3D
		if not original:
			continue
		if not variants.has(original):
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/shiny.gdshader")
			mat.set_shader_parameter("palette",palette)
			mat.set_shader_parameter("painted",original.vertex_color_use_as_albedo)
			mat.set_shader_parameter("base_color",original.albedo_color)
			variants[original] = mat
		part.material_override = variants[original]
