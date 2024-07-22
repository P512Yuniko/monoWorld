extends RigidBody2D

var hp = 200
var time = 1800
var ammo = 200
var detecting = false
var dmg = 30
var fire_rate = 0.05
var bullet_speed = 5000
var smoke = 0
var facing = 1
var aiming = 20
var recoil = 0.1
var current_recoil = 0
var spread = 0
var direct = 1
var scan_speed = 0
var scan_facing = 1
@onready var bullet = preload("res://Screen/Asset/Entity/Bullet/Bullet.tscn")
@onready var shell = preload("res://Screen/Asset/Entity/Shell/Shell556.tscn")
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
func active():
	if aiming < 20 and !$Firedelay.time_left > 0:
		var bullet_ins = bullet.instantiate()
		bullet_ins.position = $Body/Hub/Fire.get_global_position()
		bullet_ins.global_rotation_degrees = $Body/Hub/Fire.global_rotation_degrees
		bullet_ins.dmg = dmg
		bullet_ins.speed = bullet_speed
		bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated($Body/Hub/Fire.global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_ins)
		var shell_ins = shell.instantiate()
		shell_ins.position = $Body/Hub/Gun/Load.get_global_position()
		shell_ins.global_rotation_degrees = $Body/Hub/Gun/Load.global_rotation_degrees
		shell_ins.angular_velocity = -20 * facing
		shell_ins.z_index = -1 * facing
		shell_ins.apply_impulse(Vector2(randf_range(-220,-180), randf_range(-500,-700) * facing).rotated($Body/Hub/Gun/Load.global_rotation), Vector2())
		get_tree().get_root().add_child(shell_ins)
		$Firedelay.start(fire_rate)
		$Shoot.play()
		$Body/Hub/Gas.restart()
		$Body/Hub/Flash.restart()
		$Body/Hub/Flash/Flash2.restart()
		smoke += 2
		ammo -= 1
	if $Body/Hub/Gun/Detech.is_colliding() and $Body/Hub/Gun/Detech.get_collider() != null and $Body/Hub/Gun/Detech.get_collider().get_parent() != null and $Body/Hub/Gun/Detech.get_collider().get_parent().is_in_group("target"):
		if aiming > 0:
			aiming -= 4
	else:
		if aiming < 40:
			aiming += 1
	$Body/Hub.rotation_degrees = $Body/Recoil.rotation_degrees * facing + spread
	$Body/Hub/Gun/Aim/FocusU.rotation_degrees = -aiming * 1.5
	$Body/Hub/Gun/Aim/FocusD.rotation_degrees = aiming * 1.5
	if detecting:
		$Body/Recoil.rotation_degrees += scan_speed
		scan_speed = lerpf(scan_speed,direct * 2 * facing,0.5)
	else:
		if aiming > 20:
			$Body/Recoil.rotation_degrees += scan_speed
		scan_speed = lerpf(scan_speed, scan_facing * facing,0.05)
		if $Body/Hub/Gun/RotateR.is_colliding():
			scan_facing = -1
		if $Body/Hub/Gun/RotateL.is_colliding():
			scan_facing = 1
	if $Body/Hub/Gun/Detech.is_colliding() and $Body/Hub/Gun/Detech.get_collider() != null and $Body/Hub/Gun/Detech.get_collider().get_parent() != null and $Body/Hub/Gun/Detech.get_collider().get_parent().is_in_group("target"):
		detecting = true
		direct = 0
	elif $Body/Hub/Gun/Detech1.is_colliding() and $Body/Hub/Gun/Detech1.get_collider() != null and $Body/Hub/Gun/Detech1.get_collider().get_parent() != null and $Body/Hub/Gun/Detech1.get_collider().get_parent().is_in_group("target"):
		detecting = true
		direct = -0.5
	elif $Body/Hub/Gun/Detech2.is_colliding() and $Body/Hub/Gun/Detech2.get_collider() != null and $Body/Hub/Gun/Detech2.get_collider().get_parent() != null and $Body/Hub/Gun/Detech2.get_collider().get_parent().is_in_group("target"):
		detecting = true
		direct = 0.5
	elif $Body/Hub/Gun/DetechUp.is_colliding() and $Body/Hub/Gun/DetechUp.get_collider() != null and $Body/Hub/Gun/DetechUp.get_collider().get_parent() != null and $Body/Hub/Gun/DetechUp.get_collider().get_parent().is_in_group("target") and !$Body/Hub/Gun/RotateL.is_colliding():
		detecting = true
		$Body/Hub/Gun/DetechUp.look_at($Body/Hub/Gun/DetechUp/Tracker.get_collision_point(0))
		if aiming > 20 and !$Body/Hub/Gun/Detech.is_colliding():
			direct = -1
	elif $Body/Hub/Gun/DetechDown.is_colliding() and $Body/Hub/Gun/DetechDown.get_collider() != null and $Body/Hub/Gun/DetechDown.get_collider().get_parent() != null and $Body/Hub/Gun/DetechDown.get_collider().get_parent().is_in_group("target") and !$Body/Hub/Gun/RotateR.is_colliding():
		detecting = true
		$Body/Hub/Gun/DetechDown.look_at($Body/Hub/Gun/DetechDown/Tracker.get_collision_point(0))
		if aiming > 20 and !$Body/Hub/Gun/Detech.is_colliding():
			direct = 1
	else:
		detecting = false
		direct = 0
		$Body/Hub/Gun/DetechUp.rotation_degrees = lerpf($Body/Hub/Gun/DetechUp.rotation_degrees,-16,0.1)
		$Body/Hub/Gun/DetechDown.rotation_degrees = lerpf($Body/Hub/Gun/DetechDown.rotation_degrees,16,0.1)
	if time > 0 and hp > 0:
		time -= 1
	else:
		var ins = boom.instantiate()
		ins.dmg = 160
		ins.global_position = global_position
		ins.rotation = rotation
		get_tree().get_root().add_child(ins)
		queue_free() 

