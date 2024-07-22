extends RigidBody2D

var time = 1
var speed = 200
var id = 0
func _ready():
	$Effect.restart()
	await get_tree().create_timer(time).timeout
	$Effect.emitting = false
	await get_tree().create_timer(5).timeout
	queue_free()
func _physics_process(_delta):
	apply_impulse(Vector2(randi_range(-speed,speed),randi_range(-speed,speed)),Vector2())
	if speed > 0:
		speed -= 2
	if $Effect.scale_amount_max > 0:
		$Effect.scale_amount_max -= 0.5
func attack():
	if Operator.conqueror.size() > 0:
		for i in Operator.conqueror:
			if i.id == id:
				var tween = create_tween()
				tween.tween_property(self, "global_position", Operator.conqueror[Operator.conqueror.find(i)].global_position, 0.1)
				tween.chain().tween_property(self, "modulate", Color(1,1,1,0), 0.1)
				tween.play()
				tween.tween_callback(queue_free)
	await get_tree().create_timer(0.5).timeout
	$Effect.emitting = false
	var tween = create_tween()
	tween.tween_property($Trail, "modulate", Color(0,0,0,0), 0.5)
	tween.play()
	tween.tween_callback(queue_free)
	
