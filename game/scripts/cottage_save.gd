extends RefCounted

# One checkpoint per local game or browser origin. Only stable resident IDs go on disk.
var path := "user://cottage.json"
const WEB_KEY := "monster-island.cottage.v1"
var read_error := false

func write(friends: Array, party: Array, treasures: Array = [], stamps: Array = [], charts: Array = [], turtles := false, outings: Dictionary = {}) -> bool:
	var data := JSON.stringify({"version":1,"friends":friends,"party":party,"treasures":treasures,"stamps":stamps,"charts":charts,"turtles":turtles,"outings":outings})
	if OS.has_feature("web"):
		var script := "(function(){try{const key=%s;localStorage.setItem(key,%s);return localStorage.getItem(key)}catch(e){return null}})()"
		return JavaScriptBridge.eval(script % [JSON.stringify(WEB_KEY),JSON.stringify(data)],true)==data
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file:
		return false
	file.store_string(data)
	file.flush()
	var ok := file.get_error()==OK
	file.close()
	return ok and DirAccess.rename_absolute(path+".tmp",path)==OK

func read() -> Dictionary:
	read_error = false
	var text: Variant
	if OS.has_feature("web"):
		text = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)}catch(e){return false}})()" % JSON.stringify(WEB_KEY),true)
		if text==null:
			return {}
	else:
		if not FileAccess.file_exists(path):
			return {}
		text = FileAccess.get_file_as_string(path)
	if text is String:
		var data: Variant = JSON.parse_string(text)
		if data is Dictionary and data.get("version")==1 and data.get("friends") is Array and data.get("party") is Array:
			return data
	read_error = true
	return {}
