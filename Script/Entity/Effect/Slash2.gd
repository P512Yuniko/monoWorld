extends Node2D

func _ready():
	$Timer.start(0.5)
	$Ani.play("Process")
func _on_timer_timeout():
	queue_free()
