extends VBoxContainer

@onready var key_box = preload("res://Screen/Asset/Function/HUD/key.tscn")

var remaping = false
var reaction
var rebutton

var input_actions = {
	"fire" : "FIRE",
	"alt" : "ALT",
	"reload" : "RELOAD",
	"switchup" : "SWITCHUP",
	"switchdown" : "SWITCHDOWN",
	"mode" : "MODE",
	"lethal" : "LETHAL",
	"tactical" : "TACTICAL",
	"melee" : "MELEE",
	"lethalskill" : "ATKSKILL",
	"tacticalskill" : "TACSKILL",
	"ultimateskill" : "ULTSKILL",
	"sentry" : "STREAK_SP",
	"armor" : "USE_ARMOR",
	"interface" : "INTERFACE",
	"ping" : "PING",
	"inventory" : "INVENTORY",
	"map" : "MAP",
	"right" : "GO_RIGHT",
	"left" : "GO_LEFT",
	"up" : "LOOK_UP",
	"down" : "LOOK_DOWN",
	"jump" : "JUMP",
	"crouch" : "CROUCH",
	"kick" : "KICK"
}

func _ready():
	TranslationServer.set_locale("en")
	InputMap.load_from_project_settings()
	for i in get_children():
		i.queue_free()
	for action in input_actions:
		var button = key_box.instantiate()
		var action_label = button.get_node("Label")
		var input = button.get_node("Input")
		
		action_label.text = tr(input_actions[action])
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input.text = ""
		add_child(button)
		button.pressed.connect(_pressed.bind(button,action))

func _pressed(button,action):
	if !remaping:
		remaping = true
		reaction = action
		rebutton = button
		button.disabled = true
		button.get_node("Input").text = "Press key to bind..."
		
func _input(event):
	if remaping:
		if event is InputEventKey or (event is InputEventMouseButton and event.pressed):
			InputMap.action_erase_events(reaction)
			InputMap.action_add_event(reaction,event)
			_update(rebutton,event)
			remaping = false
			rebutton.disabled = false
			reaction = null
			rebutton = null
func _update(button,event):
	button.get_node("Input").text = event.as_text().trim_suffix(" (Physical)")
