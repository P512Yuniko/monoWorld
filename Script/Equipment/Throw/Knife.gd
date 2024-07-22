extends RigidBody2D
var dmg = 100
var type = 0
var time = 20.0
var count = 0
var trigged = false
var id = 0
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
func _ready():
	$Circle2.scale = Vector2(0,0)
func _physics_process(_delta):
	if trigged:
		look_at($ShapeCast2D.get_collision_point(0))
		count += 1
		$Circle2.scale.x = lerpf($Circle2.scale.x,3,0.1)
		$Circle2.scale.y = $Circle2.scale.x
	if count > 30:
		var ins = boom.instantiate()
		ins.dmg = 240
		ins.id = id
		ins.global_position = global_position
		ins.rotation = rotation
		get_tree().get_root().add_child(ins)
		queue_free() 
var is_sticking = false
var body_on_which_sticked
var tr_ci_collider_to_ball = Transform2D()

func _integrate_forces( body_state ):
	if is_sticking == false && body_state.get_contact_count() == 1 :
		is_sticking = true
		set_use_custom_integrator(true) 
		body_on_which_sticked = body_state.get_contact_collider_object(0)
		var tr_ci_world_to_ball = get_global_transform()
		var tr_ci_world_to_collider = body_on_which_sticked.get_global_transform()
		tr_ci_collider_to_ball = tr_ci_world_to_collider.inverse() * tr_ci_world_to_ball
	if is_sticking:
		if body_on_which_sticked != null:
			global_transform = body_on_which_sticked.get_global_transform() * tr_ci_collider_to_ball
func _on_body_entered(body):
	if body.is_in_group("target"):
		Operator.emit_signal("hit")
	freeze = true
	trigged = true
	
