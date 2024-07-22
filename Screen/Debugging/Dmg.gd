extends RigidBody2D
var dmg = 0
var type = 0
var hp = 1
var hack_level = 3
var dmging = false
var ttk = 0.0
var time = 0.0
func _physics_process(_delta):
	$Label.text = str(dmg)
	$Label3.text = str(ttk)
	if dmging:
		time += 1
	else:
		time = 0
	if dmg > 250:
		Operator.kill(493,1)
		ttk = time/60.0
		dmg = 0
func _on_timer_timeout():
	dmg = 0
	ttk = 0
	dmging = false

func _on_body_entered(body):
	if body.is_in_group("bullet") or body.is_in_group("slash"):
		dmging = true
		Operator.hit(body.id,body.dmg)
		dmg += body.dmg
		$Timer.start(1)
		var tween = create_tween()
		tween.tween_property($Body.material, "shader_parameter/color", Color(1,1,1,1), 0)
		tween.chain().tween_property($Body.material, "shader_parameter/color", Color(0,0,0,1), 0.1)
		tween.play()
	
func _on_area_2d_2_area_entered(area):
	if area.get_parent().is_in_group("fire"):
		dmg += area.get_parent().dmg
		$Timer.start(1)
		Operator.hit(area.get_parent().id,area.get_parent().dmg)

