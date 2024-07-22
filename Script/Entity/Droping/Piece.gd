extends RigidBody2D
func _ready():
	$Sprite2D.frame = randi_range(0,3)
	$Sprite2D.scale.x = randf_range(0.1,1)
	$Sprite2D.scale.y = randf_range(0.1,1)
	$Sprite2D.skew = randf_range(-2,2)
	
func _process(_delta):
	$CollisionShape2D.scale = $Sprite2D.scale
	$CollisionShape2D.skew = $Sprite2D.skew
	await get_tree().create_timer(0.05).timeout
	if !$On_screen.is_on_screen():
		queue_free()
	else:
		await get_tree().create_timer(randf_range(2,5)).timeout
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
		tween.play()
		tween.tween_callback(queue_free)

