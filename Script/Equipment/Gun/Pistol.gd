extends Node2D

var gun = 00
var code = 00
var ammo
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell9.tscn")
var fire = false
var firing = false
var reload = false
var mode = false
var buffering = 0
var shoot = false
var can_fire = true
var fire_delay = false
var burst = false
var burst_wait = false
var burst_delay = false
var burst_count = 0
var coiling = false
var left_ammo = 0
var current_ammo = 0
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
var mag = load("res://Screen/Asset/Entity/Mag/Mag9.tscn")
var facing = 1
var walk = false
var slide = false
var wait = false
var block = false
var action = false
var smoke = 0
var recoil = 0
var max_spread = 0
var max_ammo = 0
var aim_speed = 0
@export var dmg = 30
@export var bullet_speed = 5000
@export var fire_rate = 0.2
@export var burst_time = 3
@export var base_recoil = 0.1
@export var base_spread = 2.0
@export var base_ammo = 12
var reverse_ammo = 0
@export var empty_time = 1.5
@export var tac_time = 1
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
	if fire:
		buffering = 5
	buffering = move_toward(buffering,0,60.0/Engine.physics_ticks_per_second)
	if shoot:
		current_ammo -= 1
		burst_count -= 1
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
		shell_ins.apply_impulse(Vector2(randf_range(-220,-180),randf_range(-500, -700) * facing).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(shell_ins)
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
		if smoke > 4:
			$Body/Smoke.restart()
	if (firing or buffering > 0) and can_fire and current_ammo > 0:
		if burst:
			if !burst_wait:
				$Burst.start(fire_rate * 2)
		else:
			burst_count = burst_time
			if !fire_delay:
				shoot = true
				$Firedelay.start(fire_rate)
			else:
				shoot = false
		if tac_loading:
			$Tac.stop()
			tac_loading = false
	else:
		shoot = false
	if $Burst.time_left > 0 and current_ammo > 0:
		burst_wait = true
	else:
		burst_wait = false
		burst_count = burst_time
	if burst:
		if burst_wait and !burst_delay and burst_count > 0 and current_ammo > 0:
			shoot = true
			$Burstdelay.start(fire_rate/6)
		else:
			shoot = false
		fire_mode = 07
	else:
		burst_count = 0
		fire_mode = 52
	if mode and !$Mode.time_left > 0:
		$Mode.start(0.2)
		$Mode2.play()
	if reload and can_reload:
		$Tac.start(tac_time)
	elif current_ammo < 1 and can_reload:
		$Empty.start(empty_time)
		$Burst.stop()
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
	elif ammo[1] < 1:
		can_reload = false
	else:
		can_reload = true
func _physics_process(_delta):
	if $Firedelay.time_left > 0:
		fire_delay = true
	elif $Burstdelay.time_left > 0:
		burst_delay = true
		fire_delay = true
	else:
		burst_delay = false
		fire_delay = false
	if $Mode.time_left > 0:
		mode_changing = true
	else:
		mode_changing = false
	if smoke >= 0:
		smoke -= 0.2
	if !burst and $Firedelay.time_left < fire_rate * 3/4 and buffering > 0 and can_fire and current_ammo > 0:
		$Firedelay.stop()
		fire_delay = false
	if $Burst.time_left < fire_rate * 3/4 and buffering > 0 and can_fire and current_ammo > 0:
		$Burst.stop()
	if $Firedelay.time_left > fire_rate/4 or $Burstdelay.time_left > 0:
		coiling = true
	else:
		coiling = false
	if switching or block or action:
		reloading = false
		tac_loading = false
		empty_loading = false
		can_fire = false
		$Tac.stop()
		$Tac2.stop()
		$Empty.stop()
		$Empty2.stop()
	if fire_delay:
		$Anim.playback_default_blend_time = 0
		if current_ammo > 1:
			$Anim.play("Shoot")
		elif current_ammo < 1:
			$Anim.play("Last")
	elif tac_loading:
		$Anim.play("Tac")
	elif empty_loading:
		can_fire = false
		$Anim.play("Empty")
	elif $Mode.time_left > 0:
		can_fire = false
		$Anim.play("Mode")
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
	$Body/Counter.text = str(current_ammo)
	$Body/Counter.scale.x = facing
	if facing == 1:
		$Body/Upper.frame = 2
	else:
		$Body/Upper.frame = 1
	reverse_ammo = ammo[1]
	if max_ammo - current_ammo > ammo[1]:
		left_ammo = ammo[1]
	else:
		left_ammo = max_ammo - current_ammo
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
	aim_speed = 0.1
	if muzzle == 0 or muzzle > 3:
		$Body/Muzzle.hide()
		$Flash.show()
		$Flash.position.x = 110
		$Body/Smoke.position.x = 36
		$Gas.position.x = 115
	else:
		$Body/Muzzle.show()
		$Flash.position.x = 130
		$Body/Smoke.position.x = 54
		if muzzle == 1:
			$Flash.hide()
			$Body/Muzzle.frame = 12
			$Gas.position.x = 160
		elif muzzle == 2:
			$Flash.show()
			$Body/Muzzle.frame = 13
			recoil -= base_recoil/4
			$Gas.position.x = 135
		elif muzzle == 3:
			$Flash.show()
			$Body/Muzzle.frame = 14
			max_spread -= base_spread/4
			$Gas.position.x = 145
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
func _on_Empty_timeout():
	reloading = false
	empty_loading = false
func _on_Tac_timeout():
	reloading = false
	tac_loading = false
func tacloaded():
	if ammo[1] > 0 and left_ammo < ammo[1]:
		current_ammo += left_ammo + 1
		ammo[1] -= left_ammo + 1
	else:
		current_ammo += left_ammo
		ammo[1] -= left_ammo
func emptyloaded():
	current_ammo += left_ammo
	ammo[1] -= left_ammo
func magout():
	var mag_ins = mag.instantiate()
	mag_ins.position = $Body/MagOut.get_global_position()
	mag_ins.facing = facing
	mag_ins.z_index = -4
	mag_ins.apply_impulse(Vector2(0, 0).rotated(global_rotation), Vector2())
	get_tree().get_root().add_child(mag_ins)
func _on_mode_timeout():
	burst = !burst
