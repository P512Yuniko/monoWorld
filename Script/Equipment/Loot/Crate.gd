extends RigidBody2D

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
	$Sprite2D/Sprite2D2.position.y = 0
	$Area2D/CollisionShape2D.disabled = false
	for i in $Node2D.get_children():
		i.queue_free()
	if random:
		stuff.clear()
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
	$Sprite2D/Sprite2D2.position.y = -61
	for i in stuff:
		var drop_ins = drop.instantiate()
		drop_ins.apply_impulse(Vector2(randf_range(-800,800), randf_range(-800,0)).rotated(global_rotation), Vector2())
		drop_ins.code = i
		$Node2D.add_child(drop_ins)
	stuff.clear()
	open = true
	if contract:
		Contract.progress[Contract.contract.find(2)] -= 1
		Contract.update()
		
	$Area2D/CollisionShape2D.disabled = true
	if restock > 0:
		$Timer.start(restock)

func _on_timer_timeout():
	store()
