extends Node3D
const S = preload("res://scripts/shapes.gd")
var body: Node3D
var legs := []
var arms := []
var phase := 0.0

func _ready() -> void:
	body = S.group(self)
	for side in [-1,1]:
		var leg := S.group(body,Vector3(side*0.145,0.59,0))
		legs.append(leg)
		S.ball(leg,Vector3(0,-0.12,0),Vector3(0.135,0.22,0.13),"4d656c")
		S.ball(leg,Vector3(0,-0.31,0),Vector3(0.093,0.12,0.095),"d79b72")
		S.ball(leg,Vector3(0,-0.42,0),Vector3(0.108,0.10,0.11),"fbdda2")
		S.ball(leg,Vector3(0,-0.48,0.047),Vector3(0.14,0.11,0.19),"a75e42")
	S.ball(body,Vector3(0,0.79,0),Vector3(0.32,0.37,0.223),"e9844c",24)
	for side in [-1,1]:
		var arm := S.group(body,Vector3(side*0.274,0.94,0))
		arms.append(arm)
		arm.rotation.z = side*0.14
		S.ball(arm,Vector3(0,-0.049,0),Vector3(0.124,0.149,0.134),"f09859")
		S.ball(arm,Vector3(0,-0.21,0.02),Vector3(0.098,0.14,0.098),"e6af83")
	S.ball(body,Vector3(0,1.30,0.02),Vector3(0.334,0.354,0.306),"efb98c",24)
	S.ball(body,Vector3(0,1.40,-0.056),Vector3(0.346,0.301,0.289),"664234",24)
	for side in [-1,1]:
		S.ball(body,Vector3(side*0.295,1.28,0.06),Vector3(0.085,0.104,0.073),"e9ae84")
		S.ball(body,Vector3(side*0.121,1.32,0.295),Vector3(0.031,0.046,0.019),"443339")
		S.ball(body,Vector3(side*0.158,1.245,0.278),Vector3(0.058,0.024,0.012),"e59e7e")
	S.ball(body,Vector3(0,1.26,0.324),Vector3(0.054,0.044,0.038),"e4a47e")
	var hat := S.group(body,Vector3(0,1.55,-0.02))
	hat.rotation.z = -0.055
	S.ball(hat,Vector3.ZERO,Vector3(0.48,0.075,0.424),"dfad66",24)
	S.ball(hat,Vector3(0,0.064,0),Vector3(0.355,0.221,0.323),"f9ce84",24)
	var band := S.tube(hat,Vector3(0,0.044,0),Vector3(0,0.111,0),0.356,0.344,"b95e41",24)
	band.scale.z *= 0.92
	S.ball(body,Vector3(0,0.82,-0.225),Vector3(0.255,0.294,0.138),"2b7c7a",20)
	S.ball(body,Vector3(0,0.87,-0.31),Vector3(0.225,0.184,0.097),"5ab2a3",20)
	S.ball(body,Vector3(0,0.71,-0.326),Vector3(0.18,0.12,0.09),"3c9290")
	S.box(body,Vector3(0,0.84,-0.409),Vector3(0.059,0.094,0.028),"f6cb75")

func animate(dt: float, speed: float, airborne: bool) -> void:
	phase += dt*10.8
	var swing := sin(phase)*speed
	body.position.y = absf(cos(phase))*0.055*speed
	for i in 2:
		var sign_dir := 1.0 if i==0 else -1.0
		legs[i].rotation.x = (0.20 if airborne else 0.62*swing)*sign_dir
		arms[i].rotation.x = -0.43*swing*sign_dir
		arms[i].rotation.z = -sign_dir*(0.75 if airborne else 0.12)
