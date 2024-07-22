extends Node2D

var gun = 31
var code = 31
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet50.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell50.tscn")
var fire = false
var firing = false
var reload = false
var mode = false
var buffering = 0
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
var fire_mode = 55
var switching = false
var mag = load("res://Screen/Asset/Entity/Mag/Mag762.tscn")
var mag_rotate = 0
var facing = 0
var walk = false
var slide = false
var wait = false
var block = false
var action = false
var smoke = 0
var recoil = 0.0
var max_spread = 0.0
var max_ammo = 0
var aim_speed = 0
@export var dmg = 75
@export var bullet_speed = 12000
@export var fire_rate = 0.1
@export var base_ammo = 10
var reverse_ammo = 0
@export var empty_time = 2.4
@export var tac_time = 2
@export var base_recoil = 0.2
@export var base_spread = 4.0
var type = 0
var charge = 0
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
	if firing and !fire_delay and can_fire and current_ammo > 0 and charge <= 50:
		charge += 1
		$Recoil.position.x -= 0.05
	if (!firing and charge > 0 or charge == 50) and !fire_delay and can_fire and current_ammo > 0:
		current_ammo -= 1
		var bullet_ins = bullet.instantiate()
		bullet_ins.position = $Fire.get_global_position()
		bullet_ins.global_rotation_degrees = global_rotation_degrees
		bullet_ins.dmg = dmg + charge * 2
		bullet_ins.speed = bullet_speed
		bullet_ins.type = type
		bullet_ins.id = get_parent().get_parent().id
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
		$Charge.stop()
		charge = 0
		$Shoot.play()
		$Flash.restart()
		$Flash/Flash2.restart()
		$Flash/Flash3.restart()
		$Body/Smoke.restart()
		$Gas.restart()
		if tac_loading:
			$Tac.stop()
			$Tac2.stop()
			tac_loading = false
	if reload and can_reload:
		$Tac.start(tac_time)
	elif current_ammo < 1 and can_reload and !get_parent().aim:
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
	if $Firedelay.time_left > 0:
		fire_delay = true
	else:
		fire_delay = false
	coiling = fire_delay
	reverse_ammo = ammo[3]
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
		if current_ammo >= 1:
			$Anim.play("Shoot")
		else:
			$Anim.play("Last")
	elif tac_loading:
		$Anim.play("Tac")
	elif empty_loading:
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
	elif switching:
		can_fire = false
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
		if charge > 0:
			$Anim.play("Charge")
		elif walk:
			$Anim.play("Walk")
		elif slide:
			$Anim.play("Slide")
		elif wait:
			$Anim.play("Chill")
		else:
			$Anim.play("Idle")
	$Body/Charge.value = charge
	scale.y = facing
	$Body.frame = 1
	$Body/Bolt/Bolt2.z_index = facing
	$Mag2.z_index = -facing
	$Mag3.z_index = -facing
	$Body/Laser.z_index = facing
	$Body/Counter.text = str(current_ammo)
	$Body/Counter.scale.x = facing
	if facing == 1:
		$Body.frame = 1
	else:
		$Body.frame = 0
	left_ammo = max_ammo - current_ammo
	if max_ammo - current_ammo > ammo[3]:
		left_ammo = ammo[3]
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
	if laser == 0 or laser > 1:
		$Body/Laser.hide()
	else:
		$Body/Laser.show()
		max_spread -= base_spread/4
		aim_speed += 0.05
	if magazine > 2:
		type = magazine - 2
		recoil += base_recoil/2
		max_spread += base_spread/2
func _on_last_timeout():
	if can_reload and !Key.alt:
		$Empty.start(empty_time)
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
	mag_ins.angular_velocity = mag_rotate
	mag_ins.facing = facing
	mag_ins.apply_impulse(Vector2(randf_range(50,100), 0).rotated($Body/MagOut.global_rotation), Vector2())
	get_tree().get_root().add_child(mag_ins)

