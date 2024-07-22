extends Node2D

var gun = 20
var code = 20
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet12.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell12.tscn")
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
var facing = 0
var walk = false
var slide = false
var wait = false
var spread = 1
var slug = false
var block = false
var action = false
var smoke = 0
var recoil = 0.2
var max_spread = 0
var bullet_speed = 0
var aim_speed = 0
@export var dmg = 21
@export var base_speed = 4000
@export var fire_rate = 0.8
@export var max_ammo = 7
var reverse_ammo = 0
@export var empty_time = 4.2
@export var tac_time = 3
var type = 0
var scope = 0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var spread_muzzle = 0
var speed_muzzle = 0
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
		for i in 12:
			var bullet_ins = bullet.instantiate()
			bullet_ins.position = $Fire.get_global_position()
			bullet_ins.rotation_degrees = rotation_degrees + (-11 + i * 2) * spread * (1 - spread_muzzle)
			bullet_ins.dmg = dmg
			bullet_ins.type = type
			bullet_ins.id = get_parent().get_parent().id
			bullet_ins.sup = !$Flash.visible
			bullet_ins.speed = bullet_speed + speed_muzzle
			bullet_ins.apply_impulse(Vector2(bullet_speed + speed_muzzle, 0).rotated(rotation + (-0.22 + i * 0.04) * spread * (1 - spread_muzzle)), Vector2())
			get_tree().get_root().add_child(bullet_ins)
		if current_ammo >= 1:
			$Firedelay.start(fire_rate)
		else:
			$Last.start(fire_rate/4)
		$Gas.restart()
		if muzzle == 1:
			$ShootSup.play()
		else:
			$Shoot.play()
			$Flash.restart()
			$Flash/Flash2.restart()
			smoke += 2
		if tac_loading:
			$Tac.stop()
			tac_loading = false
		if smoke > 10:
			$Body/Smoke.restart()
		if tac_loading:
			$Tac.stop()
			tac_loading = false
			reloading = false
			$Tac2.stop()
		elif empty_loading:
			$Empty.stop()
			empty_loading = false
			reloading = false
			$Tac2.stop()
	if mode and !$Mode.time_left > 0 and !reloading:
		$Mode.start(0.5)
		$Mode2.play()
	if reload and can_reload:
		$Tac.start(tac_time)
	elif current_ammo < 1 and can_reload:
		$Empty.start(empty_time)
func _physics_process(_delta):
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	if $Firedelay.time_left > fire_rate * 4/5 or $Last.time_left > fire_rate/5:
		coiling = true
	else:
		coiling = false
	if $Mode.time_left > 0:
		mode_changing = true
	else:
		mode_changing = false
	if slug:
		spread = 0.5
		bullet_speed = base_speed + 2000
		fire_mode = 48
	else:
		spread = 1
		bullet_speed = base_speed
		fire_mode = 93
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
	elif empty_loading and !switching:
		$Anim.play("Empty")
	elif !slug and $Mode.time_left > 0:
		can_fire = false
		$Anim.play("Mode")
	elif slug and $Mode.time_left > 0:
		can_fire = false
		$Anim.play_backwards("Mode")
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
	elif switching:
		can_fire = false
		$Tac.stop()
		$Empty.stop()
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
		elif tac_loading and !switching:
			$Anim.play("Tac")
		else:
			$Shell.hide()
			if slug:
				$Anim.play("Idle_2")
			else:
				$Anim.play("Idle")
	scale.y = facing
	$Body/Mode.z_index = -1 * facing
	if facing == 1:
		$Body.frame = 1
	else:
		$Body.frame = 0
	left_ammo = max_ammo - current_ammo
	if max_ammo - current_ammo > ammo[2]:
		left_ammo = ammo[2]
	if ammo[2] < 1:
		can_reload = false
		reloading = false
		tac_loading = false
		empty_loading = false
		$Tac.stop()
		$Empty.stop()
	reverse_ammo = ammo[2]
	if $Empty.time_left > 0 and !switching:
		reloading = true
		empty_loading = true
	elif $Tac.time_left > 0 and current_ammo < max_ammo and !switching:
		reloading = true
		tac_loading = true
	else:
		reloading = false
		tac_loading = false
	if reloading:
		can_reload = false
	elif current_ammo == max_ammo:
		can_reload = false
	elif ammo[2] < 1:
		can_reload = false
	else:
		can_reload = true
		$Tac.stop()
		$Empty.stop()
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
	spread_muzzle = 0
	speed_muzzle = 0
	if scope == 0 or scope > 2:
		$Body/Scope.hide()
	else:
		$Body/Scope.show()
		if scope == 1:
			$Body/Scope.frame = 0
			aim_speed += 0.05
		elif scope == 2:
			$Body/Scope.frame = 1
	if muzzle == 0 or muzzle > 2:
		$Body/Muzzle.hide()
		$Flash.show()
		$Flash.position.x = 167
		$Body/Smoke.position.x = 77
		$Gas.position.x = 167
	else:
		$Body/Muzzle.show()
		$Flash.position.x = 210
		if muzzle == 1:
			$Flash.hide()
			$Gas.position.x = 228
			$Body/Muzzle.frame = 8
		elif muzzle == 2:
			$Flash.show()
			$Body/Smoke.position.x = 120
			$Gas.position.x = 210
			$Body/Muzzle.frame = 9
			spread_muzzle += 0.5
			speed_muzzle += 2000
	if stock == 0:
		$Body/Stock.show()
	else:
		$Body/Stock.hide()
		aim_speed += 0.05
	if magazine > 2:
		type = magazine - 2
func _on_last_timeout():
	$Empty.start(empty_time)
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
	shell_ins.position = $Body/Load.get_global_position()
	shell_ins.global_rotation_degrees = $Body/Load.global_rotation_degrees
	shell_ins.angular_velocity = -20 * facing
	shell_ins.z_index = 4 * facing
	shell_ins.apply_impulse(Vector2(randf_range(-220,-180), randf_range(-500, -700) * facing).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(shell_ins)
func _on_mode_timeout():
	slug = !slug
