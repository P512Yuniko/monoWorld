extends RigidBody2D

var dmg = 20
var count = 0
var facing = 1
var id = 0
func _ready():
	$CBlade.scale.x = -facing
	$CBlade2.scale.x = -facing
func _physics_process(_delta):
	$CBlade2.modulate.a = abs(angular_velocity)/100
	if abs(angular_velocity) < 10:
		gravity_scale = 1
		$CollisionShape2D2.disabled = true
	if count > 5 and abs(angular_velocity) > 20:
		linear_damp = 20
		angular_damp = 2
	else:
		linear_damp = 0
		angular_damp = 0
	if count < 40:
		count += 1
		dmg -= 1
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