var picking = 0
func _ready():
	$Deploy.start(1.5)
func _physics_process(_delta):
	$Body.scale.x = facing
	$Body/Hub/Gun.z_index = -facing
	$HitBox.time = time
	picking = $HitBox.picking
	$HP.value = hp
	$Pick.value = picking
	$Body/Hub/Gun/Label.text = str(detecting)
	$Body/Hub/Gun/Label.scale.x = facing
	$CollisionLegF.global_position = $Body/LegF/Collision.global_position
	$CollisionLegF.rotation = $Body/LegF/Collision.rotation
	$CollisionLegB.global_position = $Body/LegB/Collision.global_position
	$CollisionLegB.rotation = $Body/LegB/Collision.rotation
	if picking > 0:
		$Pick.show()
	else:
		$Pick.hide()
	if $Grounded.is_colliding():
		gravity_scale = 0
	else:
		gravity_scale = 1
	apply_impulse(Vector2(0,200).rotated($Grounded.global_rotation), Vector2())
	if facing == 1:
		$Body/Hub/Gun.frame = 0
		$Body/Hub/Gun/Muzzle.show_behind_parent = true
	else:
		$Body/Hub/Gun.frame = 1
		$Body/Hub/Gun/Muzzle.show_behind_parent = false
	if !$Deploy.time_left > 0:
		active()
		set_collision_layer_value(3,false)
		freeze = true
	if $Firedelay.time_left > 0:
		$Anim.play("Shoot")
		current_recoil += recoil
		current_recoil = clampf(current_recoil,-1,1)
		spread = randf_range(-current_recoil,current_recoil)
	elif $Deploy.time_left > 0:
		$Body/Hub/Gun/Aim.scale.x = 0
		if $Grounded.rotation_degrees > 45:
			$Anim.play("Starting_Left")
		if $Grounded.rotation_degrees < -45:
			$Anim.play("Starting_Right")
		else:
			$Anim.play("Starting_Down")
	else:
		$Anim.play("Idle")
		$Body/Hub/Gun/Aim.scale.x = lerpf($Body/Hub/Gun/Aim.scale.x,7,0.05)
		current_recoil = lerpf(current_recoil,0,0.5)
		spread = lerpf(spread,0,0.5)

func hurt(area):
	if area.get_parent().is_in_group("danger"):
		hp -= area.get_parent().dmg
