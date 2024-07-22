extends Node2D

var time = 120
var facing = 1
var id = 0
func _ready():
	$Timer.start(1)
func attack():
	if Operator.conqueror.size() > 0:
		for i in Operator.conqueror:
			if i.id == id:
				$Ani.play("Idle")
				var tween = create_tween()
				tween.tween_property($Sprite, "global_position", Operator.conqueror[Operator.conqueror.find(i)].global_position, 0.1)
				tween.chain().tween_property($Sprite, "modulate", Color(1,1,1,0), 0.1)
				tween.play()
				tween.tween_callback(queue_free)
func _on_timer_timeout():
	queue_free()
