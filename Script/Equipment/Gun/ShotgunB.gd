extends Node2D

var gun = 21
var code = 21
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
var max_spread = 0
var max_ammo = 0
var bullet_speed = 0
var aim_speed = 0
@export var base_speed = 4000
@export var fire_rate = 0.1
@export var dmg = 9
@export var base_recoil = 0.2
@export var base_spread = 6.0
@export var base_ammo = 8
var reverse_ammo = 0
@export var empty_time = 1.9
@export var tac_time = 1.7
var type = 0
var scope = 0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var spread_muzzle = 0
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
	if fire:
		buffering = 8
	buffering = move_toward(buffering,0,60.0/Engine.physics_ticks_per_second)
	if buffering > 0 and !fire_delay and can_fire and current_ammo > 0:
		current_ammo -= 1
		for i in 12:
			var bullet_ins = bullet.instantiate()
			bullet_ins.position = $Fire.get_global_position()
			bullet_ins.rotation_degrees = rotation_degrees + (-11 + i * 2) * (1 - spread_muzzle)
			bullet_ins.dmg = dmg
			bullet_ins.type = type
			bullet_ins.id = get_parent().get_parent().id
			bullet_ins.sup = !$Flash.visible
			bullet_ins.speed = bullet_speed
			bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated(rotation + (-0.11 + i * 0.02) * (1 - spread_muzzle)), Vector2())
			get_tree().get_root().add_child(bullet_ins)
		var shell_ins = shell.instantiate()
		shell_ins.position = $Body/Load.get_global_position()
		shell_ins.global_rotation_degrees = global_rotation_degrees
		shell_ins.angular_velocity = -20 * facing
		shell_ins.z_index = 4 * facing
		shell_ins.apply_impulse(Vector2(randf_range(-220,-180), randf_range(-200, -400) * facing).rotated(global_rotation), Vector2())
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
	if reload and can_reload:
		$Tac.start(tac_time)
	elif current_ammo < 1 and can_reload and !fire_delay:
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
	elif ammo[2] < 1:
		can_reload = false
	else:
		can_reload = true
func _physics_process(_delta):
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	if smoke >= 0 :
		smoke -= 0.2
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
		if magazine == 1:
			$Anim.play("Tac")
		else:
			$Anim.play("Tac_2")
	elif empty_loading:
		can_fire = false
		if magazine == 1:
			$Anim.play("Empty")
		else:
			$Anim.play("Empty_2")
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
	$Mag2.z_index = -1 * facing
	$Mag3.z_index = 1 * facing
	$Body/Laser.z_index = facing
	$Body/Counter.text = str(current_ammo)
	$Body/Counter.scale.x = facing
	if facing == 1:
		$Body.frame = 1
	else:
		$Body.frame = 0
	reverse_ammo = ammo[2]
	left_ammo = max_ammo - current_ammo
	if max_ammo - current_ammo > ammo[2]:
		left_ammo = ammo[2]
func stop():
	$Tac.stop()
	$Tac2.stop()
	$Tac3.stop()
	$Empty.stop()
	$Empty2.stop()
	$Empty3.stop()
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
	if scope == 0:
		$Body/Scope.hide()
	else:
		$Body/Scope.show()
		if scope == 1:
			$Body/Scope.frame = 0
			aim_speed += 0.05
		elif scope == 2:
			$Body/Scope.frame = 1
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
	if muzzle == 0 or muzzle > 2:
		$Body/Muzzle.hide()
		$Flash.show()
		$Flash.position.x = 150
		$Body/Smoke.position.x = 90
		$Gas.position.x = 150
	else:
		$Body/Muzzle.show()
		$Flash.position.x = 190
		if muzzle == 1:
			$Flash.hide()
			$Gas.position.x = 210
			$Body/Muzzle.frame = 8
		elif muzzle == 2:
			$Flash.show()
			$Gas.position.x = 190
			$Body/Smoke.position.x = 125
			$Body/Muzzle.frame = 9
			spread_muzzle += 0.5
			max_spread -= base_spread/4
			bullet_speed += 2000
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
	if magazine == 0 or magazine > 1:
		empty_time = 1.9
		tac_time = 1.7
		$Body/Mag.frame = 6
		$Mag2.frame = 6
		$Mag3.frame = 6
		max_ammo = base_ammo
		mag = load("res://Screen/Asset/Entity/Mag/Mag12.tscn")
	else:
		empty_time = 2.6
		tac_time = 2.2
		$Body/Mag.frame = 4
		$Mag2.frame = 4
		$Mag3.frame = 4
		max_ammo = base_ammo + 10
		mag = load("res://Screen/Asset/Entity/Mag/Mag12B.tscn")
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
func tacloaded():
	if ammo[2] > 0 and left_ammo < ammo[2]:
		current_ammo += left_ammo + 1
		ammo[2] -= left_ammo + 1
	else:
		current_ammo += left_ammo
		ammo[2] -= left_ammo
func emptyloaded():
	current_ammo += left_ammo
	ammo[2] -= left_ammo
func magout():
	var mag_ins = mag.instantiate()
	mag_ins.position = $Body/MagOut.get_global_position()
	mag_ins.angular_velocity = -5 * facing
	mag_ins.facing = facing
	mag_ins.apply_impulse(Vector2(100, 0).rotated($Body/MagOut.global_rotation), Vector2())
	get_tree().get_root().add_child(mag_ins)
	