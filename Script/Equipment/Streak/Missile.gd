extends RigidBody2D
var dmg = 600
var type = 0
var buffer = 0
var boosted = false
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
func _physics_process(_delta):
	print(Input.get_axis("left","right"))
	apply_impulse(Vector2(100,Input.get_axis("left","right")/2).rotated(global_rotation),Vector2())
	if Key.fire and !boosted:
		if buffer > 0:
			apply_impulse(Vector2(8000,0).rotated(global_rotation),Vector2())
			boosted = true
		else:
			buffer = 12
func _on_body_entered(_body):
	var ins = boom.instantiate()
	ins.dmg = dmg
	ins.global_position = global_position
	ins.rotation = global_rotation
	get_tree().get_root().call_deferred("add_child",ins)
	Operator.serii.get_node("Weapon/Camera2D").enabled = true
	Operator.serii.can_move = true
	Operator.serii.fight = true
	queue_free() 

var cover = load("res://Screen/Asset/Weapon/Streak/MissileCover.tscn")
@onready var piece = preload("res://Screen/Asset/Entity/Object/Piece/Square_piece.tscn")
func _on_timer_timeout():
	for i in 2:
		var ins = cover.instantiate()
		ins.global_position = global_position
		ins.global_rotation_degrees = global_rotation_degrees + 180 * i
		ins.facing = 1 - i * 2
		ins.time = 0.5
		ins.apply_impulse(Vector2(0,-2000 * (1 - i * 2)).rotated(global_rotation),Vector2())
		ins.angular_velocity = -5 * (1 - i * 2)
		get_tree().get_root().add_child(ins)
	for i in 32:
		var ins = piece.instantiate()
		ins.global_position = global_position + Vector2(0,20)
		ins.angular_velocity = randf_range(-20,20)
		ins.apply_impulse(Vector2(randf_range(-400,400),randf_range(-400,400)).rotated(0), Vector2())
		get_tree().get_root().call_deferred("add_child",ins)
	$Sprite2D/Sprite2D2.hide()
	$Sprite2D/Sprite2D3.hide()
	$Jet.emitting = true
	
