extends Node

var left
var lefting
var lefted
var right
var righting
var righted
var up
var down
var jump
var fly
var crouch
var crouching
var dive
var lay
var alt
var aim
var fire
var firing
var fired
var reload
var use
var using
var mode
var attack
var attacked
var attack_charge
var scroll
var scroll_down
var scroll_up
var lethal
var lethal_hold
var tactical
var tactical_hold
var lethal_skill
var tactical_skill
var skill_mode
var sentry
var armor
var heal
var pack
var inventory
var map
var drop
var ping
var dash
var dashing
var kick
var escape
func _physics_process(_delta):
	process_mode = Node.PROCESS_MODE_ALWAYS
	lefting = Input.is_action_pressed("left")
	left = Input.is_action_just_pressed("left")
	lefted = Input.is_action_just_released("left")
	righting = Input.is_action_pressed("right")
	right = Input.is_action_just_pressed("right")
	righted = Input.is_action_just_released("right")
	up = Input.is_action_pressed("up")
	down = Input.is_action_pressed("down")
	jump = Input.is_action_just_pressed("jump")
	fly = Input.is_action_pressed("jump")
	crouch = Input.is_action_just_pressed("crouch")
	crouching = Input.is_action_pressed("crouch")
	dive = Input.is_action_pressed("crouch")
	fire = Input.is_action_just_pressed("fire")
	firing = Input.is_action_pressed("fire")
	fired = Input.is_action_just_released("fire")
	alt = Input.is_action_pressed("alt")
	use = Input.is_action_just_pressed("interface")
	using = Input.is_action_pressed("interface")
	mode = Input.is_action_just_pressed("mode")
	reload = Input.is_action_just_pressed("reload")
	attacked = Input.is_action_just_released("melee")
	attack = Input.is_action_just_pressed("melee")
	attack_charge = Input.is_action_pressed("melee")
	scroll = Input.is_action_just_pressed("switch")
	scroll_down = Input.is_action_just_released("switchdown")
	scroll_up = Input.is_action_just_released("switchup")
	lethal = Input.is_action_just_released("lethal")
	lethal_hold = Input.is_action_just_pressed("lethal")
	tactical = Input.is_action_just_released("tactical")
	tactical_hold = Input.is_action_just_pressed("tactical")
	lethal_skill = Input.is_action_just_pressed("lethalskill")
	tactical_skill = Input.is_action_just_pressed("tacticalskill")
	skill_mode = Input.is_action_just_pressed("ultimateskill")
	sentry = Input.is_action_just_pressed("sentry")
	armor = Input.is_action_pressed("armor")
	pack = Input.is_action_pressed("inventory")
	inventory = Input.is_action_just_pressed("inventory")
	map = Input.is_action_pressed("map")
	drop = Input.is_action_just_pressed("alt")
	ping = Input.is_action_just_pressed("ping")
	dash = Input.is_action_just_pressed("dash")
	dashing = Input.is_action_pressed("dash")
	aim = Input.is_action_pressed("joyr") or Input.is_action_pressed("joyl") or Input.is_action_pressed("joyu") or Input.is_action_pressed("joyd")
	kick = Input.is_action_just_pressed("kick")
	escape = Input.is_action_just_released("ui_cancel")
