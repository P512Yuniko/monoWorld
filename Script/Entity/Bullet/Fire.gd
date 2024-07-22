extends RigidBody2D
var count = 0
var time = 0.0
var dmg = 0
var id = 0
func _ready():
	$Timer.start(time/60)
	$BurnDelay.start(0.1)

var is_sticking = false
var body_on_which_sticked
var tr_ci_collider_to_ball = Transform2D()

func _integrate_forces( body_state ):
	if is_sticking == false && body_state.get_contact_count() == 1:
		is_sticking = true
		set_use_custom_integrator(true) 
		body_on_which_sticked = body_state.get_contact_collider_object(0)
		var tr_ci_world_to_ball = get_global_transform()
		if body_on_which_sticked != null:
			var tr_ci_world_to_collider = body_on_which_sticked.get_global_transform()
			tr_ci_collider_to_ball = tr_ci_world_to_collider.inverse() * tr_ci_world_to_ball
	if is_sticking:
		if body_on_which_sticked != null:
			global_transform = body_on_which_sticked.get_global_transform() * tr_ci_collider_to_ball
		else:
			queue_free()

func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 1)
	tween.play()
	tween.tween_callback(queue_free)

func _on_burn_delay_timeout():
	$Area/Collision.disabled = !$Area/Collision.disabled
