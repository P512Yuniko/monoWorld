extends RigidBody2D

var dmg = 100
var corruptor = 0
func _ready():
	modulate.a = 0
	$CollisionShape2D.scale.x = 0

func _process(_delta):
	$AnimationPlayer.play("Process")
func _on_animation_player_animation_finished(_anim_name):
	queue_free()
var collision_pos : Vector2 = Vector2(0.0, 0.0)
func _integrate_forces(state : PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_collider_position(0)
@onready var hit = preload("res://Screen/Asset/Entity/Bullet/Blade/HitSlash.tscn")
@onready var glitch
func _on_body_entered(body):
	if body.is_in_group("target"):
		Operator.emit_signal("slash")
		if get_contact_count() > 0 and corruptor:
			var ins2 = glitch.instantiate()
			ins2.global_position = collision_pos
			ins2.look_at(global_position)
			ins2.restart()
			get_tree().get_root().add_child(ins2)
	if get_contact_count() > 0:
		var ins = hit.instantiate()
		ins.global_position = collision_pos
		ins.look_at(global_position)
		get_tree().get_root().add_child(ins)
