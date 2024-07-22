extends RigidBody2D

var dmg = 100
var count = 0
var id = 0
func _ready():
	$Effect.restart()
func _physics_process(_delta):
	if count < 2000:
		count += 1
	else:
		queue_free()

var collision_pos : Vector2 = Vector2(0.0, 0.0)
func _integrate_forces(state : PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_collider_position(0)
@onready var hit = preload("res://Screen/Asset/Entity/Bullet/Blade/HitSlash.tscn")
func _on_body_entered(body):
	if body.is_in_group("target"):
		Operator.emit_signal("hit")
	if get_contact_count() > 0:
		var ins = hit.instantiate()
		ins.global_position = collision_pos
		ins.look_at(global_position)
		get_tree().get_root().add_child(ins)
