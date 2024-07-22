extends RigidBody2D

var attacking = false
var id = 493
func _ready():
	Operator.prism += 1
	Operator.break_charge.connect(self.attack)
	$Timer.start(randf_range(4,6))

func _process(delta):
	$Trail.visible = attacking
	if attacking:
		if Operator.conqueror.size() > 0:
			for i in Operator.conqueror:
				if i.id == id:
					global_position.x = lerpf(global_position.x,Operator.conqueror[Operator.conqueror.find(i)].global_position.x,0.2)
					global_position.y = lerpf(global_position.y,Operator.conqueror[Operator.conqueror.find(i)].global_position.y,0.2)
		
func _on_timer_timeout():
	if !attacking:
		Operator.prism -= 1
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.5)
		tween.play()
		tween.tween_callback(queue_free)

func attack():
	if Operator.taken_prism < 20:
		Operator.taken_prism += 1
	attacking = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0,0,0,0), 0.5)
	tween.play()
	tween.tween_callback(queue_free)
