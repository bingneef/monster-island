extends Node3D
const S = preload("res://scripts/shapes.gd")

func build(species: Resource) -> void:
	S.ball(self,Vector3(0,0.08,0.16),Vector3(0.46,0.43,0.38),"28182e",32)
	for side in [-1,1]:
		var eye := S.ball(self,Vector3(side*0.205,0.135,0.502),Vector3(0.077,0.139,0.045),species.eyes.to_html(false),24)
		var glow := eye.material_override.duplicate() as StandardMaterial3D
		glow.emission_enabled = true
		glow.emission = species.eyes
		glow.emission_energy_multiplier = 0.58
		eye.material_override = glow
		eye.rotation.z = side*0.12
		S.ball(self,eye.position+Vector3(-0.011,0.046,0.041),Vector3(0.025,0.044,0.012),"ffe8ff")
	# The reference shows a fringe of separate rounded flames beneath the face.
	for i in 9:
		var a := TAU*i/9
		var plume := []
		var extension := 0.19*absf(sin(a))
		for k in 11:
			var t := k/10.0
			var radius := maxf(0.003,pow(sin(t*PI),0.59)*0.26)
			var dist := 0.31+0.12*(1-t)+extension*sin(t*PI)
			var ring := S.ring(Vector2(radius,radius*0.89),-0.73+0.97*t+0.17*absf(sin(a))+0.075*cos(a*3),18)
			for j in ring.size():
				ring[j] += Vector3(sin(a)*dist,0,cos(a)*dist-0.06)
			plume.append(ring)
		S.bands(self,plume,["fff293","ffde59","ffc238","ffae29","ff9620","ff841c","ff6b15","ed591a","df461c","cf3e20","d95219"],0.0)
	var rings := []
	# Raise the front hem into a hood. Rounded teardrop lobes hang at the sides and back.
	for j in 8:
		var ring := PackedVector3Array()
		for i in 96:
			var a := TAU*i/96
			var lobe := (1+cos(a*8))/2
			var arch := smoothstep(0.52,0.96,cos(a))
			var r: float = [0.69,0.76,0.78,0.71,0.62,0.48,0.28,0.012][j]
			r += lobe * [0.07,0.085,0.07,0.052,0.03,0.015,0,0][j]
			var y: float = [-0.38,-0.34,-0.24,-0.02,0.21,0.44,0.60,0.68][j]
			y += arch * [0.79,0.79,0.72,0.56,0.36,0.14,0.035,0][j]
			y -= lobe * (1.0-arch)*[0.20,0.20,0.16,0.10,0.05,0.02,0,0][j]
			ring.append(Vector3(sin(a)*r,y,cos(a)*r*0.87))
		rings.append(ring)
	S.bands(self,rings,Array(species.cloak)+["ffce5b"],0.012)
	var sparks := CPUParticles3D.new()
	add_child(sparks)
	sparks.amount = 16
	sparks.lifetime = 1.55
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.72
	sparks.gravity = Vector3(0,0.6,0)
	sparks.direction = Vector3.UP
	sparks.initial_velocity_min = 0.32
	sparks.initial_velocity_max = 0.65
	sparks.scale_amount_min = 0.35
	var spark := SphereMesh.new()
	spark.radius = 0.042
	spark.height = 0.09
	spark.material = S.mat("ffd25f")
	sparks.mesh = spark

