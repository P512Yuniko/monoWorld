extends Area2D

var portal = load("res://Screen/Asset/Entity/Bullet/Blade/Portal.tscn")
var deploy = true
var second = false
var deploy_time = 30
var facing = 1
var id = 0
func _ready():
	if Operator.portal_placed:
		second = true
		scale.x = -Operator.portal_facing
		Operator.second_portal = self
		Operator.portal_placed = false
		Operator.emit_signal("portal_connect")
	else:
		Operator.emit_signal("portal_ready")
		Operator.portal_facing = facing
		second = false
		Operator.first_portal = self
		scale.x = facing
		Operator.portal_placed = true
		Operator.first_portal.get_node("Effect1").emitting = false
	$Ani.play("Deploy")
	$Timer.start(10)
	Operator.portal_connect.connect(self.start)
	Operator.portal_ready.connect(self.out)
func _physics_process(_delta):
	if !$Wall.is_colliding() and deploy and deploy_time > 10 and !second:
		position.x += 10 * facing
	if $Wall.is_colliding() and deploy and deploy_time > 0 and !second:
		if $OutWall.is_colliding():
			$OutWall.position.x += 20 * facing * scale.x
		else:
			if deploy:
				var ins = portal.instantiate()
				ins.global_position = $OutWall.global_position
				ins.deploy = false
				get_tree().get_root().add_child(ins)
				deploy = false
	if deploy_time > 0:
		deploy_time -= 1
var effect = load("res://Screen/Asset/Entity/Effect/Teleport.tscn")
func _on_body_entered(_body):
	var current_pos = _body.global_position - global_position
	if Operator.first_portal != null and Operator.second_portal != null and !_body.is_in_group("slash") and !_body.is_in_group("static"):
		var ins = effect.instantiate()
		if second:
			_body.global_position = Operator.first_portal.global_position + Vector2(200 * (current_pos.x)/abs(current_pos.x),current_pos.y)
			ins.global_position = Operator.first_portal.global_position + Vector2(200 * (current_pos.x)/abs(current_pos.x),current_pos.y)
			get_tree().get_root().add_child(ins)
		else:
			_body.global_position = Operator.second_portal.global_position + Vector2(200 * (current_pos.x)/abs(current_pos.x),current_pos.y)
			ins.global_position = Operator.second_portal.global_position + Vector2(200 * (current_pos.x)/abs(current_pos.x),current_pos.y)
			get_tree().get_root().add_child(ins)

func start():
	Operator.first_portal.get_node("Effect1").emitting = true
	Operator.second_portal.get_node("Effect1").emitting = true
func out():
	Operator.portal_placed = false
	queue_free()
