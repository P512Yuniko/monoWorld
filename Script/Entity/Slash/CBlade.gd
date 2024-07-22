extends RigidBody2D

var dmg = 50
var corruptor = false
var up = false
var up_speed = 2000
var knock_back = 200
var push = 0
var id = 0
func _ready():
	$Timer.start(1)

var collision_pos : Vector2 = Vector2(0.0, 0.0)
func _integrate_forces(state : PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_collider_position(0)
var hit = load("res://Screen/Asset/Entity/Bullet/Blade/HitSlash.tscn")
var glitch = load("res://Screen/Asset/Entity/Bullet/Blade/BreakX.tscn")
var kill = load("res://Screen/Asset/Entity/Effect/SlashKill.tscn")
func _on_body_entered(_body):
	if _body.is_in_group("target"):
		if _body.hp <= dmg:
			var ins = kill.instantiate()
			ins.global_position = _body.global_position
			get_tree().get_root().add_child(ins)
			if corruptor:
				var ins2 = glitch.instantiate()
				ins2.global_position = _body.global_position
				get_tree().get_root().add_child(ins2)
	if get_contact_count() > 0:
		var ins = hit.instantiate()
		ins.global_position = collision_pos
		ins.look_at(global_position)
		get_tree().get_root().add_child(ins)
	if _body.get_class() == ("RigidBody2D") and abs(push) > 0:
		if _body.is_in_group("Door"):
			_body.kick()
		_body.apply_impulse(Vector2(push,0), Vector2())
		

func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
	tween.play()
	tween.tween_callback(queue_free)

func _on_area_2d_body_entered(_body):
	if up and _body.get_class() == ("RigidBody2D"):
		_body.apply_impulse(Vector2(0,-up_speed), Vector2())
func out():
	reparent(get_tree().get_root())
func pushing():
	push = knock_back
