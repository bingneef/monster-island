extends Node3D
const S = preload("res://scripts/shapes.gd")

func build(_species: Resource) -> void:
	var rings := []
	for layer in [[0.39,-0.55],[0.56,-0.44],[0.59,-0.32],[0.57,-0.18],[0.53,0.04],[0.44,0.32],[0.41,0.47],[0.01,0.49]]:
		var ring := S.ring(Vector2(layer[0],layer[0]*0.70),layer[1],48)
		for i in ring.size():
			if layer[1] in [-0.32,-0.18]:
				ring[i].y += 0.042*cos(TAU*i*6/48)
		rings.append(ring)
	S.bands(self,rings,["126bc8","1ba4ed","fff9ce","26c7f9","28b3f5","267bd5","327bc6"])
	var lid := S.ball(self,Vector3(0,0.42,0.02),Vector3(0.48,0.18,0.36),"df9d50",24)
	lid.rotation.x = 0.18
	S.ball(self,Vector3(0,0.46,0.037),Vector3(0.48,0.17,0.37),"fff0cd",24)
	S.ball(self,Vector3(0,0.36,0.31),Vector3(0.16,0.17,0.08),"f0bf67",20)
	S.ball(self,Vector3(0,0.37,0.366),Vector3(0.11,0.126,0.045),"2289de",20)
	S.tube(self,Vector3(0,0.41,0.366),Vector3(0.018,0.55,0.36),0.095,0.004,"44cdf7")
	for side in [-1,1]:
		S.ball(self,Vector3(side*0.199,0.09,0.338),Vector3(0.062,0.083,0.041),"152d53",16)
		S.ball(self,Vector3(side*0.199-0.012,0.121,0.372),Vector3.ONE*0.021,"ffffff")
		S.ball(self,Vector3(side*0.31,-0.007,0.318),Vector3(0.064,0.031,0.017),"8de7fa")
	S.ball(self,Vector3(0,-0.035,0.38),Vector3(0.074,0.063,0.024),"432943")
	S.ball(self,Vector3(0,-0.059,0.398),Vector3(0.048,0.026,0.01),"f3849a")
