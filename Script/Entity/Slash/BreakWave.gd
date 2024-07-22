extends RigidBody2D

var dmg = 25 
var facing = 1
var id = 0
@onready var slash = preload("res://Screen/Asset/Entity/Bullet/Blade/BreakX.tscn")
func _ready():
	$Timer.start(0.5)
	$Sprite2D.scale.x = facing

func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 1)
	tween.play()
	tween.tween_callback(queue_free)
	
var collision_pos : Vector2 = Vector2(0.0, 0.0)
func _integrate_forces(state : PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_collider_position(0)
var hit = load("res://Screen/Asset/Entity/Bullet/Blade/HitSlash.tscn")
var glitch = load("res://Screen/Asset/Entity/Bullet/Blade/BreakX.tscn")
var kill = load("res://Screen/Asset/Entity/Effect/SlashKill.tscn")
func _on_body_entered(_body):
	if _body.is_in_group("target"):
		if get_contact_count() > 0:
			var ins = glitch.instantiate()
			ins.global_position = _body.global_position
			get_tree().get_root().add_child(ins)
		if _body.hp < dmg and _body.hp > 0:
			var ins2 = kill.instantiate()
			ins2.global_position = _body.global_position
			get_tree().get_root().add_child(ins2)
	if get_contact_count() > 0:
		var ins = hit.instantiate()
		ins.global_position = collision_pos
		ins.look_at(global_position)
		get_tree().get_root().add_child(ins)
