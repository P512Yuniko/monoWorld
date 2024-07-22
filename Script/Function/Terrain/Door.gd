extends RigidBody2D
var open = false

func _process(_delta):
	$CollisionShape2D.disabled = open
	$CollisionShape2D2.disabled = !open
	if open:
		$ColorRect.scale.x = lerpf($ColorRect.scale.x,10,0.2)
		$CollisionShape2D.scale.x = lerpf($CollisionShape2D.scale.x,0,0.5)
	else:
		$ColorRect.scale.x = lerpf($ColorRect.scale.x,1,0.2)
		$CollisionShape2D.scale.x = lerpf($CollisionShape2D.scale.x,1,0.5)
func interact():
	open = !open
func kick():
	freeze = false
	apply_impulse(Vector2(2000,0), Vector2())
func _on_door_body_entered(_body):
	if _body.is_in_group("Ally") and $ShapeCast2D.is_colliding():
		interact()
