extends Node2D

var gun = 22
var code = 22
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet12.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell12.tscn")
var fire = false
var firing = false
var reload = false
var mode = false
var buffering = 0
var can_fire = true
var fire_delay = false
var left_ammo = 0
var current_ammo = max_ammo
var can_reload = true
var empty_loading = false
var tac_loading = false
var reloading = false
var take = false
var on = false
var off = false
var mode_changing = false
var fire_mode = 55
var switching = false
var wait = false
var facing = 0
var walk = false
var slide = false
var coiling = false
var block = false
var action = false
var smoke = 0
var recoil = 0
var max_spread = 0
var max_ammo = 0
var bullet_speed = 0
var aim_speed = 0
@export var base_speed = 4000
@export var fire_rate = 0.03
@export var dmg = 15
@export var base_recoil = 0.2
@export var base_spread = 4.0
@export var base_ammo = 2
var reverse_ammo = 0
@export var empty_time = 1.5
@export var tac_time = 1.2
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
var speed_muzzle = 0
var aim_grip = 0
var aim_stock = 0
var aim_laser = 0
func _ready():
	ammo = get_parent().ammo
	current_ammo = int((gun%1000000000)/1000000)
	scope = int((gun%1000000)/100000)
	foregrip = int((gun%100000)/10000)
	muzzle = int((gun%10000)/1000)
	magazine = int((gun%1000)/100)
	laser = int((gun%100)/10)
	stock = int((gun%10))
	attach()
	$Anim.play("Take")
func current():
	if fire:
		buffering = 4
	buffering = move_toward(buffering,0,60.0/Engine.physics_ticks_per_second)
	if buffering > 0 and !fire_delay and can_fire and current_ammo > 0:
		current_ammo -= 1
		for i in 12:
			var bullet_ins = bullet.instantiate()
			bullet_ins.position = $Fire.get_global_position()
			bullet_ins.rotation_degrees = rotation_degrees
			bullet_ins.dmg = dmg
			bullet_ins.type = type
			bullet_ins.id = get_parent().get_parent().id
			bullet_ins.sup = !$Flash.visible
			bullet_ins.speed = bullet_speed
			bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated(rotation + (-0.22 + i * 0.04) * (1 - spread_muzzle)), Vector2())
			get_tree().get_root().add_child(bullet_ins)
		$Firedelay.start(fire_rate)
		$Gas.restart()
		$Body/Barrel/Smoke.restart()
		$Body/Barrel/Smoke2.restart()
		if current_ammo < max_ammo:
			$Body/Barrel/Smoke2.restart()
		if muzzle == 1:
			$ShootSup.play()
		else:
			$Shoot.play()
			$Flash.restart()
			$Flash/Flash2.restart()
	if reload and can_reload and !empty_loading and ammo[2] > 0:
		$Tac.start(tac_time)
	elif current_ammo < 1 and can_reload and !fire_delay:
		if ammo[2] > 2:
			$Empty.start(empty_time)
		elif ammo[2] == 1:
			$Tac.start(tac_time)
	if $Empty.time_left > 0:
		reloading = true
		empty_loading = true
	elif $Tac.time_left > 0:
		reloading = true
		tac_loading = true
	else:
		reloading = false
	if reloading:
		can_reload = false
	elif current_ammo == max_ammo:
		can_reload = false
	elif ammo[2] < 1:
		can_reload = false
	else:
		can_reload = true
func _physics_process(_delta):
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	coiling = fire_delay
	if switching or block or action:
		reloading = false
		tac_loading = false
		empty_loading = false
		can_fire = false
		$Tac.stop()
		$Tac2.stop()
		$Empty.stop()
		$Empty2.stop()
	if $Firedelay.time_left > 0:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Shoot")
	elif tac_loading:
		can_fire = false
		$Anim.play("Tac")
	elif empty_loading:
		can_fire = false
		$Anim.play("Empty")
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
	$Shell.z_index = -facing
	$Shell2.z_index = -facing
	$Body/Barrel/Laser.z_index = -facing
	$Body/Barrel/Counter.text = str(current_ammo)
	$Body/Barrel/Counter.scale.x = facing
	reverse_ammo = ammo[2]
	left_ammo = max_ammo - current_ammo
	if max_ammo - current_ammo > ammo[2]:
		left_ammo = ammo[2]
func stop():
	$Tac.stop()
	$Tac2.stop()
	$Empty.stop()
	$Empty2.stop()
	$Take.stop()
	$Take2.stop()
	reloading = false
	tac_loading = false
	empty_loading = false
	can_fire = false
func attach():
	recoil = base_recoil
	max_spread = base_spread
	max_ammo = base_ammo
	aim_speed = 0
	spread_muzzle = 0
	bullet_speed = base_speed
	if muzzle == 0:
		$Body/Barrel/Muzzle.hide()
		$Flash.show()
		$Flash.position.x = 163
		$Body/Barrel/Smoke.position.x = 62
		$Body/Barrel/Smoke2.position.x = 62
		$Gas.position.x = 163
	else:
		$Body/Barrel/Muzzle.show()
		$Flash.position.x = 208
		if muzzle == 1:
			$Flash.hide()
			$Gas.position.x = 225
			$Body/Barrel/Muzzle.frame = 8
		elif muzzle == 2:
			$Flash.show()
			$Gas.position.x = 208
			$Body/Barrel/Smoke.position.x = 107
			$Body/Barrel/Smoke2.position.x = 107
			$Body/Barrel/Muzzle.frame = 9
			spread_muzzle += 0.5
			max_spread -= base_spread/4
			bullet_speed += 2000
	if laser == 0 or laser > 1:
		$Body/Barrel/Laser.hide()
	else:
		$Body/Barrel/Laser.show()
		max_spread -= base_spread/4
		aim_speed += 0.05
	if magazine > 2:
		type = magazine - 2
		recoil += base_recoil/2
		max_spread += base_spread/2
func _on_Empty_timeout():
	reloading = false
	empty_loading = false
func _on_Tac_timeout():
	reloading = false
	tac_loading = false
func loaded():
	if reloading:
		current_ammo += 1
		ammo[2] -= 1
func shellout():
	var shell_ins = shell.instantiate()
	shell_ins.position = $Body/Barrel/Load.get_global_position()
	shell_ins.global_rotation_degrees = global_rotation_degrees
	shell_ins.z_index = 4 * facing
	shell_ins.apply_impulse(Vector2(randf_range(-480,-240), 0).rotated($Body/Barrel.global_rotation), Vector2())
	get_tree().get_root().add_child(shell_ins)
func shellout2():
	var shell_ins = shell.instantiate()
	shell_ins.position = $Body/Barrel/Load.get_global_position()
	shell_ins.global_rotation_degrees = global_rotation_degrees
	shell_ins.z_index = 4 * facing
	shell_ins.apply_impulse(Vector2(randf_range(-480,-240), 0).rotated($Body/Barrel.global_rotation), Vector2())
	get_tree().get_root().add_child(shell_ins)
	var shell_ins_2 = shell.instantiate()
	shell_ins_2.position = $Body/Barrel/Load2.get_global_position()
	shell_ins_2.global_rotation_degrees = global_rotation_degrees
	shell_ins_2.z_index = 4 * facing
	shell_ins_2.apply_impulse(Vector2(randf_range(-480,-240), 0).rotated($Body/Barrel.global_rotation), Vector2())
	get_tree().get_root().add_child(shell_ins_2)
