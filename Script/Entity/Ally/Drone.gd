extends RigidBody2D

var facing = 1
var time = 0
var bullet = load("res://Screen/Asset/Entity/Bullet/Bullet.tscn")
var shell = load("res://Screen/Asset/Entity/Shell/Shell9.tscn")
var boom = load("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
var dmg = 30
var fire_rate = 0.04
var bullet_speed = 5000
var recoil = 0.1
var current_recoil = 0
var spread = 0

var deploy_count = 0
func _ready():
	$Body.scale.y = facing
func _physics_process(_delta):
	$Body/Gun.rotation_degrees = spread
	if deploy_count < 30:
		gravity_scale = 0.5
		deploy_count += 1
		$Anim.play("Deploy")
		linear_damp = 1
	else:
		if Key.alt:
			$Marker2D.look_at(Operator.crosshair.global_position)
			global_rotation = lerp_angle(global_rotation,$Marker2D.global_rotation,0.1)
			apply_impulse(Vector2(100,0).rotated($Marker2D.global_rotation),Vector2())
		else:
			apply_impulse(Vector2(100,0).rotated(rotation),Vector2())
		set_collision_layer_value(1,true)
		set_collision_layer_value(3,false)
		active()
		
func active():
	gravity_scale = 0
	linear_damp = 0
	$Anim.play("Shoot")
	if !$Fire_delay.time_left > 0:
		var bullet_ins = bullet.instantiate()
		bullet_ins.position = $Body/Gun/Fire.get_global_position()
		bullet_ins.global_rotation_degrees = $Body/Gun/Fire.global_rotation_degrees
		bullet_ins.dmg = dmg
		bullet_ins.speed = bullet_speed
		bullet_ins.apply_impulse(Vector2(bullet_speed, 0).rotated($Body/Gun/Fire.global_rotation), Vector2())
		get_tree().get_root().add_child(bullet_ins)
		var shell_ins = shell.instantiate()
		shell_ins.position = $Body/Gun/Load.get_global_position()
		shell_ins.global_rotation_degrees = $Body/Gun/Load.global_rotation_degrees
		shell_ins.angular_velocity = -20 * facing
		shell_ins.z_index = facing
		shell_ins.apply_impulse(Vector2(randf_range(-220,-180),randf_range(-500, -700) * facing).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(shell_ins)
		$Fire_delay.start(fire_rate)
		$Shoot.play()
		$Body/Gun/Flash.restart()
		$Body/Gun/Flash/Flash2.restart()
	else:
		current_recoil += recoil
		current_recoil = clampf(current_recoil,-4,4)
		spread = randf_range(-current_recoil,current_recoil)
	if time < 300:
		time += 1
	else:
		self_destruction()

func self_destruction():
		var ins = boom.instantiate()
		ins.dmg = 240
		ins.global_position = global_position
		ins.rotation = rotation
		get_tree().get_root().add_child(ins)
		queue_free() 

func _on_body_entered(_body):
	self_destruction()
