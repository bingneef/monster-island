extends RefCounted

static var materials := {}
static var meshes := {}

static func mat(color: String) -> StandardMaterial3D:
	if not materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(color)
		m.roughness = 0.94
		materials[color] = m
	return materials[color]

static func group(parent: Node3D, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = pos
	return n

static func add(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	if color != "":
		n.material_override = mat(color)
	parent.add_child(n)
	n.position = pos
	n.scale = size
	return n

static func ball(p: Node3D, at: Vector3, size: Vector3, c: String, segments := 12) -> MeshInstance3D:
	var key := "ball%d" % segments
	if not meshes.has(key):
		var m := SphereMesh.new()
		m.radial_segments = segments
		m.rings = maxi(3, segments / 2 - 1)
		m.radius = 1
		m.height = 2
		meshes[key] = m
	return add(p, meshes[key], at, size, c)

static func box(p: Node3D, at: Vector3, size: Vector3, c: String) -> MeshInstance3D:
	if not meshes.has("box"):
		meshes["box"] = BoxMesh.new()
	return add(p, meshes["box"], at, size, c)

static func tube(p: Node3D, a: Vector3, b: Vector3, r1: float, r2: float, c: String, sides := 9) -> MeshInstance3D:
	var key := "tube%d/%f" % [sides, r2/r1]
	if not meshes.has(key):
		var m := CylinderMesh.new()
		m.radial_segments = sides
		m.rings = 0
		m.bottom_radius = 1
		m.top_radius = r2/r1
		m.height = 1
		meshes[key] = m
	var n := add(p, meshes[key], (a+b)/2, Vector3.ONE, c)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	n.scale = Vector3(r1,a.distance_to(b),r1)
	return n

# Each band is a closed polygon in the same angular order as its neighbours.
static func bands(p: Node3D, rings: Array, colors: Array, shade := 0.035) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(rings.size()-1):
		for i in rings[j].size():
			var k: int = (i+1)%rings[j].size()
			var c := Color(colors[j]).darkened(shade * (0.5+0.5*sin(i*17.31+j*3.81))).srgb_to_linear()
			var upper := Color(colors[j+1]).srgb_to_linear() if colors.size()==rings.size() else c
			for tri in [[rings[j][i],rings[j+1][i],rings[j+1][k]], [rings[j][i],rings[j+1][k],rings[j][k]]]:
				var norm: Vector3 = (tri[2]-tri[0]).cross(tri[1]-tri[0]).normalized()
				for v in tri:
					st.set_color(upper if v==rings[j+1][i] or v==rings[j+1][k] else c)
					st.set_normal(norm)
					st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(m)
	return add(p,st.commit(),Vector3.ZERO,Vector3.ONE,"")

static func ring(radius: Vector2, height: float, count: int, phase := 0.0, uneven := 0.0) -> PackedVector3Array:
	var result := PackedVector3Array()
	for i in count:
		var a := TAU*i/count
		var r := 1.0+uneven*(sin(3*a+phase)+0.5*cos(5*a-phase))
		result.append(Vector3(sin(a)*radius.x*r,height,cos(a)*radius.y*r))
	return result
