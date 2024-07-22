extends Node2D

var gun = "LauncherA"
var code = 40
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet85.tscn")
var fire = false
var firing = false
var reload = false
var mode = false
var can_fire = true
var fire_delay = false
var coiling = false
var aim_speed = 0
@export var dmg = 120.0
@export var bullet_speed = 6000
@export var fire_rate = 0.5
@export var reload_time = 2.5
var reverse_ammo = 0
var max_ammo = 1
var current_ammo = 1
var type = 0
var scope = 0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var recoil = 0.5
var max_spread = 2
var reloading = false
var take = false
var on = false
var off = false
var mode_changing = false
var fire_mode = 55
var switching = false
var facing  = 0
var walk = false
var slide = false
@export var bullet_facing = 0
var wait = false
var block = false
var action = false
func _ready():
	ammo = get_parent().ammo
	current_ammo = int((gun%1000000000)/1000000)
	$Anim.play("Take")
func current():
	if fire and !fire_delay and !reloading and can_fire and current_ammo > 0:
		current_ammo -= 1
		var bullet_ins = bullet.instantiate()
		bullet_ins.position = $Fire.get_global_position()
		bullet_ins.global_rotation_degrees = global_rotation_degrees
		bullet_ins.dmg = dmg
		bullet_ins.id = get_parent().get_parent().id
		bullet_ins.type = type
		bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_ins)
		$Firedelay.start(fire_rate)
		$Flash.restart()
		$Flash/Flash2.restart()
		$Gas.restart()
		$Gas2.restart()
		$Body/Smoke.restart()
	if current_ammo < 1 and ammo[4] > 0 and !fire_delay:
		if !get_parent().aim:
			$Empty.start(reload_time)
	else:
		$Empty.stop()
func _physics_process(_delta):
	reverse_ammo = ammo[4]
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	if $Empty.time_left > 0:
		reloading = true
	else:
		reloading = false
	if $Firedelay.time_left > fire_rate - fire_rate/5:
		coiling = true
	else:
		coiling = false
	if switching or block or action:
		can_fire = false
		reloading = false
		$Empty.stop()
		$Empty2.stop()
	else:
		can_fire = true
	if fire_delay:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Shoot")
	elif reloading:
		$Anim.playback_default_blend_time = 0.25 * Engine.physics_ticks_per_second/60
		$Anim.play("Reload")
	elif take:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Take")
	elif on:
		$Anim.playback_default_blend_time = 0
		$Anim.play("On")
	elif off:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Off")
	elif block:
		$Anim.playback_default_blend_time = 0.25 * Engine.physics_ticks_per_second/60
		$Anim.play("Block")
	elif action:
		$Anim.playback_default_blend_time = 0.25 * Engine.physics_ticks_per_second/60
		$Anim.play("Action")
	else:
		$Anim.playback_default_blend_time = 0.25 * Engine.physics_ticks_per_second/60
		if walk:
			$Anim.play("Walk")
		elif slide:
			$Anim.play("Slide")
		else:
			$Anim.play("Idle")
	scale.y = facing
	$Bullet.z_index = bullet_facing * facing
	if facing == 1:
		$Body.frame = 1
	else:
		$Body.frame = 0
func stop():
	$Empty.stop()
	$Empty2.stop()
	$Take.stop()
	reloading = false
	can_fire = false
func _on_firedelay_timeout():
	if ammo[4] > 0:
		$Empty.start(reload_time)

func loaded():
	current_ammo += 1
	ammo[4] -= 1
