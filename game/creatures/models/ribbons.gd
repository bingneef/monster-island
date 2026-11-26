extends RefCounted
const S = preload("res://scripts/shapes.gd")

# An elliptical cross-section gives each painted curl thickness from side views.
static func strand(parent: Node3D, points: PackedVector3Array, widths: PackedFloat32Array, colors: Array, depth: float) -> void:
	var rings := []
	for i in points.size():
		var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
		var side := Vector3(-tangent.y,tangent.x,0).normalized()
		var normal := tangent.cross(side).normalized()
		var ring := PackedVector3Array()
		for j in 10:
			var a := TAU*j/10
			ring.append(points[i]+widths[i]*(side*cos(a)+normal*sin(a)*depth))
		rings.append(ring)
	S.bands(parent,rings,colors,0.015)
