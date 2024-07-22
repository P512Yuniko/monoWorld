extends RigidBody2D

var dmg = 20
var count = 0
var facing = 1
var motion = Vector2()
var back = false
var id = 0
func _physics_process(_delta):
	move_and_collide(motion)
	$CBlade/CBlade2.modulate.a = abs(angular_velocity)/160
	$CBlade2/CBlade2.modulate.a = abs(angular_velocity)/160
	if back:
		if abs(angular_velocity) < 10:
			gravity_scale = 1
		else:
			gravity_scale = -5
		if count > 8:
			motion.x -= 12 * facing
			motion.y += 8
	else:
		gravity_scale = 0
	if count > 15:
		$CollisionShape2D.disabled = true
		$CollisionShape2D2.disabled = true
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.1)
		tween.play()
	if count < 32:
		count += 1
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
		tween.play()
		tween.tween_callback(queue_free)
var collision_pos : Vector2 = Vector2(0.0, 0.0)
func _integrate_forces(state : PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_collider_position(0)
var hit = load("res://Screen/Asset/Entity/Bullet/Blade/HitSlash.tscn")
var kill = load("res://Screen/Asset/Entity/Effect/SlashKill.tscn")
func _on_body_entered(_body):
	if _body.is_in_group("target"):
		if _body.hp < dmg and _body.hp > 0:
			var ins2 = kill.instantiate()
			ins2.global_position = _body.global_position
			get_tree().get_root().add_child(ins2)
	if get_contact_count() > 0:
		var ins = hit.instantiate()
		ins.global_position = collision_pos
		ins.look_at(global_position)
		get_tree().get_root().add_child(ins)
		
func _on_area_2d_area_entered(_area):
	if count > 15:
		queue_free()
