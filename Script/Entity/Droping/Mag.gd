extends RigidBody2D

var facing = 1
var time = 10
func _ready():
	$Sprite2D.scale.x = facing
	$CollisionShape2D.scale.x = facing
func _process(_delta):
	await get_tree().create_timer(time).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
	tween.play()
	tween.tween_callback(queue_free)

func _on_body_entered(_body):
	set_collision_mask_value(1,true)
	$AudioStreamPlayer2D.play()
	$AudioStreamPlayer2D.volume_db -= 2
