extends RigidBody2D

var motion = Vector2()
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
@onready var piece = preload("res://Screen/Asset/Entity/Object/Piece/Square_piece.tscn")
var state = 0
var hp = 50
var killed = false
var killer = 0
func _physics_process(_delta):
	$HP.value = hp
	$HP.max_value = 50
	if hp >= 1:
		active()
		set_collision_mask_value(3,false)
	else:
		$Anim.play("Idle")
		set_collision_mask_value(3,true)
		$Countdown.stop()
		lock_rotation = false
		if !killed:
			Operator.kill(killer,0)
			killed = true
		await get_tree().create_timer(1).timeout
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
		tween.play()
		tween.tween_callback(queue_free)
func active():
	move_and_collide(motion)
	$Timer.autostart = true
	$Timer.wait_time = randi_range(4,8)
	if state == 1:
		motion.x = 4
		$Detect.scale.x = 1
		$Anim.play("Move")
		$Body.scale.x = 1
	elif state == 2:
		motion.x = -4
		$Detect.scale.x = -1
		$Anim.play("Move")
		$Body.scale.x = -1
	elif $Countdown.time_left > 0:
		$Anim.play("Blow")
		motion.x = 0
	else:
		motion.x = 0
		$Anim.play("Idle")
	if $RightEdge.is_colliding() and $LeftEdge.is_colliding():
		await get_tree().create_timer(0.2).timeout
		if $RightEdge.is_colliding() and $LeftEdge.is_colliding():
			lock_rotation = true
	else:
		await get_tree().create_timer(0.2).timeout
		if !$RightEdge.is_colliding() or !$LeftEdge.is_colliding():
			lock_rotation = false
	if !$RightEdge.is_colliding() and !$LeftEdge.is_colliding():
		state = 0
	if $Detect.is_colliding() and $Detect.get_collider(0)!= null:
		if $Detect.get_collider(0).get_parent()!= null and $Detect.get_collider(0).get_parent().is_in_group("Conqueror"):
			$Body/Ohno.show()
			state = 0
			$Countdown.start(0.5)
			$Detect.enabled = false
	elif $RightWall.is_colliding() and $LeftWall.is_colliding():
		state = 0
	else:
		if $RightWall.is_colliding() or !$RightEdge.is_colliding():
			if state == 1:
				state = 2
		elif $LeftWall.is_colliding() or !$LeftEdge.is_colliding():
			if state == 2:
				state = 1
		
func _on_timer_timeout():
	state = randi_range(0,3)
	$Timer.start()

func _on_area_body_entered(body):
	if body.is_in_group("bullet") or body.is_in_group("slash"):
		if hp > 0:
			Operator.dmg_dealt += body.dmg
			hp -= body.dmg
			if body.is_in_group("slash"):
				Operator.slash(body.id,body.dmg)
				killer = body.id
				if !$RightEdge.is_colliding() and !$LeftEdge.is_colliding():
					apply_impulse(Vector2(0,-1000), Vector2())
			else:
				Operator.hit(body.id,body.dmg)
				killer = body.id
		for i in range(randi_range(1,4)):
			var ins = piece.instantiate()
			ins.global_position = global_position
			ins.angular_velocity = randf_range(-20,20)
			ins.apply_impulse(Vector2(randf_range(body.linear_velocity.x - 400,body.linear_velocity.x + 400),randf_range(body.linear_velocity.y - 400,body.linear_velocity.y + 400)).rotated(0), Vector2())
			get_tree().get_root().call_deferred("add_child",ins)
			i += 1
		var tween = create_tween()
		tween.tween_property($Body.material, "shader_parameter/color", Color(1,1,1,1), 0)
		tween.chain().tween_property($Body.material, "shader_parameter/color", Color(0,0,0,1), 0.1)
		tween.play()
		if hp > 0:
			$Body.modulate = Color(1,1,1)
		else:
			$Body.modulate = Color(0.3,0.3,0.3)
func _on_area_area_entered(area):
	if area.get_parent().is_in_group("fire"):
		$Body.modulate = Color(0.3,0.3,0.3)
		hp -= int(area.get_parent().dmg)
		Operator.dmg_dealt += int(area.get_parent().dmg)
		var tween = create_tween()
		tween.tween_property($Body.material, "shader_parameter/color", Color(1,1,1,1), 0)
		tween.chain().tween_property($Body.material, "shader_parameter/color", Color(0,0,0,1), 0.1)
		tween.play()
		if hp > 0:
			$Body.modulate = Color(1,1,1)
			Operator.hit(area.get_parent().id,area.get_parent().dmg)
			killer = area.get_parent().id
		else:
			$Body.modulate = Color(0.3,0.3,0.3)
		
func _on_countdown_timeout():
	var ins = boom.instantiate()
	ins.dmg = 120
	ins.global_position = global_position
	get_tree().get_root().add_child(ins)
	queue_free() 


