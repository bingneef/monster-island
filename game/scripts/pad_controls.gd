extends RefCounted

const BUTTONS := {"run":JOY_BUTTON_LEFT_SHOULDER,"journal":JOY_BUTTON_START,"offer":JOY_BUTTON_B,"hop":JOY_BUTTON_A}
const SOLO_BUTTONS := {
	"journal":JOY_BUTTON_START,
	"west":JOY_BUTTON_DPAD_LEFT,"east":JOY_BUTTON_DPAD_RIGHT,
	"north":JOY_BUTTON_DPAD_UP,"south":JOY_BUTTON_DPAD_DOWN,
	"run":JOY_BUTTON_LEFT_SHOULDER,"hop":JOY_BUTTON_LEFT_STICK,"offer":JOY_BUTTON_RIGHT_SHOULDER,
	"pan_left":JOY_BUTTON_X,"pan_right":JOY_BUTTON_B,
	"pan_up":JOY_BUTTON_Y,"pan_down":JOY_BUTTON_A,
}
const STICKS := [
	["west",JOY_AXIS_LEFT_X,-1],["east",JOY_AXIS_LEFT_X,1],
	["north",JOY_AXIS_LEFT_Y,-1],["south",JOY_AXIS_LEFT_Y,1],
	["pan_left",JOY_AXIS_RIGHT_X,-1],["pan_right",JOY_AXIS_RIGHT_X,1],
	["pan_up",JOY_AXIS_RIGHT_Y,-1],["pan_down",JOY_AXIS_RIGHT_Y,1],
]
var single_left := {}

func connection(device: int, connected: bool) -> void:
	remove(device)
	if connected:
		var info := Input.get_joy_info(device)
		var label := Input.get_joy_name(device).to_lower()
		var is_left: bool = "joy-con (l)" in label or (info.get("vendor_id")==0x057e and info.get("product_id")==0x2006)
		install(device,is_left)

func install(device: int, is_left: bool) -> void:
	single_left[device] = is_left
	var buttons := SOLO_BUTTONS if is_left else BUTTONS
	for action in buttons:
		var e := InputEventJoypadButton.new()
		e.device = device
		e.button_index = buttons[action]
		InputMap.action_add_event(action,e)
	for row in STICKS:
		var e := InputEventJoypadMotion.new()
		e.device = device
		e.axis = row[1]
		e.axis_value = row[2]
		InputMap.action_add_event(row[0],e)

func remove(device: int) -> void:
	for action in SOLO_BUTTONS:
		for event in InputMap.action_get_events(action):
			if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.device==device:
				InputMap.action_erase_event(action,event)
	single_left.erase(device)
