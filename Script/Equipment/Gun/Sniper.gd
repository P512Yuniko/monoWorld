extends Node2D

var gun = 0
var code = 30
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet50.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell50.tscn")
var fire = false
var firing = false
var reload = false
var mode = false
var can_fire = true
var fire_delay = false
var coiling = false
var left_ammo = 0
var current_ammo = max_ammo
var can_reload = true
var empty_loading = false
var tac_loading = false
var reloading = false
var take = false
@export var bolt = false
var on = false
var off = false
var mode_changing = false
var fire_mode = 0
var switching = false
var mag = load("res://Screen/Asset/Entity/Mag/Mag50.tscn")
var facing = 0
var walk = false
var slide = false
var optic = true
var wait = false
var block = false
var action = false
var aim_speed = 0
@export var dmg = 160
var bullet_speed = 0
@export var fire_rate = 0.8
@export var max_ammo = 5
var reverse_ammo = 0
@export var empty_time = 3
@export var tac_time = 2.2
@export var recoil = 0.2
@export var max_spread = 2
var type = 0
var scope = 0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
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
	bolt = false
	$Anim.play("Take")
func current():
	if fire and !fire_delay and can_fire and current_ammo > 0:
		current_ammo -= 1
		var bullet_ins = bullet.instantiate()
		bullet_ins.position = $Fire.get_global_position()
		bullet_ins.global_rotation_degrees = global_rotation_degrees
		bullet_ins.dmg = dmg
		bullet_ins.type = type
		bullet_ins.id = get_parent().get_parent().id
		bullet_ins.speed = bullet_speed
		bullet_ins.sup = !$Flash.visible
		bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_ins)
		if muzzle == 1:
			$ShootSup.play()
		else:
			$Shoot.play()
			$Flash.restart()
			$Flash/Flash2.restart()
			$Flash/Flash3.restart()
			$Body/Smoke.restart()
		$Gas.restart()
		if current_ammo >= 1:
			$Firedelay.start(fire_rate)
		else:
			$Last.start(fire_rate/4)
		if tac_loading:
			$Tac.stop()
			$Tac2.stop()
			tac_loading = false
	if mode and !$Mode.time_left > 0:
		$Mode.start(1.2)
	if reload and can_reload:
		$Tac.start(tac_time)
	elif current_ammo < 1 and can_reload and !get_parent().aim and !fire_delay:
		$Empty.start(empty_time)
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
	elif current_ammo == max_ammo + 1:
		can_reload = false
	elif ammo[3] < 1:
		can_reload = false
	else:
		can_reload = true
func _physics_process(_delta):
	if $Firedelay.time_left > 0 or $Last.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	if $Firedelay.time_left > (fire_rate - fire_rate/4) or $Last.time_left > (fire_rate/2 - fire_rate/4) :
		coiling = true
	else:
		coiling = false
	if $Mode.time_left > 0:
		mode_changing = true
	else:
		mode_changing = false
	reverse_ammo = ammo[3]
	if optic:
		scope = 4
		fire_mode = 84
	else:
		fire_mode = 39
		scope = 0
	if switching or block or action:
		reloading = false
		tac_loading = false
		empty_loading = false
		can_fire = false
		$Tac.stop()
		$Tac2.stop()
		$Empty.stop()
		$Empty2.stop()
		if $Firedelay.time_left < 0.5:
			$Firedelay.stop()
	if $Firedelay.time_left > 0 and !switching:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Shoot")
	elif $Last.time_left > 0:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Last")
	elif tac_loading:
		$Anim.play("Tac")
	elif empty_loading:
		can_fire = false
		$Anim.play("Empty")
	elif take:
		$Anim.playback_default_blend_time = 0
		if bolt and !$Anim.current_animation == "Take":
			$Anim.play("Take_2")
		else:
			$Anim.play("Take")
	elif on:
		$Anim.playback_default_blend_time = 0
		$Anim.play("On")
	elif off:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Off")
	elif optic and $Mode.time_left > 0:
		can_fire = false
		$Anim.play("Mode")
	elif !optic and $Mode.time_left > 0:
		can_fire = false
		$Anim.play_backwards("Mode")
	elif block:
		can_fire = false
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
			if optic:
				$Anim.play("Idle")
			else:
				$Anim.play("Idle_2")
	scale.y = facing
	$Body/Bolt/Lever.z_index = facing
	$Body/Laser.z_index = facing
	$Body/Mag/Ammo.value = current_ammo
	$Body/Counter.text = str(current_ammo)
	$Body/Counter.scale.x = facing
	if facing == 1:
		$Body.frame = 1
		$Body/Scope.show_behind_parent = true
	else:
		$Body.frame = 0
		$Body/Scope.show_behind_parent = false
	left_ammo = max_ammo - current_ammo
	if max_ammo - current_ammo > ammo[3]:
		left_ammo = ammo[3]
func stop():
	$Bolt.stop()
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
	aim_speed = 0
	if muzzle == 0 or muzzle > 2:
		$Body/Muzzle.hide()
		$Flash.show()
		$Flash.position.x = 245
		$Gas.position.x = 245
		bullet_speed = 12000
	else:
		$Body/Muzzle.show()
		if muzzle == 1:
			$Flash.hide()
			$Gas.position.x = 310
			$Body/Muzzle.frame = 8
			bullet_speed = 12000
		elif muzzle == 2:
			$Flash.show()
			$Flash.show()
			$Flash.position.x = 290
			$Gas.position.x = 290
			$Body/Muzzle.frame = 9
			bullet_speed = 15000
	if laser == 0 or laser > 1:
		$Body/Laser.hide()
	else:
		$Body/Laser.show()
		aim_speed += 0.05
	if magazine > 2:
		type = magazine - 2
func _on_Empty_timeout():
	reloading = false
	empty_loading = false
func _on_Tac_timeout():
	reloading = false
	tac_loading = false
func tacloaded():
	if ammo[3] > 0 and left_ammo < ammo[3]:
		current_ammo += left_ammo + 1
		ammo[3] -= left_ammo + 1
	else:
		current_ammo += left_ammo
		ammo[3] -= left_ammo
func emptyloaded():
	current_ammo += left_ammo
	ammo[3] -= left_ammo
func magout():
	var mag_ins = mag.instantiate()
	mag_ins.position = $Body/MagOut.get_global_position()
	mag_ins.angular_velocity = -5 * facing
	mag_ins.facing = facing
	mag_ins.apply_impulse(Vector2(randf_range(50,100), 0).rotated($Body/MagOut.global_rotation), Vector2())
	get_tree().get_root().add_child(mag_ins)
func shellout():
	var shell_ins = shell.instantiate()
	shell_ins.position = $Body/Load.get_global_position()
	shell_ins.global_rotation_degrees = global_rotation_degrees
	shell_ins.angular_velocity = -20 * facing
	shell_ins.z_index = 4 * facing
	shell_ins.apply_impulse(Vector2(randf_range(-220,-180), randf_range(-500, -700) * facing).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(shell_ins)
func _on_mode_timeout():
	optic = !optic
func _on_last_timeout():
	$Empty.start(empty_time)
