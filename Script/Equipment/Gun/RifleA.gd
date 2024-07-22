extends Node2D

var gun = 10
var code = 10
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell556.tscn")
@onready var bullet40 = preload("res://Screen/Asset/Entity/Bullet/Bullet40.tscn")
@onready var shell40 = preload("res://Screen/Asset/Entity/Shell/Shell40.tscn")
var fire = false
var firing = false
var reload = false
var mode = false
var buffering = 0
var can_fire = true
var fire_delay = false
var nade_delay = false
var left_ammo = 0
var can_reload = true
var empty_loading = false
var tac_loading = false
var reloading = false
var nade_loading = false
var nade_can_fire = true
var take = false
@export var bolt = false
var on = false
var off = false
var mode_changing = false
var fire_mode = 66
var switching = false
var wait = false
var mag
var facing = 0
var walk = false
var slide = false
var coiling = false
var block = false
var action = false
var smoke = 0
var recoil = 0
var nade = false
var current_ammo = 0
var rifle_ammo = 0
var nade_ammo = 0
var max_spread = 0
var max_ammo = 0
var aim_speed = 0
@export var dmg = 30.0
@export var bullet_speed = 5000
@export var fire_rate = 0.08
@export var nade_fire_rate = 0.2
@export var base_recoil = 0.1
@export var base_spread = 2.0
@export var base_ammo = 30
var reverse_ammo = 0
@export var empty_time = 2
@export var tac_time = 1.8
@export var nade_time = 1.8
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
func _ready():
	ammo = get_parent().ammo
	rifle_ammo = int((gun%1000000000)/1000000)
	scope = int((gun%1000000)/100000)
	foregrip = int((gun%100000)/10000)
	muzzle = int((gun%10000)/1000)
	magazine = int((gun%1000)/100)
	laser = int((gun%100)/10)
	stock = int((gun%10))
	attach()
	bolt = false
	$Anim.play("Take")
	if ammo[4] > 0:
		nade_ammo = 1
		ammo[4] -= 1
func current():
	if fire:
		buffering = 5
	buffering = move_toward(buffering,0,60.0/Engine.physics_ticks_per_second)
	if !nade and (firing or buffering > 0) and !fire_delay and can_fire and current_ammo > 0:
		rifle_ammo -= 1
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
		var shell_ins = shell.instantiate()
		shell_ins.position = $Body/Load.get_global_position()
		shell_ins.global_rotation_degrees = global_rotation_degrees
		shell_ins.angular_velocity = -20 * facing
		shell_ins.z_index = 4 * facing
		shell_ins.apply_impulse(Vector2(randf_range(-220,-180), randf_range(-500, -700) * facing).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(shell_ins)
		$Firedelay.start(fire_rate)
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
			$Tac2.stop()
			tac_loading = false
		if smoke > 10:
			$Body/Smoke.restart()
	if nade and fire and !nade_delay and can_fire and nade_ammo > 0:
		nade_ammo -= 1
		var bullet_ins = bullet40.instantiate()
		bullet_ins.dmg = 40
		bullet_ins.id = get_parent().get_parent().id
		bullet_ins.position = $Nade.get_global_position()
		bullet_ins.global_rotation_degrees = global_rotation_degrees
		bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_ins)
		$Nadedelay.start(nade_fire_rate)
		$Shoot203.play()
		$GasNade.restart()
		$Body/SmokeNade.restart()
		if ammo[4] < 1:
			$Mode.start(0.3)
	if mode and !$Mode.time_left > 0 and foregrip == 3 and ammo[4] > 0:
		$Mode.start(0.3)
		if nade:
			$Mode2.play()
		else:
			$Mode3.play()
	if reload and can_reload:
		$Tac.start(tac_time)
	elif rifle_ammo < 1 and can_reload and !fire_delay:
		$Empty.start(empty_time)
	elif nade and !nade_ammo > 0 and !nade_loading and !get_parent().aim and !nade_delay:
		$Nadeload.start(nade_time)
	if $Empty.time_left > 0:
		reloading = true
		empty_loading = true
		nade_loading = false
	elif $Tac.time_left > 0:
		reloading = true
		tac_loading = true
		nade_loading = false
	elif $Nadeload.time_left > 0:
		nade_loading = true
		reloading = true
	else:
		nade_loading = false
		reloading = false
	if reloading:
		can_reload = false
	elif rifle_ammo == max_ammo + 1:
		can_reload = false
	elif ammo[0] < 1:
		can_reload = false
	else:
		can_reload = true
func _physics_process(_delta):
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	if $Mode.time_left > 0:
		mode_changing = true
	else:
		mode_changing = false
	if $Nadedelay.time_left > 0:
		nade_delay = true
	else:
		nade_delay = false
	if smoke >= 0 :
		smoke -= 0.2
	coiling = fire_delay
	if nade:
		code = 41
		fire_mode = 15
		current_ammo = nade_ammo
		reverse_ammo = ammo[4]
	else:
		code = 10
		current_ammo = rifle_ammo
		reverse_ammo = ammo[0]
		fire_mode = 60
		$Nadeload.stop()
	if switching or block or action:
		reloading = false
		tac_loading = false
		empty_loading = false
		nade_loading = false
		can_fire = false
		$Tac.stop()
		$Tac2.stop()
		$Tac3.stop()
		$Empty.stop()
		$Empty2.stop()
		$Empty3.stop()
		$Nadeload.stop()
		$Load203.stop()
	if $Firedelay.time_left > 0:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Shoot")
	elif $Nadedelay.time_left > 0:
		$Anim.playback_default_blend_time = 0
		$Anim.play("Shoot_Nade")
	elif tac_loading:
		if magazine == 2:
			$Anim.play("Tac_2")
		else:
			$Anim.play("Tac")
	elif empty_loading:
		can_fire = false
		if magazine == 2:
			$Anim.play("Empty_2")
		else:
			$Anim.play("Empty")
	elif nade_loading:
		can_fire = false
		$Anim.play("Nade_loading")
	elif $Mode.time_left > 0:
		can_fire = false
		if !nade:
			$Anim.play("Mode")
		else:
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
		nade = false
		$Anim.playback_default_blend_time = 0
		$Anim.play("Off")
	elif block:
		nade = false
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
			if nade:
				$Anim.play("Idle_Nade")
			else:
				$Anim.play("Idle")
	scale.y = facing
	$Mag2.z_index = -1 * facing
	$Mag3.z_index = 1 * facing
	$Body/Laser.z_index = facing
	$Body/Counter.text = str(current_ammo)
	$Body/Counter.scale.x = facing
	if facing == 1:
		$Body.frame = 1
	else:
		$Body.frame = 0
	left_ammo = max_ammo - rifle_ammo
	if max_ammo - current_ammo > ammo[0]:
		left_ammo = ammo[0]
