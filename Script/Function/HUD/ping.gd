extends Area2D

var state = 0
var id = 0
func _ready():
	$CollisionShape2D/Sprite2D.frame = state
	scale = Vector2(5,5)
	$Timer.start(10)
	var tween = create_tween()
	tween.tween_property(self, "scale", Operator.crosshair.scale, 0.2)
	tween.play()
func _physics_process(_delta):
	var canvas = get_canvas_transform()
	var top_left = -canvas.origin / canvas.get_scale()
	var size = get_viewport_rect().size / canvas.get_scale()
	set_pos(Rect2(top_left,size))
	scale = Operator.crosshair.scale
	$CollisionShape2D/Sprite2D.global_rotation = 0
	if Operator.conqueror.size() > 0:
		for i in Operator.conqueror:
			if i.id == id:
				$CollisionShape2D/Sprite2D/Label.text = str(int((Operator.conqueror[Operator.conqueror.find(i)].global_transform.origin.distance_to(global_transform.origin))/200),"m")
				$CollisionShape2D/Sprite2D2/Label.text = str(int((Operator.conqueror[Operator.conqueror.find(i)].global_transform.origin.distance_to(global_transform.origin))/200),"m")
	$CollisionShape2D/Sprite2D2.global_rotation = 0
	
	if $OnScreen.is_on_screen():
		$CollisionShape2D/Sprite2D.position.x = lerpf($CollisionShape2D/Sprite2D.position.x,0,0.2)
		rotation = 0
	else:
		$CollisionShape2D/Sprite2D.position.x = lerpf($CollisionShape2D/Sprite2D.position.x,64,0.2)
		if Operator.conqueror.size() > 0:
			for i in Operator.conqueror:
				if i.id == id:
					look_at(Operator.conqueror[Operator.conqueror.find(i)].global_position)

func set_pos(bounds : Rect2):
	$CollisionShape2D.global_position.x = clampf(global_position.x,bounds.position.x,bounds.end.x)
	$CollisionShape2D.global_position.y = clampf(global_position.y,bounds.position.y,bounds.end.y)

func _on_timer_timeout():
	queue_free()
