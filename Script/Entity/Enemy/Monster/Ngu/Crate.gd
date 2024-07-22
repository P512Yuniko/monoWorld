extends RigidBody2D

var motion = Vector2()
@onready var piece = preload("res://Screen/Asset/Entity/Object/Piece/Square_piece.tscn")
var state = 1
var hp = 1
var killed = false
var killer = 0
var trigger = false
func _physics_process(_delta):
	if trigger and !open and hp > 0:
		active()
	else:
		$Timer.stop
		$Anim.play("Idle")
	if hp <= 0:
		if !killed:
			Operator.kill(killer,0)
			open = true
			interact()
			killed = true
		$Anim.play("Idle")
		await get_tree().create_timer(1).timeout
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
		tween.play()
		tween.tween_callback(queue_free)
func active():
	move_and_collide(motion)
	if !$Timer.time_left > 0:
		$Timer.start(randi_range(1,2))
		state = randi_range(1,2)
	if state == 1:
		motion.x = 50
		$Anim.play("Move")
		$Body.scale.x = 1
	elif state == 2:
		motion.x = -50
		$Anim.play("Move")
		$Body.scale.x = -1
	else:
		motion.x = 0
		$Anim.play("Idle")
	motion.y = move_toward(motion.y,0,1)
	if !$RightEdge.is_colliding() and !$LeftEdge.is_colliding() or $RightWall.is_colliding() and $LeftWall.is_colliding():
		state = 0
	else:
		if $RightWall.is_colliding() or !$RightEdge.is_colliding():
			if state == 1:
				state = 2
		elif $LeftWall.is_colliding() or !$LeftEdge.is_colliding():
			if state == 2:
				state = 1

func _on_area_body_entered(body):
	if body.is_in_group("bullet") or body.is_in_group("slash"):
		if hp > 0:
			Operator.dmg_dealt += body.dmg
			hp -= body.dmg
			if body.is_in_group("slash"):
				Operator.slash(body.id,body.dmg)
				killer = body.id
				if !$RightEdge.is_colliding() and !$LeftEdge.is_colliding():
					apply_impulse(Vector2(0,-1000), Vector2())
			else:
				Operator.hit(body.id,body.dmg)
				killer = body.id
		for i in range(randi_range(1,4)):
			var ins = piece.instantiate()
			ins.global_position = global_position
			ins.angular_velocity = randf_range(-20,20)
			ins.apply_impulse(Vector2(randf_range(body.linear_velocity.x - 400,body.linear_velocity.x + 400),randf_range(body.linear_velocity.y - 400,body.linear_velocity.y + 400)).rotated(0), Vector2())
			get_tree().get_root().call_deferred("add_child",ins)
			i += 1
		var tween = create_tween()
		tween.tween_property($Body.material, "shader_parameter/color", Color(1,1,1,1), 0)
		tween.chain().tween_property($Body.material, "shader_parameter/color", Color(0,0,0,1), 0.1)
		tween.play()
		if hp > 0:
			$Body.modulate = Color(1,1,1)
		else:
			$Body.modulate = Color(0.3,0.3,0.3)
func _on_area_area_entered(area):
	if area.get_parent().is_in_group("fire"):
		$Body.modulate = Color(0.3,0.3,0.3)
		hp -= int(area.get_parent().dmg)
		Operator.dmg_dealt += int(area.get_parent().dmg)
		var tween = create_tween()
		tween.tween_property($Body.material, "shader_parameter/color", Color(1,1,1,1), 0)
		tween.chain().tween_property($Body.material, "shader_parameter/color", Color(0,0,0,1), 0.1)
		tween.play()
		if hp > 0:
			$Body.modulate = Color(1,1,1)
			Operator.hit(area.id,area.get_parent().dmg)
			killer = area.id
		else:
			$Body.modulate = Color(0.3,0.3,0.3)

@export var stuff = []

@export var random = false
@export var rarity = 0
@export var restock = 0
var contract = false
var drop = load("res://Screen/Asset/Entity/Stuff/Drop.tscn")
var open = false
var gun = 0
var gun_type = 0
var gun_class = 0
var gun_ammo = 0
var scope = 0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var nade = 0
func _ready():
	store()
