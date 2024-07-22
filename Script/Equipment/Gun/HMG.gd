extends Node2D

var gun = 15
var code = 15
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell556.tscn")
var fire = false
var firing = false
var can_fire = true
var fire_delay = false
var left_ammo = 0
var current_ammo = 95
var can_reload = true
var empty_loading = false
var tac_loading = false
var reloading = false
var take = false
var swap = false
var on = false
var off = false
var mode_changing = false
var fire_mode = 6
var switching = false
var wait = false
var facing = 1
var walk = false
var slide = false
var coiling = false
var block = false
var mode = false
var action = false
var smoke = 0
var recoil = 0
var max_spread = 0
var max_ammo = 0
var aim_speed = 0
@export var dmg = 38
@export var bullet_speed = 5000
@export var fire_rate = 0.03
@export var base_recoil = 0.1
@export var base_spread = 2.0
var reverse_ammo = Inventory.heavy_ammo
var type = 0
var scope = 0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var recoil_grip = 0
var recoil_muzzle = 0
var recoil_stock = 0
var spread_grip = 0
var spread_muzzle = 0
var spread_laser = 0
var spread_stock = 0
var aim_grip = 0
var aim_stock = 0
var aim_laser = 0
var charge = 0
func current():
	if firing and charge < 18:
		charge += 1
		if charge < 2:
			$Spin.play()
	else:
		if charge > 0:
			charge -= 1
	if charge > 16 and !firing:
		$Stop.play()
	if charge > 16 and !fire_delay and can_fire and current_ammo > 0:
		current_ammo -= 1
		var bullet_ins = bullet.instantiate()
		bullet_ins.position = $Fire.get_global_position()
		bullet_ins.global_rotation_degrees = global_rotation_degrees
		bullet_ins.dmg = dmg
		bullet_ins.type = type
		bullet_ins.speed = bullet_speed
		bullet_ins.sup = !$Flash.visible
		bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_ins)
		var shell_ins = shell.instantiate()
		shell_ins.position = $Body/Load.get_global_position()
		shell_ins.global_rotation_degrees = global_rotation_degrees
		shell_ins.angular_velocity = -20 * facing
		shell_ins.z_index = 4 * facing
		shell_ins.apply_impulse(Vector2(randf_range(-220,-180),randf_range(-500, -700) * facing).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(shell_ins)
		$Firedelay.start(fire_rate)
		$Gas.restart()
		$Shoot.play()
		$Flash.restart()
		$Flash/Flash2.restart()
		smoke += 2
		if smoke > 10:
			$Body/Smoke.restart()
func _physics_process(_delta):
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	if smoke >= 0 :
		smoke -= 0.2
	coiling = fire_delay
	recoil = base_recoil
	max_spread = base_spread
	if switching or block:
		can_fire = false
	if charge > 0:
		$Rotate.play("Rotate")
	else:
		$Rotate.play("Idle")
	if $Firedelay.time_left > 0:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Shoot")
	elif take or swap:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Take")
	elif $Empty.time_left > 0:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Out")
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
		can_fire = true
		$Anim.playback_default_blend_time = 0.25 * Engine.physics_ticks_per_second/60
		if walk:
			$Anim.play("Walk")
		elif slide:
			$Anim.play("Slide")
		elif wait:
			$Anim.play("Chill")
		else:
			$Anim.play("Idle")
	scale.y = facing
	$Body/Counter.text = str(current_ammo)
	$Body/Counter.scale.x = facing
	if facing == 1:
		$Body.frame = 0
	else:
		$Body.frame = 1
func _on_take_2_timeout():
	queue_free()
