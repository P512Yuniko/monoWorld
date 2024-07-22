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
	angular_velocity = 0
func _process(_delta):
	if $Detect.is_colliding() and !trigged:
		trigged = true
		apply_impulse(Vector2(0,-1000),Vector2())
	if trigged:
		count += 1
		$Circle2.scale.x = lerpf($Circle2.scale.x,3,0.1)
		$Circle2.scale.y = $Circle2.scale.x
	if count > 30:
		var ins = boom.instantiate()
		ins.dmg = 260
		ins.id = id
		ins.global_position = global_position
		get_tree().get_root().add_child(ins)
		queue_free()
	if $Land.is_colliding():
		physics_material_override.bounce = 0
		$Detect.enabled = true
func _on_area_2d_body_entered(_body):
	if _body.is_in_group("bullet"):
		count += 31
