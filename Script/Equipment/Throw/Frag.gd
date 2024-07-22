extends RigidBody2D
var type = 0
var time = 20
var trigged = false
var count = 0
var id = 0
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
@onready var level = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")
func _ready():
	$Circle2.scale = Vector2(0,0)
func _process(_delta):
	if trigged:
		$NadeTrigger.hide()
		count += 1
		$Circle2.scale.x = lerpf($Circle2.scale.x,3,0.1)
		$Circle2.scale.y = $Circle2.scale.x
	if count > 30:
		var ins = boom.instantiate()
		ins.dmg = 240
		ins.global_position = global_position
		ins.rotation = rotation
		ins.id = id
		get_tree().get_root().add_child(ins)
		queue_free() 
func _on_body_entered(_body):
	if !trigged:
		trigged = true
		var ins = level.instantiate()
		ins.position = global_position
		ins.apply_impulse(Vector2(0,-500).rotated(global_rotation), Vector2())
		get_tree().get_root().call_deferred("add_child",ins)
	
	
