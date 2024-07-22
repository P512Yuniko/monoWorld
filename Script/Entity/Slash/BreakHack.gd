extends RigidBody2D

var dmg = 50
var facing = 1
var time = 0
var slashed = false
var id = 0
@onready var slash = preload("res://Screen/Asset/Entity/Bullet/Blade/BreakX.tscn")
func _ready():
	$Timer.start(time)
	$Sprite2D.scale = Vector2(10,0)
	$CollisionShape2D2.scale = Vector2(1,0.02)
	$CollisionShape2D2.position.y = 2500

func _on_timer_timeout():
	if !slashed:
		slashed = !slashed
		$Timer.start(0.2-time)
		var tween = create_tween().set_parallel(true)
		tween.tween_property($Sprite2D, "scale", Vector2(1,10),0.02)
		tween.tween_property($CollisionShape2D2, "scale", Vector2(1,1),0.02)
		tween.tween_property($CollisionShape2D2, "position", Vector2(0,0),0.02)
		tween.play()
	else:
		$CollisionShape2D2.disabled = true
		var tween = create_tween()
		tween.tween_property($Sprite2D, "self_modulate", Color(1,1,1,0), randf_range(0.05,0.5))
		tween.chain().tween_property(self, "modulate", Color(1,1,1,0), randf_range(1,5))
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
