extends RigidBody2D
var time = 400
var trigged = false
var count = 0
var id = 0
@onready var fire = preload("res://Screen/Asset/Entity/Bullet/Fire.tscn")
@onready var level = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")
func _process(_delta):
	if trigged:
		count += 1
		$NadeTrigger.hide()
	if count > 30:
		for i in 10:
			var ins = fire.instantiate()
			ins.dmg = 1
			ins.time = time
			ins.id = id
			ins.global_position = global_position
			ins.apply_impulse(Vector2(randi_range(-2000,2000),randi_range(-500,500)).rotated(0), Vector2())
			get_tree().get_root().add_child(ins)
	if count > 40:
		queue_free() 
func _on_body_entered(_body):
	if !trigged:
		trigged = true
		var ins = level.instantiate()
		ins.position = global_position
		ins.apply_impulse(Vector2(0,-500).rotated(global_rotation), Vector2())
		get_tree().get_root().add_child(ins)
	