func stop():
	$Tac.stop()
	$Tac2.stop()
	$Tac3.stop()
	$Empty.stop()
	$Empty2.stop()
	$Empty3.stop()
	$Nadeload.stop()
	$Load203.stop()
	$Take.stop()
	$Take2.stop()
	reloading = false
	tac_loading = false
	empty_loading = false
	nade_loading = false
	can_fire = false
func attach():
	recoil = base_recoil
	max_spread = base_spread
	max_ammo = base_ammo
	aim_speed = 0
	if scope == 0 or scope > 3:
		$Body/Scope.hide()
	else:
		$Body/Scope.show()
		if scope == 1:
			$Body/Scope.frame = 0
			aim_speed += 0.05
		elif scope == 2:
			$Body/Scope.frame = 1
		elif scope == 3:
			$Body/Scope.frame = 2
	if foregrip == 3:
		$Body/Launcher.show()
	else:
		nade = false
		fire_mode = 66
		$Body/Launcher.hide()
	if foregrip == 0 or foregrip > 2:
		$Body/Foregrip.hide()
	else:
		$Body/Foregrip.show()
		aim_speed += 0.05
		if foregrip == 1:
			$Body/Foregrip.frame = 4
			max_spread -= base_spread/4
		elif foregrip == 2:
			$Body/Foregrip.frame = 5
			recoil -= base_recoil/4
	if muzzle == 0 or muzzle > 3:
		$Flash.show()
		$Body/Muzzle.hide()
		$Flash.position.x = 150
		$Gas.position.x = 150
		$Body/Smoke.position.x = 110
	else:
		$Body/Muzzle.show()
		$Flash.position.x = 170
		$Body/Smoke.position.x = 125
		if muzzle == 1:
			$Flash.hide()
			$Body/Muzzle.frame = 8
			$Gas.position.x = 195
		elif muzzle == 2:
			$Flash.show()
			$Body/Muzzle.frame = 9
			recoil -= base_recoil/4
			$Gas.position.x = 165
		elif muzzle == 3:
			$Flash.show()
			$Body/Muzzle.frame = 10
			max_spread -= base_spread/4
			$Gas.position.x = 175
	if laser == 0 or laser > 1:
		$Body/Laser.hide()
	else:
		$Body/Laser.show()
		max_spread -= base_spread/4
		aim_speed += 0.05
	if stock == 0:
		$Body/Stock.show()
	else:
		$Body/Stock.hide()
		aim_speed += 0.1
		recoil += base_recoil/2
		max_spread += base_spread/2
	if magazine == 1:
		tac_time = 1.8
		empty_time = 2.0
		$Body/Mag.frame = 7
		$Mag2.frame = 7
		$Mag3.frame = 7
		max_ammo = base_ammo + 10
		mag = load("res://Screen/Asset/Entity/Mag/Mag556B.tscn")
	elif magazine == 2:
		tac_time = 2
		empty_time = 2.3
		$Body/Mag.frame = 8
		$Mag2.frame = 8
		$Mag3.frame = 8
		max_ammo = base_ammo + 20
		mag = load("res://Screen/Asset/Entity/Mag/Mag556C.tscn")
	else:
		tac_time = 1.8
		empty_time = 2.0
		$Body/Mag.frame = 6
		$Mag2.frame = 6
		$Mag3.frame = 6
		max_ammo = base_ammo
		mag = load("res://Screen/Asset/Entity/Mag/Mag556.tscn")
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
func _on_nadeload_timeout():
	nade_loading = false
	reloading = false
func tacloaded():
	if ammo[0] > 0 and left_ammo < ammo[0]:
		rifle_ammo += left_ammo + 1
		ammo[0] -= left_ammo + 1
	else:
		rifle_ammo += left_ammo
		ammo[0] -= left_ammo
func emptyloaded():
	rifle_ammo += left_ammo
	ammo[0] -= left_ammo
func magout():
	var mag_ins = mag.instantiate()
	mag_ins.position = $Body/MagOut.get_global_position()
	mag_ins.angular_velocity = -5 * facing
	mag_ins.facing = facing
	mag_ins.apply_impulse(Vector2(randf_range(200,100), 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(mag_ins)
func nadeout():
	var nade_ins = shell40.instantiate()
	nade_ins.position = $Body/NadeOut.get_global_position()
	nade_ins.angular_velocity = -5 * facing
	nade_ins.get_node("Smoke").restart()
	nade_ins.apply_impulse(Vector2(randf_range(-200,-100), 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(nade_ins)
func nadeloaded():
	nade_ammo += 1
	ammo[4] -= 1
func _on_mode_timeout():
	nade = !nade