func store():
	randomize()
	$Body/Sprite2D2.position.y = 0
	$Area2D/CollisionShape2D.disabled = false
	for i in $Node2D.get_children():
		i.queue_free()
	stuff.clear()
	if random:
		match rarity:
			1: 
				gun_class = [0,1].pick_random()
				match gun_class:
					0: gun_type = [4,5,0].pick_random()
					1: gun_type = [0,1].pick_random()
				foregrip = randi_range(0,2)
				muzzle = randi_range(0,3)
				nade = [0,1,4,5].pick_random()
			2: 
				gun_class = [0,1].pick_random()
				match gun_class:
					0: gun_type = [4,5,0,1,2].pick_random()
					1: gun_type = [0,1,2].pick_random()
				scope = randi_range(0,1)
				foregrip = randi_range(0,2)
				muzzle = randi_range(1,3)
				laser = randi_range(0,1)
				nade = [0,1,3,4,5,7].pick_random()
			3: 
				gun_class = [0,1,2].pick_random()
				match gun_class:
					0: gun_type = [4,5,0,1,2,3].pick_random()
					1: gun_type = [0,1,2,3].pick_random()
					2: gun_type = [2,0].pick_random()
				scope = randi_range(0,2)
				foregrip = randi_range(1,2)
				muzzle = randi_range(1,3)
				magazine = randi_range(0,1) 
				laser = randi_range(0,1)
				nade = [0,1,2,3,4,5,6,7].pick_random()
			4: 
				gun_class = [0,1,2,3].pick_random()
				match gun_class:
					0: gun_type = [4,5,0,1,2,3,6].pick_random()
					1: gun_type = [0,1,2,3,4].pick_random()
					2: gun_type = [2,0,1].pick_random()
					3: gun_type = [0].pick_random()
				scope = randi_range(1,3)
				foregrip = randi_range(1,2)
				muzzle = randi_range(1,3)
				magazine = randi_range(0,3) 
				laser = 1
				stock = randi_range(0,1)
				nade = [0,1,2,3,4,5,6,7].pick_random()
			5: 
				gun_class = [0,1,2,3,4].pick_random()
				match gun_class:
					0: gun_type = [4,5,0,1,2,3,6].pick_random()
					1: gun_type = [0,1,2,3,4].pick_random()
					2: gun_type = [2,0,1].pick_random()
					3: gun_type = [0,1].pick_random()
					4: gun_type = 0
				scope = randi_range(1,3)
				foregrip = randi_range(1,3)
				muzzle = randi_range(1,2)
				magazine = randi_range(1,5) 
				laser = 1
				stock = randi_range(0,1)
				nade = [0,1,2,3,4,5,6,7].pick_random()
		match gun_class:
			0: match gun_type:
				0:
					gun_ammo = str(0) + str(1) + str(2)
					scope = 0
					foregrip = 0
					magazine = 0
					stock = 0
				1:
					gun_ammo = str(0) + str(0) + str(7)
					foregrip = 0
					magazine = 0
					stock = 0
				2:
					gun_ammo = str(0) + str(1) + str(5)
					scope = 0
					foregrip = 0
					magazine = 0
					stock = 0
				3: 
					gun_ammo = str(0) + str(1) + str(8)
					scope = 0
					foregrip = 0
					magazine = 0
					stock = 0
				4: 
					gun_ammo = str(0) + str(3) + str(0)
					if scope > 2:
						scope = 2
				5: 
					gun_ammo = str(0) + str(4) + str(0)
					if scope > 2:
						scope = 2
				6: 
					gun_ammo = str(0) + str(5) + str(0)
					if scope > 2:
						scope = 2
					stock = 0
			1: match gun_type:
				2:
					gun_ammo = str(0) + str(3) + str(0)
					magazine = 0
				3: 
					gun_ammo = str(0) + str(1) + str(5)
					magazine = 0
				4: 
					gun_ammo = str(1) + str(0) + str(0)
					magazine = 0
				_: 
					gun_ammo = str(0) + str(3) + str(0)
			2: match gun_type:
				0: 
					gun_ammo = str(0) + str(0) + str(7)
					scope = 0
					foregrip = 0
					magazine = 0
					laser = 0
				1: 
					gun_ammo = str(0) + str(0) + str(8)
					if scope > 2:
						scope = 2
				2: 
					gun_ammo = str(0) + str(0) + str(2)
					scope = 0
					foregrip = 0
					magazine = 0
					stock = 0
			3: match gun_type:
				0: 
					gun_ammo = str(0) + str(0) + str(5)
					scope = 0
					foregrip = 0
					magazine = 0
					stock = 0
				1: 
					gun_ammo = str(0) + str(1) + str(0)
					muzzle = 0
					stock = 0
			4: match gun_type:
				0: 
					gun_ammo = str(0) + str(0) + str(1)
					scope = 0
					foregrip = 0
					muzzle = 0
					magazine = 0
					laser = 0
					stock = 0
		gun = str(1) + str(gun_class) + str(gun_type) + gun_ammo + str(scope) + str(foregrip) + str(muzzle) + str(magazine) + str(laser) + str(stock)
		stuff.append(int(gun))
		for i in 3:
			stuff.append(int(str(2) + str(gun_class) + gun_ammo))
		stuff.append(int(str(27) + str(nade)))
	
func interact():
	trigger = true
	if open:
		$Body/Sprite2D2.position.y = -61
		for i in stuff:
			var drop_ins = drop.instantiate()
			drop_ins.apply_impulse(Vector2(randf_range(-800,800), randf_range(-800,0)).rotated(global_rotation), Vector2())
			drop_ins.code = i
			drop_ins.position = global_position
			get_tree().get_root().add_child(drop_ins)
		stuff.clear()
		if contract:
			Contract.progress[Contract.contract.find(2)] -= 1
			Contract.update()
	$Area2D/CollisionShape2D.disabled = true

func _on_bullet_body_entered(_body):
	if ($RightEdge.is_colliding() or $LeftEdge.is_colliding()) and _body.is_in_group("bullet"):
		motion.y = -50
		$Anim.play("Idle")

func _on_bullet_area_entered(_area):
	if ($RightEdge.is_colliding() or $LeftEdge.is_colliding()) and _area.is_in_group("bullet"):
		motion.y = -50
		$Anim.play("Idle")
