extends Node2D

var current_recoil = 0
var facing_right = true
var facing = 1
var facing_up = true
var aim = false
var dmg = 10
var ammo = Inventory.ammo
signal cancel
signal picked
signal select
signal pressed
var id = 0
func _ready():
	id = get_parent().id
	TranslationServer.set_locale("en")
	Operator.crosshair = $CrossHair
	$CrossHair/Cam.world_2d = get_world_2d()
	$Map/SubViewport.world_2d = get_world_2d()
	get_tree().get_root().get_viewport().canvas_cull_mask = get_tree().get_root().get_viewport().canvas_cull_mask - 2
	get_parent().get_node("UI/CrossHair").position = Vector2(get_viewport_rect().size.x/2,get_viewport_rect().size.y/2)
	Operator.shake.connect(self.shaked)
	Inventory.perk.clear()
	Inventory.perk.append_array(Inventory.perk_mod_1)
	Inventory.perk.append_array(Inventory.perk_mod_2)
	Inventory.perk.append_array(Inventory.perk_mod_3)
	Inventory.perk.append_array(Inventory.perk_mod_4)
	for i in 2 - Inventory.weapon.size():
		Inventory.weapon.append(0)
	for i in Inventory.perk:
		if i == 1:
			Inventory.loadout += 1
	match Inventory.current_perk:
		1: Inventory.perk_key = Inventory.perk_mod_1
		2: Inventory.perk_key = Inventory.perk_mod_2
		3: Inventory.perk_key = Inventory.perk_mod_3
		4: Inventory.perk_key = Inventory.perk_mod_4
	perk_load(Inventory.perk_key)
	Inventory.used_slot = 0
	if Inventory.weapon[0] == 0 and Inventory.weapon[1] > 0:
		Inventory.weapon[0] = Inventory.weapon[1]
		Inventory.weapon[1] = 0
	for i in Inventory.backpack:
		if i > 1000:
			if Inventory.weapon[0] == 0:
				Inventory.weapon[0] = i
				i = 0
			elif Inventory.weapon[1] == 0:
				Inventory.weapon[1] = i
				i = 0
			else:
				var ins = reverse_gun.instantiate()
				ins.code = i
				$Inventory/Loadout.add_child(ins)
				if int((i % 100000000000)/1000000000) > 3:
					Inventory.used_slot += 2
				else:
					Inventory.used_slot += 1
		else:
			match int(i/100):
				2:
					var ins = item.instantiate()
					ins.code = i % 10
					$Inventory/Loadout.add_child(ins)
					Inventory.used_slot += 1
				7:
					var ins = Nade.instantiate()
					match int(i/10)%10:
						0: ins.count = 1
						_: ins.count = 2
					ins.code = i % 10
					$Inventory/Loadout.add_child(ins)
					Inventory.used_slot += 1
		Inventory.backpack.erase(0)
	for i in $Inventory/Loadout.get_children():
		i.pressed.connect(HUDSound.pressed)
		i.mouse_entered.connect(HUDSound.select)
	self.cancel.connect(HUDSound.cancel)
	self.picked.connect(HUDSound.picked)
	self.select.connect(HUDSound.select)
	self.pressed.connect(HUDSound.pressed)
	$Inventory/Weapon/Weapon1.mouse_entered.connect(HUDSound.select)
	$Inventory/Weapon/Weapon2.mouse_entered.connect(HUDSound.select)
	$Inventory/Equipment/Kit/Armor.pressed.connect(HUDSound.pressed)
	$Inventory/Equipment/Kit/Armor.mouse_entered.connect(HUDSound.select)
	$Inventory/Equipment/Kit/Aid.pressed.connect(HUDSound.pressed)
	$Inventory/Equipment/Kit/Aid.mouse_entered.connect(HUDSound.select)
	$Inventory/Equipment/Nade.mouse_entered.connect(HUDSound.select)
	$Inventory/Equipment/Nade2.mouse_entered.connect(HUDSound.select)
	for i in $Buy/Gear.get_children():
		i.mouse_entered.connect(HUDSound.select)
		i.pressed.connect(HUDSound.pressed)
	for i in $Buy/Weapon.get_children():
		i.mouse_entered.connect(HUDSound.select)
		i.pressed.connect(HUDSound.pressed)
var right_aim = true
var tolerance_rotate = 0
var shake = 0
var unstable = 0
func active():
	switch()
	pick()
	stow()
	throw()
	buy()
	hack()
	shoot = Key.fire
	shooting = Key.firing
	pack_opening = (Key.pack and !stow_hold > 0)
	if stuff != null and stuff.is_in_group("stuff") and (stuff.key[0] == 1 or stuff.key[0] == 6 or stuff.key[0] == 2) and !$Switch.time_left > 0 and !pack_opening and !buying:
		$Pick.visible = $PickRange.is_colliding()
	else:
		$Pick.hide()
		$Pick.position.x = 128
		$Pick.position.y = 64
func _physics_process(_delta):
	camera()
	crosshair()
	killstreak()
	quickpack()
	if get_child(0).get_class() == "Node2D":
		weapon()
		bare = false
	else:
		bare = true
	if coiling:
		if get_parent().crouching:
			current_recoil += recoil * 0.75 * Setting.inverse
			spread = randf_range(-max_spread,max_spread) * 0.75
		else:
			current_recoil += recoil * Setting.inverse
			spread = randf_range(-max_spread,max_spread)
	else:
		current_recoil = lerpf(current_recoil,0,(0.2 + aim_speed) * Setting.inverse)
		spread = lerpf(spread,0,(0.2 + aim_speed) * Setting.inverse)
	if Key.righting and !Key.lefting and !aim and !get_parent().get_node("BlockR").is_colliding():
		facing_right = true
	elif Key.lefting and !Key.righting and !aim and !get_parent().get_node("BlockL").is_colliding():
		facing_right = false
	if facing_right and get_parent().get_node("BlockR").is_colliding() and !get_parent().get_node("BlockL").is_colliding() and !aim and !melee and get_parent().get_node("Grounded").is_colliding() or facing_right and get_parent().target_dash < 0 and get_parent().slash and get_parent().slash_count > 3 and !Key.righting:
		if get_parent().velocity.x > 800 and !get_parent().slash:
			$Camera2D.shake(abs(get_parent().velocity.x)/100,5)
		facing_right = false
	if !facing_right and get_parent().get_node("BlockL").is_colliding() and !get_parent().get_node("BlockR").is_colliding() and !aim and !melee and get_parent().get_node("Grounded").is_colliding() or !facing_right and get_parent().target_dash > 0 and get_parent().slash and get_parent().slash_count > 3 and !Key.lefting:
		if get_parent().velocity.x < -800 and !get_parent().slash:
			$Camera2D.shake(abs(get_parent().velocity.x)/100,5)
		facing_right = true
	if !aim or block and facing_right and right_aim or block and !facing_right and !right_aim or block and get_parent().crouching or (abs($CrossHair.position.x) + abs($CrossHair.position.y) < 200 and !(Key.aim and Setting.stick_aim)):
		if Key.up and !reloading and !melee and !switching and !mode_changing and !pack_opening and !buying:
			$Rotation.global_rotation = lerp_angle($Rotation.global_rotation,deg_to_rad(-90),(0.2 + aim_speed) * Setting.inverse)
		elif Key.down and !reloading and !melee and !switching and !mode_changing and !pack_opening and !buying and !get_parent().crouching:
			$Rotation.global_rotation = lerp_angle($Rotation.global_rotation,deg_to_rad(90),(0.2 + aim_speed) * Setting.inverse)
		else:
			if facing_right:
				$Rotation.rotation = lerp_angle($Rotation.rotation,deg_to_rad(0.001),(0.2 + aim_speed) * Setting.inverse)
			else:
				$Rotation.rotation = lerp_angle($Rotation.rotation,deg_to_rad(179.999),(0.2 + aim_speed) * Setting.inverse)
	else:
		$Rotation.global_rotation = lerp_angle($Rotation.global_rotation,$Idle/Aim.global_rotation,(0.5 + aim_speed) * Setting.inverse)
	if (Key.alt or Key.aim and Setting.stick_aim) and !melee and !reloading and !switching and !mode_changing and !pack_opening and !buying and !Key.map and !(get_parent().get_node("BlockR").is_colliding() and right_aim or get_parent().get_node("BlockL").is_colliding() and !right_aim):
		aim = true
		unstable = 0
		get_parent().get_node("Block").rotation = $Idle/Aim.rotation
	else:
		aim = false
		unstable = 1
		get_parent().get_node("Block").rotation = $Rotation.rotation
	right_aim = $CrossHair.position.x > 0
	shake = move_toward(shake,randf_range(-2,2),0.05)
	if facing_right:
		facing = 1
	else:
		facing = -1
	if slide or reloading or fire_delay:
		walk = false
	$Head/Rotate.position.x = $Recoil.position.x/2 * -facing
	$Head.rotation = $Rotation.rotation
	$Rotation/Recoil/Body.position.x = $Recoil.position.x/2
	$Rotation/Recoil.rotation_degrees = (current_recoil + spread) * -facing
	$Idle.position.x = ($Rotation/Recoil/Body.global_position.x - global_position.x) * facing
	if !bare and int(current_gun/10) == 0:
		$Idle/Aim.position.x = 0
	else:
		$Idle/Aim.position.x = -10 * facing
	if ($Rotation/Recoil/Position.global_position.y - global_position.y) < 20:
		facing_up = true
	elif ($Rotation/Recoil/Position.global_position.y - global_position.y) > 20:
		facing_up = false
	if !bare and gun != null:
		if aim:
			gun.global_position.x = $Idle/Aim.global_position.x
		else:
			gun.position.x = lerpf(gun.position.x,$Idle.position.x,0.2 * Setting.inverse)
	gun.position.y = shake
	block = get_parent().get_node("Block").is_colliding()
	action = melee or throwing or hacking or hack_hold > 0 or get_parent().climb
	if current_gun == 40:
		$Idle/Aim.position.y = -28
	elif current_gun == 15:
		$Idle/Aim.position.y = 100
	else:
		$Idle/Aim.position.y = 0
	slow = lerpf(slow,1,0.25 * Setting.inverse)
	for i in Contract.time:
		if i != -1:
			if i > 0:
				i -= 1
			else:
				Contract.fail.append(i)

var offset = 0
var current_zoom = 1.0
var estimate_zoom = 1.0
var to_cross = 0.0
@export var zoom = 0.75

func camera():
	$Camera2D.zoom = Vector2(current_zoom,current_zoom)
	$CrossHair/Cam/Camera.position = $CrossHair.global_position
	$Map/SubViewport/Camera.global_position = global_position
	$Camera2D.offset = (-$Recoil.position + $Camera2D.shake_offset) * (1/(current_zoom))
	$Map.global_position.x = lerpf($Map.global_position.x,$Rotation/Recoil/Body/ArmL.global_position.x + $Joint/RigidBody2D.position.x/20 + 128 * facing,0.2 * Setting.inverse)
	$Map.global_position.y = $Rotation/Recoil/Body/ArmL.global_position.y + $Joint/RigidBody2D.position.y/20
	$Map/Sprite2D2.rotation_degrees += 2 * Setting.inverse
	$Map/Sprite2D4.rotation_degrees -= 8 * Setting.inverse
	$Map/Sprite2D5.rotation_degrees -= 0.5 * Setting.inverse
	$Map/Sprite2D2.position.x = lerpf($Map/Sprite2D2.position.x,-32 * facing,0.05 * Setting.inverse)
	$Map/Sprite2D3.rotation = lerp_angle($Map/Sprite2D3.rotation,deg_to_rad(90 - 90 * facing),0.1 * Setting.inverse)
	$Map/Sprite2D3.position.x = lerpf($Map/Sprite2D3.position.x,16 * facing,0.1 * Setting.inverse)
	$Map/Sprite2D4.position.x = lerpf($Map/Sprite2D4.position.x,-40 * facing,0.2 * Setting.inverse)
	$Map/Sprite2D5.position.x = lerpf($Map/Sprite2D5.position.x,-64 * facing,0.2 * Setting.inverse)
	$Map/Sprite2D6.position.x = lerpf($Map/Sprite2D6.position.x,-72 * facing,0.2 * Setting.inverse)
	$Map.skew = lerpf($Map.skew,deg_to_rad(-20 * facing),0.2 * Setting.inverse)
	$Map/TV/Map.skew = - $Map.skew
	$Map/Sprite2D/Class.skew = - $Map.skew
	$Map/Sprite2D2.position.y = -160 + $Joint/RigidBody2D.position.y/20
	$Map/Sprite2D3.position.y = -208 + $Joint/RigidBody2D.position.y/10
	$Map/Sprite2D4.position.y = -152 + $Joint/RigidBody2D.position.y/20
	$Map/Sprite2D5.position.y = -128 + $Joint/RigidBody2D.position.y/10
	$Map/Sprite2D6.position.y = -104 + $Joint/RigidBody2D.position.y/20
	$Map/Sprite2D3.z_index = -1 + facing
	$Map/Sprite2D4.modulate.a = 0.7 - 0.2 * facing
	$Map/Sprite2D5.modulate.a = 0.4 - 0.2 * facing
	$Map/Sprite2D7.modulate.a = 0.8 - 0.2 * facing
	$Map/Sprite2D8.modulate.a = 0.8 - 0.2 * facing
	$Map/Sprite2D7.look_at($Rotation/Recoil/Body/ArmL.global_position)
	$Map/Sprite2D7.scale.x = ($Map/Sprite2D7.global_transform.origin.distance_to($Rotation/Recoil/Body/ArmL.global_transform.origin) + 16)/512
	$Map/Sprite2D8.look_at($Rotation/Recoil/Body/ArmL.global_position)
	$Map/Sprite2D8.scale.x = ($Map/Sprite2D8.global_transform.origin.distance_to($Rotation/Recoil/Body/ArmL.global_transform.origin) + 16)/512
	if Key.aim and Setting.stick_aim:
		$Idle/Aim.look_at($Idle/Aim/Joystick.global_position)
		$Rotation/Recoil/Joy.modulate.a = lerpf($Rotation/Recoil/Joy.modulate.a,1,0.2 * Setting.inverse)
	else:
		$Idle/Aim.look_at($CrossHair.global_position)
		$Rotation/Recoil/Joy.modulate.a = lerpf($Rotation/Recoil/Joy.modulate.a,0,0.2 * Setting.inverse)
	current_zoom = lerpf(current_zoom,(zoom - (zoom - estimate_zoom) * to_cross),(0.1 + aim_speed) * Setting.inverse)
	if aim:
		estimate_zoom = zoom/(scope/2+1)
		if Setting.to_mouse_zoom:
			to_cross = clampf(global_transform.origin.distance_to($CrossHair.global_transform.origin)/(get_viewport_rect().size.x/2 * 1/estimate_zoom),0,1)
		else:
			to_cross = 1
		$Camera2D.position.x = clampf($CrossHair.position.x/4,-512,512)
		$Camera2D.position.y = clampf($CrossHair.position.y/(4 * get_viewport_rect().size.x/get_viewport_rect().size.y),-512,512)
		if current_recoil < recoil * (recoil * 25):
			$Rotation/Recoil.global_rotation_degrees = $Rotation.global_rotation_degrees + current_recoil * -facing
		else:
			$Rotation/Recoil.global_rotation_degrees = $Rotation.global_rotation_degrees + (current_recoil + spread) * -facing
		if get_parent().crouching:
			if ($Rotation/Recoil/Position.global_position.x - global_position.x) > 100:
				facing_right = true
			elif ($Rotation/Recoil/Position.global_position.x - global_position.x) < -100:
				facing_right = false
		else:
			if ($Rotation/Recoil/Position.global_position.x - global_position.x) > 25:
				facing_right = true
			elif ($Rotation/Recoil/Position.global_position.x - global_position.x) < -25:
				facing_right = false
	else:
		to_cross = 1
		if pack_opening or hacking or buying:
			estimate_zoom = 1
			$Camera2D.position_smoothing_speed = 10
		elif Key.map:
			estimate_zoom = 0.75
			$Camera2D.position_smoothing_speed = 5
		else:
			estimate_zoom = zoom
			$Camera2D.position_smoothing_speed = 5
		$Camera2D.position = Vector2(0,0)
	if abs($Recoil.position.x) + abs($Recoil.position.y) != 0:
		$Camera2D.shake(abs($Recoil.position.x) + abs($Recoil.position.y) + current_recoil/10,10)
		Input.start_joy_vibration(0,clampf(abs($Recoil.position.x) + abs($Recoil.position.y),0,1)/10,clampf(current_recoil,0,1),0.01)
	if !(fire_delay or reloading or switching or melee):
		$Recoil.position.x = lerpf($Recoil.position.x,0,0.2 * Setting.inverse)
		$Recoil.position.y = lerpf($Recoil.position.y,0,0.2 * Setting.inverse)
	if Key.map:
		$Map.modulate.a = lerpf($Map.modulate.a,1,0.5 * Setting.inverse)
		$Map/TV.scale.x = lerpf($Map/TV.scale.x,1,0.5 * Setting.inverse)
		$Map/TV.scale.y = lerpf($Map/TV.scale.y,1,0.5 * Setting.inverse)
	else:
		$Map.modulate.a = lerpf($Map.modulate.a,0,0.5 * Setting.inverse)
		$Map/TV.scale.x = lerpf($Map/TV.scale.x,0,0.5 * Setting.inverse)
		$Map/TV.scale.y = lerpf($Map/TV.scale.y,0,0.5 * Setting.inverse)
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		match Setting.mouse_pos:
			1:
				$CrossHair.move_local_x(event.relative.x * 1/current_zoom * Setting.mouse_sens)
				$CrossHair.move_local_y(event.relative.y * 1/current_zoom * Setting.mouse_sens)
			_:
				get_parent().get_node("UI/CrossHair").move_local_x(event.relative.x * Setting.mouse_sens)
				get_parent().get_node("UI/CrossHair").move_local_y(event.relative.y * Setting.mouse_sens)
var mark = load("res://Screen/Asset/Function/HUD/ping.tscn")
func crosshair():
	if !(Key.aim and Setting.stick_aim):
		get_parent().get_node("UI/CrossHair").move_local_x(Input.get_axis("ui_left","ui_right") * 10 * Setting.stick_x)
		get_parent().get_node("UI/CrossHair").move_local_y(Input.get_axis("ui_up","ui_down") * 10 * Setting.stick_y)
	$Ping.target_position = $CrossHair.position
	$Idle/Aim/Joystick.global_position.x = $Idle/Aim.global_position.x + Input.get_joy_axis(0,JOY_AXIS_RIGHT_X)
	$Idle/Aim/Joystick.global_position.y = $Idle/Aim.global_position.y + Input.get_joy_axis(0,JOY_AXIS_RIGHT_Y)
	if pack_opening or buying or get_parent().get_node("UI").opening_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$CrossHair.position = Vector2(0,0)
	elif Setting.controller:
		if Setting.stick_aim:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			$CrossHair.position = Vector2(0,0)
		else:
			$CrossHair.move_local_x(Input.get_axis("ui_left","ui_right") * 10 * Setting.stick_x)
			$CrossHair.move_local_y(Input.get_axis("ui_up","ui_down") * 10 * Setting.stick_y)
	else:
		match Setting.mouse_pos:
			0:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_parent().get_node("UI/CrossHair").position.x = clampf(get_parent().get_node("UI/CrossHair").position.x,0,get_viewport_rect().size.x)
				get_parent().get_node("UI/CrossHair").position.y = clampf(get_parent().get_node("UI/CrossHair").position.y,0,get_viewport_rect().size.y)
				$CrossHair.global_position = get_parent().get_node("UI/CrossHair").position * 1.0/current_zoom + get_parent().get_node("UI/CrossHair").get_viewport().get_canvas_transform().affine_inverse().origin
			1:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				$CrossHair.global_position.x = clampf($CrossHair.global_position.x,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.x,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.x + get_viewport_rect().size.x * 1.0/current_zoom)
				$CrossHair.global_position.y = clampf($CrossHair.global_position.y,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.y,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.y + get_viewport_rect().size.y * 1.0/current_zoom)
			2:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				$CrossHair.global_position.x = clampf(get_parent().get_node("UI/CrossHair").position.x * 1.0/current_zoom + get_parent().get_node("UI/CrossHair").get_viewport().global_canvas_transform.origin.x,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.x,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.x + get_viewport_rect().size.x * 1.0/current_zoom)
				$CrossHair.global_position.y = clampf(get_parent().get_node("UI/CrossHair").position.y * 1.0/current_zoom + get_parent().get_node("UI/CrossHair").get_viewport().global_canvas_transform.origin.y,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.y,$CrossHair.get_viewport().get_canvas_transform().affine_inverse().origin.y + get_viewport_rect().size.y * 1.0/current_zoom)
			3:
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
				$CrossHair.global_position = get_global_mouse_position()
	if aim and !bare and int(current_gun/10) != 2 and int(current_gun/10) != 4 and abs($CrossHair.position.x) + abs($CrossHair.position.y) > 200:
		if scope > 2:
			$CrossHair/Scope/SniperX.scale.y = lerpf($CrossHair/Scope/SniperX.scale.y,1,(0.2 + aim_speed) * Setting.inverse)
			$CrossHair/Scope/SniperY.scale.y = lerpf($CrossHair/Scope/SniperY.scale.y,1,(0.2 + aim_speed) * Setting.inverse)
			$CrossHair/Inner/CrossUp.scale.y = lerpf($CrossHair/Inner/CrossUp.scale.y,0,0.2 * Setting.inverse)
			$CrossHair/Inner.modulate.a = lerpf($CrossHair/Inner.modulate.a,0,0.2 * Setting.inverse)
			$CrossHair/Static.modulate.a = lerpf($CrossHair/Static.modulate.a,0,0.2 * Setting.inverse)
			$CrossHair/Scope.modulate.a = lerpf($CrossHair/Scope.modulate.a,1,0.5 * Setting.inverse)
			match scope:
				3: $CrossHair/TV.frame = 1
				4: $CrossHair/TV.frame = 0
		else:
			$CrossHair/Scope/SniperX.scale.y = lerpf($CrossHair/Scope/SniperX.scale.y,0,0.2 * Setting.inverse)
			$CrossHair/Scope/SniperY.scale.y = lerpf($CrossHair/Scope/SniperY.scale.y,0,0.2 * Setting.inverse)
			$CrossHair/Inner/CrossUp.scale.y = lerpf($CrossHair/Inner/CrossUp.scale.y,1,0.2 * Setting.inverse)
			$CrossHair/Inner.modulate.a = lerpf($CrossHair/Inner.modulate.a,1,0.2 * Setting.inverse)
			$CrossHair/Static.modulate.a = lerpf($CrossHair/Static.modulate.a,1,0.2 * Setting.inverse)
			$CrossHair/Scope.modulate.a = lerpf($CrossHair/Scope.modulate.a,0,0.5 * Setting.inverse)
		$CrossHair/Outer.modulate.a = lerpf($CrossHair/Outer.modulate.a,0,0.2 * Setting.inverse)
		$CrossHair/Outer.scale.x = lerpf($CrossHair/Outer.scale.x,2,0.05 * Setting.inverse)
	else:
		$CrossHair/Scope/SniperX.scale.y = lerpf($CrossHair/Scope/SniperX.scale.y,0,0.2 * Setting.inverse)
		$CrossHair/Scope/SniperY.scale.y = lerpf($CrossHair/Scope/SniperY.scale.y,0,0.2 * Setting.inverse)
		$CrossHair/Inner/CrossUp.scale.y = lerpf($CrossHair/Inner/CrossUp.scale.y,0,0.2 * Setting.inverse)
		$CrossHair/Inner.modulate.a = lerpf($CrossHair/Inner.modulate.a,0,0.2 * Setting.inverse)
		$CrossHair/Outer.modulate.a = lerpf($CrossHair/Outer.modulate.a,1,0.2 * Setting.inverse)
		$CrossHair/Outer.scale.x = lerpf($CrossHair/Outer.scale.x,1,0.2 * Setting.inverse)
		$CrossHair/Static.modulate.a = lerpf($CrossHair/Static.modulate.a,1,0.2 * Setting.inverse)
		$CrossHair/Scope.modulate.a = lerpf($CrossHair/Scope.modulate.a,0,0.5 * Setting.inverse)
	$Idle/Aim/Aim/AimX.global_position.x = lerpf($Idle/Aim/Aim/AimX.global_position.x,$CrossHair.global_position.x,0.05 * Setting.inverse)
	$Idle/Aim/Aim/AimX.global_position.y = $CrossHair.global_position.y
	$Idle/Aim/Aim/AimX.position.y = 0
	$Idle/Aim/Aim/AimY.global_position.x = $CrossHair.global_position.x
	$Idle/Aim/Aim/AimY.global_position.y = lerpf($Idle/Aim/Aim/AimY.global_position.y,$CrossHair.global_position.y,0.05 * Setting.inverse)
	$Idle/Aim/Aim/AimY.position.y = 0
	$Idle/Aim/Aim.global_rotation = $Rotation/Recoil.global_rotation
	$CrossHair/Scope.frame = $CrossHair/TV.frame
	$CrossHair/TV.modulate = $CrossHair/Scope.modulate
	$CrossHair/Scope.scale.x = 1 + ((abs($Recoil.position.x) + abs($Recoil.position.y)) + (current_recoil + abs(spread)))/128
	$CrossHair/Scope.scale.y = 1 + ((abs($Recoil.position.x) + abs($Recoil.position.y)) + (current_recoil + abs(spread)))/128
	$CrossHair/Scope/SniperX.position.x = clampf($CrossHair/Dynamic.position.x/2,-80,80)
	$CrossHair/Scope/SniperY.position.y = clampf($CrossHair/Dynamic.position.y/2,-80,80)
	$CrossHair/Dynamic.global_position.x = $Idle/Aim/Aim/AimX.global_position.x
	$CrossHair/Dynamic.global_position.y = $Idle/Aim/Aim/AimY.global_position.y
	$CrossHair.rotation_degrees = clampf(spread * current_recoil,-4,4)
	$CrossHair.scale = Vector2(1,1)/Vector2(current_zoom,current_zoom)
	$CrossHair/Outer.scale.y = $CrossHair/Outer.scale.x
	$CrossHair/Inner/CrossDown.scale.y = $CrossHair/Inner/CrossUp.scale.y
	$CrossHair/Inner/CrossRight.scale.y = $CrossHair/Inner/CrossUp.scale.y
	$CrossHair/Inner/CrossLeft.scale.y = $CrossHair/Inner/CrossUp.scale.y
	$CrossHair/Outer/CrossR.position.x = (abs($Recoil.position.x) + abs($Recoil.position.y)) + (current_recoil + abs(spread))
	$CrossHair/Outer/CrossL.position.x = -(abs($Recoil.position.x) + abs($Recoil.position.y)) - (current_recoil + abs(spread))
	$Rotation/Recoil/Joy/Aim2.position.y = (abs($Recoil.position.x) + abs($Recoil.position.y))
	$Rotation/Recoil/Joy/Aim.position.y = -(abs($Recoil.position.x) + abs($Recoil.position.y))
	$Rotation/Recoil/Joy/Aim2.rotation_degrees = (current_recoil + abs(spread))
	$Rotation/Recoil/Joy/Aim.rotation_degrees = -(current_recoil + abs(spread))
	$CrossHair/Static/Cross1.offset.x = 16 + (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross1.offset.y = -16 - (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross2.offset.x = 16 + (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross2.offset.y = -16 - (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross3.offset.x = 16 + (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross3.offset.y = -16 - (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross4.offset.x = 16 + (current_recoil + abs(spread)) * 2
	$CrossHair/Static/Cross4.offset.y = -16 - (current_recoil + abs(spread)) * 2
	$CrossHair/Inner/CrossUp.position.y = -36 - (current_recoil + abs(spread))
	$CrossHair/Inner/CrossDown.position.y = 36 + (current_recoil + abs(spread))
	$CrossHair/Inner/CrossRight.position.x = 36 + (current_recoil + abs(spread))
	$CrossHair/Inner/CrossLeft.position.x = -36 - (current_recoil + abs(spread))
	$CrossHair/Inner/CrossUp.offset.y = 12 - (abs($Recoil.position.x) + abs($Recoil.position.y)) * 2
	$CrossHair/Inner/CrossDown.offset.y = $CrossHair/Inner/CrossUp.offset.y
	$CrossHair/Inner/CrossRight.offset.y = $CrossHair/Inner/CrossUp.offset.y
	$CrossHair/Inner/CrossLeft.offset.y = $CrossHair/Inner/CrossUp.offset.y
	$CrossHair/Static/AmmoR.position.x = -64 + (abs($Recoil.position.x) + abs($Recoil.position.y)) + (current_recoil + abs(spread))
	$CrossHair/Static/AmmoL.position.x = 64 - (abs($Recoil.position.x) + abs($Recoil.position.y)) - (current_recoil + abs(spread))
	if !bare and gun != null:
		$CrossHair/Static/AmmoR.max_value = gun.max_ammo
		$CrossHair/Static/AmmoR.value = current_ammo
		$CrossHair/Static/AmmoL.max_value = gun.max_ammo
		$CrossHair/Static/AmmoL.value = current_ammo
	if aim and current_recoil > recoil * 10:
		$CrossHair/Inner/CrossUp.hide()
	else:
		$CrossHair/Inner/CrossUp.show()
	if reloading or switching and !aim:
		$CrossHair/Outer.rotation_degrees += 4 * Setting.inverse
	else:
		var current_rotate = ceili($CrossHair/Outer.rotation_degrees/180)
		$CrossHair/Outer.rotation_degrees = lerpf($CrossHair/Outer.rotation_degrees,180 * current_rotate,0.05 * Setting.inverse)
		if abs($CrossHair/Outer.rotation_degrees - 180 * current_rotate) < 1:
			$CrossHair/Outer.rotation_degrees = 0
	if Key.ping:
		var ins = mark.instantiate()
		ins.id = get_parent().id
		if $Ping.is_colliding() and $Ping.get_collider() != null:
			if $CrossHair/Pick.is_colliding() and $CrossHair/Pick.get_collider(0) != null and $CrossHair/Pick.get_collider(0).get_class() == "Area2D":
				ins.state = 1
				$CrossHair/Pick.get_collider(0).add_child(ins)
				if $CrossHair/Pick.get_collider(0).is_in_group("mark"):
					$CrossHair/Pick.get_collider(0).queue_free()
				else:
					$Ping3.play()
			else:
				if $Ping.get_collider().get_class() == "Area2D" and $Ping.get_collider().get_child(0).get_class() != "Area2D":
					ins.state = 1
					$Ping.get_collider().add_child(ins)
					if $Ping.get_collider().is_in_group("mark") and $Ping.get_collider().get_child(0).get_class() != "Area2D":
						$Ping.get_collider().queue_free()
					else:
						$Ping3.play()
				else:
					ins.state = 0
					ins.global_position = $Ping.get_collision_point()
					get_tree().get_root().add_child(ins)
					$Ping2.play()
					
		else:
			ins.state = 0
			ins.global_position = $CrossHair.global_position
			get_tree().get_root().add_child(ins)
			$Ping2.play()
	if spotter > 0 and aim and $Ping.is_colliding() and $Ping.get_collider() != null and $Ping.get_collider().get_class() == "Area2D" and !$Ping.get_collider().is_in_group("mark") and !$Ping.get_collider().get_child(0).is_in_group("mark"):
		var ins = mark.instantiate()
		ins.state = 1
		$Ping.get_collider().add_child(ins)
		$Ping.get_collider().move_child(ins,0)
		$Ping3.play()
var melee = false
var switch_count = 1
var back_count = 1
var switching = false
var bare = true
var slot_1 = true
var slot_2 = false
var break_action = false
var on_slot_1 = true
func switch():
	if (Key.scroll_up and !pack_opening or $Inventory/Weapon/Weapon1.is_hovered() and Input.is_action_just_pressed("ui_select")) and !get_parent().igniting and !melee:
		if switch_count > 0:
			if switch_count > 1:
				switch_count -= 1
				on_slot_1 = true
				$Switch.start(0.5)
		else:
			switch_count += 1
			$Switch.start(0.5)
	if (Key.scroll_down and !pack_opening or $Inventory/Weapon/Weapon2.is_hovered() and Input.is_action_just_pressed("ui_select")) and !get_parent().igniting and !melee:
		if switch_count > 0:
			if switch_count < 2 and get_child(1).get_class() == "Node2D":
				switch_count += 1
				on_slot_1 = false
				$Switch.start(0.5)
		else:
			switch_count += 1
			$Switch.start(0.5)
	if Key.scroll and !get_parent().igniting and !melee and get_child(1).get_class() == "Node2D":
		if switch_count > 0:
			on_slot_1 = !on_slot_1
			$Switch.start(0.5)
		else:
			switch_count += 1
			$Switch.start(0.5)
	if $Switch.time_left > 0:
		switching = true
		break_action = true
	else:
		switching = false
		$Switch.stop()
	if switch_count != 0:
		if on_slot_1:
			switch_count = 1
		else:
			switch_count = 2
	if switch_count > 0 and !bare:
		back_count = switch_count
	match switch_count:
		0:
			slot_1 = false
			slot_2 = false
		1:
			slot_1 = true
			slot_2 = false
		2:
			slot_1 = false
			slot_2 = true

@onready var PistolA = preload("res://Screen/Asset/Weapon/PistolA.tscn")
@onready var PistolB = preload("res://Screen/Asset/Weapon/PistolB.tscn")
@onready var PistolC = preload("res://Screen/Asset/Weapon/PistolC.tscn")
@onready var PistolD = preload("res://Screen/Asset/Weapon/PistolD.tscn")
@onready var RifleA = preload("res://Screen/Asset/Weapon/RifleA.tscn")
@onready var RifleB = preload("res://Screen/Asset/Weapon/RifleB.tscn")
@onready var RifleC = preload("res://Screen/Asset/Weapon/RifleC.tscn")
@onready var SniperA = preload("res://Screen/Asset/Weapon/SniperA.tscn")
@onready var SniperB = preload("res://Screen/Asset/Weapon/SniperB.tscn")
@onready var SMGA = preload("res://Screen/Asset/Weapon/SMGA.tscn")
@onready var SMGB = preload("res://Screen/Asset/Weapon/SMGB.tscn")
@onready var SMGC = preload("res://Screen/Asset/Weapon/SMGC.tscn")
@onready var ShotgunA = preload("res://Screen/Asset/Weapon/Shotgun.tscn")
@onready var ShotgunB = preload("res://Screen/Asset/Weapon/ShotgunB.tscn")
@onready var ShotgunC = preload("res://Screen/Asset/Weapon/ShotgunC.tscn")
@onready var DMR = preload("res://Screen/Asset/Weapon/DMR.tscn")
@onready var LMG = preload("res://Screen/Asset/Weapon/LMG.tscn")
@onready var LauncherA = preload("res://Screen/Asset/Weapon/Launcher.tscn")
@onready var drop = preload("res://Screen/Asset/Entity/Stuff/Drop.tscn")
@onready var Perk1 = preload("res://Screen/Asset/Function/HUD/perk1.tscn")
@onready var Perk2 = preload("res://Screen/Asset/Function/HUD/perk2.tscn")
@onready var Perk4 = preload("res://Screen/Asset/Function/HUD/perk4.tscn")
@onready var Nade = preload("res://Screen/Asset/Function/HUD/Nade.tscn")
@onready var item = preload("res://Screen/Asset/Function/HUD/Item.tscn")
var gun
var current_gun = 0
var stuff
var weapon_1
var weapon_2
var hovering = 0
var perk_code = 0

var loadout = 0
var echo = 0
var recharge = 0
var spotter = 0
var payout = 0

func quickpack():
	$Inventory/Weapon.visible = pack_opening
	$Inventory/Equipment.visible = pack_opening
	$CrossHair.visible = !pack_opening and !buying and !(Key.aim and Setting.stick_aim)
	if pack_opening:
		$Inventory/Weapon.position.x = lerpf($Inventory/Weapon.position.x,128,0.2 * Setting.inverse)
		$Inventory/Equipment.position.x = lerpf($Inventory/Equipment.position.x,128,0.2 * Setting.inverse)
		$Inventory/Loadout.position.x = lerpf($Inventory/Loadout.position.x,128,0.2 * Setting.inverse)
		$Inventory/Perk.position.x = lerpf($Inventory/Perk.position.x,96,0.2 * Setting.inverse)
		$Inventory.modulate.a = lerpf($Inventory.modulate.a,1,0.5 * Setting.inverse)
		if weapon_1 != null:
			$Inventory/Weapon/Weapon1.show()
			$Inventory/Weapon/Weapon1/Gun.frame = weapon_1.code
			$Inventory/Weapon/Weapon1/Label.text = str(weapon_1.current_ammo + weapon_1.reverse_ammo)
			$Inventory/Weapon/Weapon1/Type.frame = int(weapon_1.code/10)
			$Inventory/Weapon/Weapon1/Scope.frame = weapon_1.scope
			$Inventory/Weapon/Weapon1/Foregrip.frame = weapon_1.foregrip
			$Inventory/Weapon/Weapon1/Muzzle.frame = weapon_1.muzzle
			$Inventory/Weapon/Weapon1/Magazine.frame = weapon_1.magazine
			$Inventory/Weapon/Weapon1/Laser.frame = weapon_1.laser
			$Inventory/Weapon/Weapon1/Stock.frame = weapon_1.stock
		else:
			$Inventory/Weapon/Weapon1.hide()
		if weapon_2 != null:
			$Inventory/Weapon/Weapon2.show()
			$Inventory/Weapon/Weapon2/Gun.frame = weapon_2.code
			$Inventory/Weapon/Weapon2/Label.text = str(weapon_2.current_ammo + weapon_2.reverse_ammo)
			$Inventory/Weapon/Weapon2/Type.frame = int(weapon_2.code/10)
			$Inventory/Weapon/Weapon2/Scope.frame = weapon_2.scope
			$Inventory/Weapon/Weapon2/Foregrip.frame = weapon_2.foregrip
			$Inventory/Weapon/Weapon2/Muzzle.frame = weapon_2.muzzle
			$Inventory/Weapon/Weapon2/Magazine.frame = weapon_2.magazine
			$Inventory/Weapon/Weapon2/Laser.frame = weapon_2.laser
			$Inventory/Weapon/Weapon2/Stock.frame = weapon_2.stock
		else:
			$Inventory/Weapon/Weapon2.hide()
		$Inventory/Equipment/Nade/Bar.value = Inventory.lethal.size()
		$Inventory/Equipment/Nade/Type.frame = lethal
		$Inventory/Equipment/Nade2/Bar.value = Inventory.tactical.size()
		$Inventory/Equipment/Nade2/Type.frame = tactical
		$Inventory/Equipment/Nade.disabled = !Inventory.lethal.size() > 0
		$Inventory/Equipment/Nade2.disabled = !Inventory.tactical.size() > 0
		if $Inventory/Weapon/Weapon1.is_hovered():
			$Inventory/Pick.show()
			$Inventory/Pick.global_position = $Inventory/Weapon/Weapon1.global_position
			$Inventory/Pick.size.x = 128
			$Inventory/Pick/Interact.position.y = 128
			$Inventory/Pick/Interact/LMB.hide()
			$Inventory/Pick/Interact/stow.hide()
			$Inventory/Pick/Interact/RMB.show()
			$Inventory/Pick/Interact/equip.show()
			$Inventory/Pick/Interact/equip.text = tr("PICK")
			$Inventory/Weapon/LMB.show()
			$Inventory/Weapon/LMB2.show()
			$Inventory/Weapon/LMB3.show()
			$Inventory/Pick/Label.text = str(Library.named(int(Inventory.weapon[0]/1000000000)))
		elif $Inventory/Weapon/Weapon2.is_hovered():
			$Inventory/Pick.show()
			$Inventory/Pick.global_position = $Inventory/Weapon/Weapon2.global_position
			$Inventory/Pick.size.x = 128
			$Inventory/Pick/Interact.position.y = 64
			$Inventory/Pick/Interact/LMB.hide()
			$Inventory/Pick/Interact/stow.hide()
			$Inventory/Pick/Interact/RMB.show()
			$Inventory/Pick/Interact/equip.show()
			$Inventory/Pick/Interact/equip.text = tr("PICK")
			$Inventory/Weapon/LMB.show()
			$Inventory/Weapon/LMB2.show()
			$Inventory/Weapon/LMB3.show()
			$Inventory/Pick/Label.text = str(Library.named(int(Inventory.weapon[1]/1000000000)))
		elif $Inventory/Equipment/Kit/Armor.is_hovered():
			$Inventory/Pick.show()
			$Inventory/Pick.size.x = 64
			$Inventory/Pick.global_position = $Inventory/Equipment/Kit/Armor.global_position
			$Inventory/Pick/Interact.position.y = 64
			$Inventory/Pick/Label.text = "ARMOR"
			$Inventory/Pick/Interact/RMB.hide()
			$Inventory/Pick/Interact/stow.hide()
			$Inventory/Weapon/LMB.show()
			$Inventory/Weapon/LMB2.hide()
			$Inventory/Weapon/LMB3.show()
			$Inventory/Pick/Interact/LMB.visible = (get_parent().armor < 150)
			$Inventory/Pick/Interact/equip.visible = (get_parent().armor < 150)
			$Inventory/Pick/Interact/equip.text = tr("PICK")
		elif $Inventory/Equipment/Kit/Aid.is_hovered():
			$Inventory/Pick.show()
			$Inventory/Pick.size.x = 64
			$Inventory/Pick.global_position = $Inventory/Equipment/Kit/Aid.global_position
			$Inventory/Pick/Interact.position.y = 64
			$Inventory/Pick/Label.text = "HEAL"
			$Inventory/Pick/Interact/RMB.hide()
			$Inventory/Pick/Interact/stow.hide()
			$Inventory/Weapon/LMB.show()
			$Inventory/Weapon/LMB2.hide()
			$Inventory/Weapon/LMB3.show()
			$Inventory/Pick/Interact/equip.text = "Use"
		elif $Inventory/Equipment/Nade.is_hovered():
			$Inventory/Pick.show()
			$Inventory/Pick.size.x = 64
			$Inventory/Pick.global_position = $Inventory/Equipment/Nade.global_position
			$Inventory/Pick/Interact/RMB.hide()
			$Inventory/Pick/Interact/stow.hide()
			$Inventory/Weapon/LMB.hide()
			$Inventory/Weapon/LMB2.hide()
			$Inventory/Weapon/LMB3.hide()
			$Inventory/Pick/Interact.position.y = 64
			$Inventory/Pick/Interact/equip.hide()
			match lethal:
				0: $Inventory/Pick/Label.text = tr("FRAG")
				1: $Inventory/Pick/Label.text = tr("FIRE")
				2: $Inventory/Pick/Label.text = tr("KNIFE")
				3: $Inventory/Pick/Label.text = tr("MINE")
		elif $Inventory/Equipment/Nade2.is_hovered():
			$Inventory/Pick.show()
			$Inventory/Pick.size.x = 64
			$Inventory/Pick.global_position = $Inventory/Equipment/Nade2.global_position
			$Inventory/Pick/Interact/RMB.hide()
			$Inventory/Pick/Interact/stow.hide()
			$Inventory/Weapon/LMB.hide()
			$Inventory/Weapon/LMB2.hide()
			$Inventory/Weapon/LMB3.hide()
			$Inventory/Pick/Interact.position.y = 64
			$Inventory/Pick/Interact/equip.hide()
			match tactical:
				4: $Inventory/Pick/Label.text = tr("SMOKE")
				5: $Inventory/Pick/Label.text = tr("FLASH")
				6: $Inventory/Pick/Label.text = tr("STIM")
				7: $Inventory/Pick/Label.text = tr("DECOY")
		else:
			for i in $Inventory/Loadout.get_children():
				if i.is_hovered():
					$Inventory/Pick.global_position = i.global_position
					$Inventory/Pick.size.x = i.size.x
					$Inventory/Pick/Interact/RMB.hide()
					$Inventory/Pick/Interact/stow.hide()
					$Inventory/Pick/Interact/equip.show()
					$Inventory/Pick/Interact/equip.text = tr("PICK")
					if $Inventory/Pick.position.y < 70:
						$Inventory/Pick/Interact.position.y = 128
					else:
						$Inventory/Pick/Interact.position.y = 64
					match i.type:
						0: $Inventory/Pick/Label.text = str(Library.named(int(i.code/1000000000)))
						1: $Inventory/Pick/Label.text = str(Library.named(int(str(27) + str(i.code))))
						2: match i.code:
							1: pass
			if $Inventory/Loadout.get_child_count() > 0 and $Inventory/Loadout.get_child(hovering) != null and $Inventory/Loadout.get_child(hovering).is_hovered():
				$Inventory/Pick.show()
				$Inventory/Weapon/LMB.show()
				$Inventory/Weapon/LMB2.show()
				$Inventory/Weapon/LMB3.hide()
			else:
				$Inventory/Pick.hide()
				$Inventory/Weapon/LMB.show()
				$Inventory/Weapon/LMB2.show()
				$Inventory/Weapon/LMB3.show()
				if hovering < $Inventory/Loadout.get_child_count():
					hovering += 1
				else:
					hovering = 0
		$Inventory/Equipment/Kit/Armor.disabled = (get_parent().armor == 150)
		if Inventory.loadout > 2:
			$Inventory/Equipment/Grid.size.x = 64 * int((Inventory.loadout + 2)/2)
			$Inventory/Equipment/Grid.size.y = 128
		else:
			$Inventory/Equipment/Grid.size.x = 64 * (Inventory.loadout + 2)
			$Inventory/Equipment/Grid.size.y = 64
		match Inventory.current_perk:
			1: 
				$Inventory/Perk/Slot1.frame = 2
				$Inventory/Perk/Slot2.frame = 1
			2:
				$Inventory/Perk/Slot1.frame = 1
				$Inventory/Perk/Slot2.frame = 2
		if $Inventory/Perk.is_hovered() and Input.is_action_just_pressed("ui_select"):
			if Inventory.current_perk == 1:
				Inventory.perk_key = Inventory.perk_mod_2
				perk_load(Inventory.perk_key)
				Inventory.current_perk = 2
			else:
				Inventory.perk_key = Inventory.perk_mod_1
				perk_load(Inventory.perk_key)
				Inventory.current_perk = 1
	else:
		$Inventory/Weapon.position.x = lerpf($Inventory/Weapon.position.x,-128,0.2 * Setting.inverse)
		$Inventory/Equipment.position.x = lerpf($Inventory/Equipment.position.x,-128,0.2 * Setting.inverse)
		$Inventory/Loadout.position.x = lerpf($Inventory/Loadout.position.x,-128,0.2 * Setting.inverse)
		$Inventory/Perk.position.x = lerpf($Inventory/Perk.position.x,-128,0.2 * Setting.inverse)
		$Inventory.modulate.a = lerpf($Inventory.modulate.a,0,0.5 * Setting.inverse)
	$Inventory.visible = ($Inventory.modulate.a > 0.05)
	$Inventory/Decor1.rotation_degrees += 0.5 * Setting.inverse
	$Inventory/Decor2.rotation_degrees += 2 * Setting.inverse
	$Inventory/Decor3.rotation_degrees -= 1 * Setting.inverse
	$Inventory/Decor4.rotation_degrees += 4 * Setting.inverse
	$Inventory/Weapon/Weapon1/Current.visible = slot_1
	$Inventory/Weapon/Weapon2/Current.visible = slot_2
	if get_child(0).get_class() != "Node2D" and Inventory.weapon[0] > 0:
		replacing_gun(Inventory.weapon[0])
	if get_child(1).get_class() != "Node2D" and Inventory.weapon[1] > 0:
		replacing_gun(Inventory.weapon[1])
	for i in $Inventory/Loadout.get_children():
		if i.is_hovered() and Input.is_action_just_pressed("ui_select"):
			match i.type:
				0:
					if slot_1:
						Inventory.weapon[0] = i.code
					if slot_2:
						Inventory.weapon[1] = i.code
					var w = int(str(1) + str(int(current_gun / 10)) + str(current_gun % 10) + str(int(current_ammo / 100)) + str(int(current_ammo % 100/10)) + str(current_ammo % 10) + str(gun.scope) + str(gun.foregrip) + str(gun.muzzle) + str(gun.magazine) + str(gun.laser) + str(gun.stock))
					if int((i.code % 100000000000)/1000000000) < 4 and int((w % 100000000000)/1000000000) > 3:
						Inventory.used_slot += 1
					if int((i.code % 100000000000)/1000000000) > 3 and int((w % 100000000000)/1000000000) < 4:
						Inventory.used_slot -= 1
					replacing_gun(i.code)
					i.code = w
					i.update()
				1:
					var new_nade = 0
					var nade_side = 0
					if i.code < 4:
						new_nade = lethal
						nade_side = Inventory.lethal.size()
						Inventory.lethal.clear()
						for j in i.count:
							Inventory.lethal.append(i.code)
					else:
						new_nade = tactical
						nade_side = Inventory.tactical.size()
						Inventory.tactical.clear()
						for j in i.count:
							Inventory.tactical.append(i.code)
					if nade_side > 0:
						i.code = new_nade
						i.count = nade_side
						i.update()
					else:
						i.queue_free()
						Inventory.used_slot -= 1
				2: match i.code:
					0:
						refill()
						i.queue_free()
						Inventory.used_slot -= 1
		if Inventory.used_slot > Inventory.loadout + 2 or i.is_hovered() and Input.is_action_just_pressed("ui_deselect"):
			match i.type:
				0: 
					var drop_ins = drop.instantiate()
					drop_ins.global_position = global_position
					drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
					drop_ins.code = i.code
					get_tree().get_root().add_child(drop_ins)
					Inventory.used_slot -= 2
					i.queue_free()
					emit_signal("cancel")
				1: 
					for j in i.count:
						var drop_ins = drop.instantiate()
						drop_ins.global_position = global_position
						drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
						drop_ins.code = int(str(27) + str(i.code))
						get_tree().get_root().add_child(drop_ins)
					Inventory.backpack.remove_at(i.get_index())
					Inventory.used_slot -= 1
					i.queue_free()
					emit_signal("cancel")
				2:
					var drop_ins = drop.instantiate()
					drop_ins.global_position = global_position
					drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
					drop_ins.code = int(str(4) + str(i.code))
					get_tree().get_root().add_child(drop_ins)
					Inventory.used_slot -= 1
					i.queue_free()
					emit_signal("cancel")
		if i.type == 0 and i.get_index() > 0 and $Inventory/Loadout.get_child(i.get_index() - 1).type > 0:
			$Inventory/Loadout.move_child(i,i.get_index() - 1)
var pick_cool = 0
func pick():
	$Pick.scale = Vector2(1,1)/Vector2(zoom,zoom)
	$Interact.scale = Vector2(1,1)/Vector2(zoom,zoom)
	if abs($CrossHair.position.x) < 240 and abs($CrossHair.position.y) < 240 and !buying:
		$PickRange.position.x = clampf($CrossHair.position.x,-120,120)
		$PickRange.position.y = clampf($CrossHair.position.y,-120,240)
	else:
		$PickRange.position.x = 0
		$PickRange.position.y = 0
	if $PickRange.is_colliding() and $PickRange.get_collider(0) != null:
		stuff = $PickRange.get_collider(0).get_parent()
	if stuff != null and $PickRange.is_colliding():
		if stuff.is_in_group("Interact"):
			if !pack_opening and !buying:
				$Interact.show()
			$Interact.global_position.x = lerpf($Interact.global_position.x,stuff.global_position.x,0.2 * Setting.inverse)
			$Interact.global_position.y = lerpf($Interact.global_position.y,stuff.global_position.y - 64,0.5 * Setting.inverse)
			$Interact/Interact/equip.text = tr("PICK")
			if Key.use:
				stuff.interact()
				if stuff.is_in_group("buystation"):
					buying = !buying
		elif stuff.is_in_group("ammo"):
			$Interact.show()
			$Interact.global_position.x = lerpf($Interact.global_position.x,stuff.global_position.x,0.2 * Setting.inverse)
			$Interact.global_position.y = lerpf($Interact.global_position.y,stuff.global_position.y - 64,0.5 * Setting.inverse)
			$Interact/Interact/equip.text = tr("PICK")
			if Key.use:
				refill()
		else:
			buying = false
			$Interact.hide()
	else:
		buying = false
		$Interact.hide()
	if stuff != null and stuff.is_in_group("contract") and $PickRange.is_colliding():
		if Key.use:
			Contract.contract.append(stuff.type)
			Contract.cash.append(stuff.cash)
			Contract.progress.append(stuff.progress)
			Contract.time.append(stuff.time * 3600)
			stuff.queue_free()
	if stuff != null and stuff.is_in_group("stuff") and $PickRange.is_colliding() and !get_parent().velocity.x > 1600:
		if Key.use and stuff.key[0] == 1:
			if Inventory.weapon[1] > 0:
				var drop_ins = drop.instantiate()
				drop_ins.global_position = global_position
				drop_ins.code = gun.gun
				drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
				get_tree().get_root().add_child(drop_ins)
				replacing_gun(stuff.code)
			else:
				replacing_gun(stuff.code)
				switch_count += 1
				on_slot_1 = false
			stuff.queue_free()
		if Key.use and stuff.key[0] == 2 and stuff.key[1] == 7:
			if stuff.key[2] < 4 and stuff.key[2] != lethal:
				for i in Inventory.lethal.size():
					var drop_ins = drop.instantiate()
					drop_ins.global_position = global_position
					drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
					drop_ins.code = int(str(27) + str(lethal))
					get_tree().get_root().add_child(drop_ins)
				Inventory.lethal.clear()
				lethal = stuff.key[2]
				stuff.queue_free()
				emit_signal("picked")
			if stuff.key[2] > 3 and stuff.key[2] != tactical:
				for i in Inventory.tactical.size():
					var drop_ins = drop.instantiate()
					drop_ins.global_position = global_position
					drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
					drop_ins.code = int(str(27) + str(tactical))
					get_tree().get_root().add_child(drop_ins)
				Inventory.tactical.clear()
				tactical = stuff.key[2]
				stuff.queue_free()
				emit_signal("picked")
		if Key.use and stuff.key[0] == 4 and Inventory.used_slot < Inventory.loadout + 2:
			Inventory.backpack.append(20)
			var ins = item.instantiate()
			ins.code = 0
			$Inventory/Loadout.add_child(ins)
			Inventory.used_slot += 1
			stuff.queue_free()
			emit_signal("picked")
		$Pick/Rarity2.value = stuff.rarity
		match stuff.key[0]:
			1:
				$Pick/Gun.show()
				$Pick/Type.show()
				$Pick/Perk.hide()
				$Pick/Item.hide()
				$Pick/Gun.frame = int(str(stuff.key[1]) + str(stuff.key[2]))
				$Pick/Type.frame = stuff.key[1]
				match stuff.key[1]:
					0: 
						if stuff.key[2] > 3:
							$Pick/Class.text = "Sub-Machine Gun"
						else:
							$Pick/Class.text = "Sidearm"
						match stuff.key[2]:
							0: $Pick/Name.text = "P54"
							1: $Pick/Name.text = "EM50"
							2: $Pick/Name.text = "P15-C"
							3: $Pick/Name.text = "STA9"
							4: $Pick/Name.text = "B5Q-C"
							5: $Pick/Name.text = "G7Q-A"
							6: $Pick/Name.text = "B9Q-PD"
					1: match stuff.key[2]:
						0: 
							$Pick/Class.text = "Assault Rifle"
							$Pick/Name.text = "Spec556"
						1:
							$Pick/Class.text = "Assault Rifle"
							$Pick/Name.text = "KR762"
						2:
							$Pick/Class.text = "Assault Rifle"
							$Pick/Name.text = "BPF556"
						3:
							$Pick/Class.text = "Battle Rifle"
							$Pick/Name.text = "ST28"
						4:
							$Pick/Class.text = "Light Machine Gun"
							$Pick/Name.text = "HG48"
					2: match stuff.key[2]:
						0: 
							$Pick/Class.text = "Pump-Action Shotgun"
							$Pick/Name.text = "BK12"
						1:
							$Pick/Class.text = "Semi-Auto Shotgun"
							$Pick/Name.text = "VH12"
						2: 
							$Pick/Class.text = "Sawed-off Shotgun"
							$Pick/Name.text = "TB12-C"
					3: match stuff.key[2]:
						0: 
							$Pick/Class.text = "Bolt-Action Sniper"
							$Pick/Name.text = "SK11 SR"
						1: 
							$Pick/Class.text = "Marksman Rifle"
							$Pick/Name.text = "SVC8 SR"
					4: 
						$Pick/Class.text = "Rocket Laucher"
						$Pick/Name.text = "RL85"
			6:
				match stuff.key[1]:
					5:
						$Pick/Perk.frame = stuff.key[2] + 3
						$Pick/Class.text = "Perk Tier 2"
						match stuff.key[2]:
							1: $Pick/Name.text = "Resilience"
							2: $Pick/Name.text = "Echo"
							3: $Pick/Name.text = "Succinct"
							4: $Pick/Name.text = "Spotter"
							5: $Pick/Name.text = "Sonic"
							6: $Pick/Name.text = "Payout"
							7: $Pick/Name.text = "Overload"
							8: $Pick/Name.text = "Berserk"
					6:
						$Pick/Perk.frame = stuff.key[2] + 11
						$Pick/Class.text = "Perk Tier 3"
						match stuff.key[2]:
							1: $Pick/Name.text = "Phantom"
							2: $Pick/Name.text = "Alert"
							3: $Pick/Name.text = "Recharge"
							4: $Pick/Name.text = "Shifter"
					_:
						$Pick/Perk.frame = stuff.key[1] - 1
						$Pick/Class.text = "Perk Tier 1"
						match stuff.key[1]:
							1: $Pick/Name.text = "Loadout"
							2: $Pick/Name.text = "Conscious"
							3: $Pick/Name.text = "Recovery"
							4: $Pick/Name.text = "Overclock"
			2: if stuff.key[1] == 7:
				$Pick/Class.text = "Throwable"
				match stuff.key[2]:
					0: $Pick/Name.text = "Frag Grenade"
					1: $Pick/Name.text = "Incendiary"
					2: $Pick/Name.text = "Frag Kunai"
					3: $Pick/Name.text = "Land Mine"
					4: $Pick/Name.text = "Smoke Grenade"
					5: $Pick/Name.text = "Flashbang!"
					6: $Pick/Name.text = "Crushzone"
					7: $Pick/Name.text = "Decoy Grenade"
		$Pick/Rarity.frame = stuff.rarity
		if stuff.rarity > 4:
			$Pick.frame = 1
			$Pick/Gun.modulate = Color(1,1,1)
			$Pick/Rarity.modulate = Color(1,1,1)
		elif stuff.rarity > 2 and stuff.rarity < 5:
			$Pick.frame = 0
			$Pick/Gun.modulate = Color(0.7,0.7,0.7)
			$Pick/Rarity.modulate = Color(0.7,0.7,0.7)
		else:
			$Pick.frame = 0
			$Pick/Gun.modulate = Color(0.7,0.7,0.7)
			$Pick/Rarity.modulate = Color(0.44,0.44,0.44)
		if !$Switch.time_left > 0 and $PickRange.is_colliding():
			$Pick.global_position.x = lerpf($Pick.global_position.x,stuff.global_position.x,0.2 * Setting.inverse)
			$Pick.global_position.y = lerpf($Pick.global_position.y,stuff.global_position.y - 192,0.5 * Setting.inverse)
		if stuff.key[0] == 3:
			if Key.using:
				stuff.picking += 1 * Setting.inverse
			else:
				stuff.picking = 0
			if stuff.picking > 60:
				get_parent().sentry_cool -= stuff.time/2
				stuff.queue_free()
		if stuff.key[0] == 6:
			if (stuff.key[1] == 6 and Inventory.perk_slot > 12) or (stuff.key[1] == 5 and Inventory.perk_slot > 14) or (stuff.key[1] < 5 and Inventory.perk_slot > 15):
				$Inventory/Perk/Interact/equip.text = "Cancel"
			else:
				$Inventory/Perk/Interact/equip.text = tr("PICK")
		if Key.use and stuff.key[0] == 6:
			match stuff.key[1]:
				6:
					if Inventory.perk_slot < 13:
						var ins = Perk4.instantiate()
						match stuff.key[2]:
							1: if get_parent().phantom < 1:
								get_parent().phantom += 1
								Inventory.perk_slot += 4
								ins.code = 61
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(6199)
								stuff.queue_free()
							2: if get_parent().alert < 1:
								get_parent().alert += 1
								Inventory.perk_slot += 4
								ins.code = 62
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(6299)
								stuff.queue_free()
							3: if recharge < 1:
								recharge += 1
								Inventory.perk_slot += 4
								ins.code = 63
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(6399)
								stuff.queue_free()
							4: if get_parent().shifter < 1:
								get_parent().shifter += 1
								Inventory.perk_slot += 4
								ins.code = 64
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(6499)
								stuff.queue_free()
				5: 
					if Inventory.perk_slot < 15:
						var ins = Perk2.instantiate()
						match stuff.key[2]:
							1: if get_parent().resilience < 1:
								get_parent().resilience += 1
								Inventory.perk_slot += 2
								ins.code = 51
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(51)
								stuff.queue_free()
							2: if echo < 1:
								echo += 1
								Inventory.perk_slot += 2
								ins.code = 52
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(52)
								stuff.queue_free()
							3: if get_parent().succinct < 1:
								get_parent().succinct += 1
								Inventory.perk_slot += 2
								ins.code = 53
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(53)
								stuff.queue_free()
							4: if spotter < 1:
								spotter += 1
								Inventory.perk_slot += 2
								ins.code = 54
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(54)
								stuff.queue_free()
							5: if get_parent().sonic < 2:
								get_parent().sonic += 1
								Inventory.perk_slot += 2
								ins.code = 55
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(55)
								stuff.queue_free()
							6: if payout < 2:
								payout += 1
								Inventory.perk_slot += 2
								ins.code = 56
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(56)
								stuff.queue_free()
							7: if get_parent().overload < 4:
								get_parent().overload += 1
								Inventory.perk_slot += 2
								ins.code = 57
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(57)
								stuff.queue_free()
							8: if get_parent().berserk < 4:
								get_parent().berserk += 1
								Inventory.perk_slot += 2
								ins.code = 58
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(58)
								stuff.queue_free()
				_: 
					if Inventory.perk_slot < 16:
						var ins = Perk1.instantiate()
						match stuff.key[1]:
							1: if loadout < 6:
								loadout += 1
								Inventory.perk_slot += 1
								Inventory.loadout += 1
								ins.code = 1
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(1)
								stuff.queue_free()
							2: if get_parent().conscious < 2:
								get_parent().conscious += 1
								Inventory.perk_slot += 1
								ins.code = 2
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(2)
								stuff.queue_free()
							3: if get_parent().recovery < 4:
								get_parent().recovery += 1
								Inventory.perk_slot += 1
								ins.code = 3
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(3)
								stuff.queue_free()
							4: if get_parent().overclock < 4:
								get_parent().overclock += 1
								Inventory.perk_slot += 1
								ins.code = 4
								$Inventory/Perk/PerkBox.add_child(ins)
								Inventory.perk_key.append(4)
								stuff.queue_free()
			match Inventory.current_perk:
				1: Inventory.perk_mod_1 = Inventory.perk_key
				2: Inventory.perk_mod_2 = Inventory.perk_key
				3: Inventory.perk_mod_3 = Inventory.perk_key
				4: Inventory.perk_mod_4 = Inventory.perk_key
			emit_signal("picked")
	if pack_opening:
		for perk in $Inventory/Perk/PerkBox.get_children():
			if perk.is_hovered():
				if Input.is_action_just_pressed("ui_deselect"):
					var ins = drop.instantiate()
					ins.global_position = global_position
					ins.code = int(str(6) + str(perk.code))
					ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
					get_tree().get_root().add_child(ins)
					Inventory.perk_slot -= perk.cost
					Inventory.perk_key.remove_at(perk.get_index())
					if perk.code == 1:
						Inventory.loadout -= 1
					perk_load(Inventory.perk_key)
					match Inventory.current_perk:
						1: Inventory.perk_mod_1 = Inventory.perk_key
						2: Inventory.perk_mod_2 = Inventory.perk_key
						3: Inventory.perk_mod_3 = Inventory.perk_key
						4: Inventory.perk_mod_4 = Inventory.perk_key
					emit_signal("cancel")
	for auto_pick in $PickRange.get_collision_count():
		if $PickRange.is_colliding() and $PickRange.get_collider(auto_pick) != null and $PickRange.get_collider(auto_pick).get_parent().is_in_group("stuff") and !pick_cool > 0:
			var picking_stuff = $PickRange.get_collider(auto_pick).get_parent()
			match picking_stuff.key[0]:
				2: match picking_stuff.key[1]:
					0: if Inventory.ammo[1] <= 600 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						Inventory.ammo[1] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
						emit_signal("picked")
					1: if Inventory.ammo[0] <= 600 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						Inventory.ammo[0] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
						emit_signal("picked")
					2: if Inventory.ammo[2] <= 300 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						Inventory.ammo[2] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
						emit_signal("picked")
					3: if Inventory.ammo[3] <= 300 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						Inventory.ammo[3] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
						emit_signal("picked")
					4: if Inventory.ammo[4] <= 100 - int(str(picking_stuff.key[3]) + str(picking_stuff.key[4])):
						Inventory.ammo[4] += int(str(picking_stuff.key[3]) + str(picking_stuff.key[4]))
						picking_stuff.queue_free()
						emit_signal("picked")
					
					6: if Inventory.armor < 20:
						Inventory.armor += 1
						picking_stuff.queue_free()
						emit_signal("picked")
					7:
						for current_nade in $Inventory/Loadout.get_children():
							if current_nade.type == 1 and current_nade.code == picking_stuff.key[2] and current_nade.count < 2:
								current_nade.count += 1
								current_nade.update()
								picking_stuff.queue_free()
								emit_signal("picked")
						if lethal == picking_stuff.key[2] and Inventory.lethal.size() < 2:
							Inventory.lethal.append(picking_stuff.key[2])
							picking_stuff.queue_free()
							emit_signal("picked")
						if tactical == picking_stuff.key[2] and Inventory.tactical.size() < 2:
							Inventory.tactical.append(picking_stuff.key[2])
							picking_stuff.queue_free()
							emit_signal("picked")
	pick_cool = move_toward(pick_cool,0,Setting.inverse)
var switch_stow
var stow_hold = 0
var can_stow = false
var reverse_gun = load("res://Screen/Asset/Function/HUD/Weapon.tscn")
func stow():
	if $PickRange.is_colliding() and stuff != null and stuff.is_in_group("stuff") and !pack_opening and Inventory.used_slot < Inventory.loadout + 2:
		$Pick/Interact/Tab.visible = can_stow
		$Pick/Interact/stow.visible = can_stow
		$Pick/Interact/Tab/Tab/Hold.value = stow_hold
		if Key.pack and can_stow:
			stow_hold += 1 * Setting.inverse
		else:
			stow_hold = 0
		if stow_hold == 30:
			match stuff.key[0]:
				1:
					var ins = reverse_gun.instantiate()
					Inventory.backpack.append(stuff.code)
					ins.code = stuff.code
					$Inventory/Loadout.add_child(ins)
					ins.pressed.connect(HUDSound.pressed)
					ins.mouse_entered.connect(HUDSound.select)
					if int((stuff.code % 100000000000)/1000000000) > 3:
						Inventory.used_slot += 2
					else:
						Inventory.used_slot += 1
					emit_signal("picked")
					ins.update()
					stuff.queue_free()
					stow_hold = 0
				2: if stuff.key[1] == 7 and lethal != stuff.key[2] and tactical != stuff.key[2]:
					var ins = Nade.instantiate()
					Inventory.backpack.append(stuff.code)
					ins.code = stuff.key[2]
					$Inventory/Loadout.add_child(ins)
					ins.pressed.connect(HUDSound.pressed)
					ins.mouse_entered.connect(HUDSound.select)
					ins.count = 1
					Inventory.used_slot += 1
					emit_signal("picked")
					ins.update()
					stuff.queue_free()
					stow_hold = 0
		match stuff.key[0]:
			1: can_stow = Inventory.weapon[1] > 0
			2: if stuff.key[1] == 7:
				for current_nade in $Inventory/Loadout.get_children():
					can_stow = current_nade.code != stuff.key[2] and lethal != stuff.key[2] and tactical != stuff.key[2]
	else:
		stow_hold = 0
		$Pick/Interact/Tab.hide()
		$Pick/Interact/stow.hide()
var wheel = false
var buy_gear = true
var buying = false
func buy():
	$Buy.visible = buying
	if buying:
		if global_transform.origin.distance_to(get_global_mouse_position()) > 150:
			$Buy/Wheel/cursor.look_at(get_global_mouse_position())
		for i in $Buy/Wheel.get_children():
			if i.get_index() > 0:
				if abs(i.global_rotation_degrees - $Buy/Wheel/cursor.global_rotation_degrees - 90) < 30:
					i.frame = 1
				else:
					i.frame = 0
		if buy_gear:
			$Buy/Gear.modulate.a = lerpf($Buy/Gear.modulate.a,1,0.5 * Setting.inverse)
			$Buy/Weapon.modulate.a = lerpf($Buy/Weapon.modulate.a,0,0.5 * Setting.inverse)
			$Buy/Gear2.frame = 1
			$Buy/Gear2/Name.modulate = Color(0,0,0)
			$Buy/Weapon2.frame = 0
			$Buy/Weapon2/Name.modulate = Color(1,1,1)
			$Buy/Interact.position.x = -448
			$Buy/Gear.scale.x = lerpf($Buy/Gear.scale.x,1,0.5 * Setting.inverse)
			$Buy/Gear.size.x = lerpf($Buy/Gear.size.x,224,0.5 * Setting.inverse)
			$Buy/Weapon.scale.x = lerpf($Buy/Weapon.scale.x,0.5,0.5 * Setting.inverse)
			$Buy/Weapon.size.x = lerpf($Buy/Weapon.size.x,384,0.5 * Setting.inverse)
			$Buy/Weapon.position.x = lerpf($Buy/Weapon.position.x,-368,0.5 * Setting.inverse)
			$Buy.move_child($Buy/Weapon,0)
		else:
			$Buy/Gear.modulate.a = lerpf($Buy/Gear.modulate.a,0,0.5 * Setting.inverse)
			$Buy/Weapon.modulate.a = lerpf($Buy/Weapon.modulate.a,1,0.5 * Setting.inverse)
			$Buy/Gear2.frame = 0
			$Buy/Gear2/Name.modulate = Color(1,1,1)
			$Buy/Weapon2.frame = 1
			$Buy/Weapon2/Name.modulate = Color(0,0,0)
			$Buy/Interact.position.x = -256
			$Buy/Gear.scale.x = lerpf($Buy/Gear.scale.x,0.5,0.5 * Setting.inverse)
			$Buy/Gear.size.x = lerpf($Buy/Gear.size.x,384,0.5 * Setting.inverse)
			$Buy/Weapon.scale.x = lerpf($Buy/Weapon.scale.x,1,0.5 * Setting.inverse)
			$Buy/Weapon.size.x = lerpf($Buy/Weapon.size.x,224,0.5 * Setting.inverse)
			$Buy/Weapon.position.x = lerpf($Buy/Weapon.position.x,-288,0.5 * Setting.inverse)
			$Buy.move_child($Buy/Gear,0)
		for i in $Buy/Gear.get_children():
			if i.is_hovered():
				i.get_node("Sprite2D").frame = 2
				buy_gear = true
			else:
				i.get_node("Sprite2D").frame = 0
			if i.is_hovered() and Input.is_action_just_pressed("ui_select"):
				match i.code:
					0: if Inventory.armor < 20 and Inventory.cash >= i.price:
						Inventory.cash -= i.price
						Inventory.armor += 1
						emit_signal("picked")
					
					5: if Inventory.cash >= i.price:
						Inventory.cash -= i.price
						Inventory.backpack.append(20)
						var ins = item.instantiate()
						ins.code = 0
						$Inventory/Loadout.add_child(ins)
						Inventory.used_slot += 1
						emit_signal("picked")
		for i in $Buy/Weapon.get_children():
			if i.is_hovered():
				i.get_node("Sprite2D").frame = 3
				buy_gear = false
			else:
				i.get_node("Sprite2D").frame = 1
			if i.is_hovered() and Input.is_action_just_pressed("ui_select") and Inventory.cash >= i.price:
				Inventory.cash -= i.price
				if Inventory.weapon[1] > 0:
					var drop_ins = drop.instantiate()
					drop_ins.global_position = global_position
					drop_ins.code = gun.gun
					drop_ins.apply_impulse(Vector2(randf_range(400,800) * facing, 0).rotated(global_rotation), Vector2())
					get_tree().get_root().add_child(drop_ins)
					replacing_gun(i.gun)
				else:
					replacing_gun(i.gun)
					switch_count += 1
					on_slot_1 = false
				
var shoot = false
var shooting = false
var shooted = false
var reload = false
var mode = false
var reverse_ammo = 0
var recoil = 0
var spread = 0
var max_spread = 0
var current_ammo = 0
var aim_speed = 0
var fire_delay = false
var coiling = false
var reloading = false
var walk = false
var slide = false
var mode_changing = false
var wait = false
var block = false
var action = false
var fire_mode = 0
var pack_opening = false
var scope = 0.0
var foregrip = 0
var muzzle = 0
var magazine = 0
var laser = 0
var stock = 0
var buffer = 0
func weapon():
	if get_child(0).get_class() == "Node2D":
		weapon_1 = get_child(0)
		weapon_1.switching = switching
		weapon_1.gun = int(str(1) + str(int(weapon_1.code / 10)) + str(weapon_1.code % 10) + str(int(weapon_1.current_ammo / 100)) + str(int(int(weapon_1.current_ammo) % 100/10)) + str(int(weapon_1.current_ammo) % 10) + str(weapon_1.scope) + str(weapon_1.foregrip) + str(weapon_1.muzzle) + str(weapon_1.magazine) + str(weapon_1.laser) + str(weapon_1.stock))
		Inventory.weapon[0] = weapon_1.gun
		if get_child(1).get_class() == "Node2D":
			weapon_2 = get_child(1)
			weapon_2.switching = switching
			weapon_2.gun = int(str(1) + str(int(weapon_2.code / 10)) + str(weapon_2.code % 10) + str(int(weapon_2.current_ammo / 100)) + str(int(int(weapon_2.current_ammo) % 100/10)) + str(int(weapon_2.current_ammo) % 10) + str(weapon_2.scope) + str(weapon_2.foregrip) + str(weapon_2.muzzle) + str(weapon_2.magazine) + str(weapon_2.laser) + str(weapon_2.stock))
			Inventory.weapon[1] = weapon_2.gun
			if get_child(2).get_class() == "Node2D":
				get_child(2).hide()
	if slot_1:
		gun = weapon_1
		if weapon_1.get_parent().get_class() == "Node2D":
			if !switching and !pack_opening and !buying and !Key.map:
				weapon_1.current()
			weapon_1.show()
		if $Switch.time_left > 0:
			if $Switch.wait_time > 0.3:
				weapon_1.take = true
				weapon_1.on = false
			else:
				weapon_1.take = false
				weapon_1.on = true
		else:
			weapon_1.take = false
			weapon_1.on = false
			weapon_1.off = false
		if !melee and !throwing and !$Armor.time_left > 0 and !$Heal.time_left > 0:
			$Recoil.position.x = weapon_1.get_node("Recoil").position.x * facing
			$Recoil.position.y = weapon_1.get_node("Recoil").position.y
	else:
		weapon_1.take = false
		weapon_1.on = false
		weapon_1.stop()
		if $Switch.time_left > 0.4:
			weapon_1.off = true
		else:
			weapon_1.off = false
			weapon_1.hide()
	if get_child(1).get_class() == "Node2D":
		if slot_2:
			gun = weapon_2
			if weapon_2.get_parent().get_class() == "Node2D":
				if !switching and !pack_opening and !buying and !Key.map:
					weapon_2.current()
				weapon_2.show()
			if $Switch.time_left > 0:
				if $Switch.wait_time > 0.3:
					weapon_2.take = true
					weapon_2.on = false
				else:
					weapon_2.take = false
					weapon_2.on = true
			else:
				weapon_2.take = false
				weapon_2.on = false
				weapon_2.off = false
			if !melee and !throwing and !$Armor.time_left > 0 and !$Heal.time_left > 0:
				$Recoil.position.x = weapon_2.get_node("Recoil").position.x * facing
				$Recoil.position.y = weapon_2.get_node("Recoil").position.y
		else:
			weapon_2.take = false
			weapon_2.on = false
			weapon_2.stop()
			if $Switch.time_left > 0.4:
				weapon_2.off = true
			else:
				weapon_2.off = false
				weapon_2.hide()
	current_gun = gun.code
	recoil = gun.recoil
	max_spread = gun.max_spread
	current_ammo = gun.current_ammo 
	reverse_ammo = gun.reverse_ammo
	fire_delay = gun.fire_delay
	coiling = gun.coiling
	reloading = gun.reloading
	scope = gun.scope
	aim_speed = gun.aim_speed
	mode_changing = gun.mode_changing
	fire_mode = gun.fire_mode
	get_parent().get_node("Block").target_position.x = gun.get_node("Fire").position.x + 10
	if (echo > 0 and Key.fired or Key.fire) and get_parent().sprint_delay > 0:
		buffer = 10
	buffer = move_toward(buffer,0,Setting.inverse)
	if gun.fire or gun.firing:
		buffer = 0
	gun.fire = (buffer > 0 or echo > 0 and Key.fired or Key.fire) and !get_parent().sprint_delay > 0
	gun.firing = Key.firing and !get_parent().sprint_delay > 0
	gun.reload = Key.reload
	gun.mode = Key.mode
	gun.facing = facing
	gun.walk = walk
	gun.slide = slide
	gun.wait = wait
	gun.block = block
	gun.action = action
	gun.z_index = facing
	gun.global_rotation = $Rotation/Recoil.global_rotation + (tolerance_rotate + deg_to_rad(shake)) * unstable
	if $Switch.time_left > $Switch.wait_time - 0.1 or $Lethal.time_left < 0.1 and $Lethal.time_left > 0 or $Tactical.time_left < 0.1 and $Tactical.time_left > 0 or $Sentry.time_left < 0.1 and $Sentry.time_left > 0 or $Chaser.time_left < 0.1 and $Chaser.time_left > 0 or $Armor.time_left < 0.1 and $Armor.time_left > 0 or $Heal.time_left < 0.1 and $Heal.time_left > 0:
		$Rotation/Recoil/Body/ArmR.global_position.x = lerpf($Rotation/Recoil/Body/ArmR.global_position.x,gun.get_node("Body/HandR").global_position.x,0.5 * Setting.inverse)
		$Rotation/Recoil/Body/ArmR.global_position.y = lerpf($Rotation/Recoil/Body/ArmR.global_position.y,gun.get_node("Body/HandR").global_position.y,0.5 * Setting.inverse)
		$Rotation/Recoil/Body/ArmR/HandR.global_position = gun.get_node("Body/HandR/HandR2").global_position
		if !throwing or $Armor.time_left > 0 or $Heal.time_left > 0 or hack_hold > 0 and hack_hold < 30:
			$Rotation/Recoil/Body/ArmL.global_position.x = lerpf($Rotation/Recoil/Body/ArmL.global_position.x,gun.get_node("Body/HandL").global_position.x,0.5 * Setting.inverse)
			$Rotation/Recoil/Body/ArmL.global_position.y = lerpf($Rotation/Recoil/Body/ArmL.global_position.y,gun.get_node("Body/HandL").global_position.y,0.5 * Setting.inverse)
			$Rotation/Recoil/Body/ArmL/HandL.global_position = gun.get_node("Body/HandL/HandL2").global_position
	else:
		if !lethal_hold and !$Lethal.time_left > 0 and !$Sentry.time_left > 0:
			$Rotation/Recoil/Body/ArmR.global_position = gun.get_node("Body/HandR").global_position
			$Rotation/Recoil/Body/ArmR/HandR.global_position = gun.get_node("Body/HandR/HandR2").global_position
		if !throwing and !$Armor.time_left > 0 and !$Heal.time_left > 0 and !(hacking or hack_hold > 0 or Key.map):
			$Rotation/Recoil/Body/ArmL.global_position = gun.get_node("Body/HandL").global_position
			$Rotation/Recoil/Body/ArmL/HandL.global_position = gun.get_node("Body/HandL/HandL2").global_position
			

@onready var frag = preload("res://Screen/Asset/Weapon/Lethal/Frag.tscn")
@onready var fire = preload("res://Screen/Asset/Weapon/Lethal/Fire.tscn")
@onready var knife = preload("res://Screen/Asset/Weapon/Lethal/Knife.tscn")
@onready var mine = preload("res://Screen/Asset/Weapon/Lethal/Mine.tscn")
@onready var smoke = preload("res://Screen/Asset/Weapon/Tactical/Smoke.tscn")
@onready var flash = preload("res://Screen/Asset/Weapon/Tactical/Flash.tscn")
@onready var decoy = preload("res://Screen/Asset/Weapon/Tactical/Decoy.tscn")
@onready var latch = preload("res://Screen/Asset/Weapon/Lethal/Level.tscn")
@onready var ring = preload("res://Screen/Asset/Weapon/Lethal/Ring.tscn")
var lethal = 0
var tactical = 4
var charging_lethal = 0
var charging_tactical = 0
var hold = 0.0
var strengt = 0
var throwing = false
var lethal_hold = false
var tactical_hold = false
func throw():
	if !break_action and abs(get_parent().velocity.x) < 1200 and !switching and !mode_changing and !reloading and !fire_delay and !melee and !get_parent().armor_using and !get_parent().healing:
		if Key.lethal_hold:
			hold = 0
			if !tactical_hold and Inventory.lethal.size() > 0:
				lethal_hold = true
				throwing = true
			else:
				tactical_hold = false
				throwing = false
		if Key.tactical_hold and Inventory.tactical.size() > 0 and !Inventory.tactical[0] == 6:
			hold = 0
			if !lethal_hold and Inventory.tactical.size() > 0:
				tactical_hold = true
				throwing = true
			else:
				lethal_hold = false
				throwing = false
	else:
		break_action = false
		throwing = $Lethal.time_left > 0.2 or $Tactical.time_left > 0.2 or $Sentry.time_left > 0 or $Chaser.time_left > 0
		lethal_hold = false
		tactical_hold = false
	if lethal_hold:
		if hold < 60 and !$Lethal.time_left > 0.2:
			hold += 1 * Setting.inverse
		$Rotation/Recoil/Body/ArmR.global_position.x = global_position.x + $ArmR.position.x * facing
		$Rotation/Recoil/Body/ArmR.global_position.y = global_position.y + $ArmR.position.y 
		$Rotation/Recoil/Body/ArmR/HandR.global_position.x = global_position.x + $ArmR/HandR.position.x * facing
		$Rotation/Recoil/Body/ArmR/HandR.global_position.y = global_position.y + $ArmR/HandR.position.y 
	if tactical_hold:
		if hold < 60 and !$Tactical.time_left > 0.2:
			hold += 1 * Setting.inverse
	if throwing or $Armor.time_left > 0.1 or $Heal.time_left > 0.1 or hacking or hack_hold > 30 or Key.map:
		$Rotation/Recoil/Body/ArmL.global_position.x = global_position.x + $ArmL.position.x * facing
		$Rotation/Recoil/Body/ArmL.global_position.y = global_position.y + $ArmL.position.y + $Joint/RigidBody2D.position.y/20
		$Rotation/Recoil/Body/ArmL/HandL.position.x = $ArmL/HandL.position.x
		$Rotation/Recoil/Body/ArmL/HandL.position.y = $ArmL/HandL.position.y * facing
	if hack_hold > 0 and hack_hold < 30:
		$Rotation/Recoil/Body/ArmR.global_position.x = lerpf($Rotation/Recoil/Body/ArmR.global_position.x,global_position.x + $ArmR.position.x * facing,0.5 * Setting.inverse)
		$Rotation/Recoil/Body/ArmR.global_position.y = lerpf($Rotation/Recoil/Body/ArmR.global_position.y,global_position.y + $ArmR.position.y,0.5 * Setting.inverse) 
		$Rotation/Recoil/Body/ArmR/HandR.position.x = $ArmR/HandR.position.x
		$Rotation/Recoil/Body/ArmR/HandR.position.y = $ArmR/HandR.position.y * facing
	if lethal_hold:
		$Anim.play("Hold_Lethal")
	if $Lethal.time_left > 0.1:
		throwing = true
		$Rotation/Recoil/Body/ArmR.global_position.x = global_position.x + $ArmR.position.x * facing
		$Rotation/Recoil/Body/ArmR.global_position.y = global_position.y + $ArmR.position.y 
		$Rotation/Recoil/Body/ArmR/HandR.position.x = $ArmR/HandR.position.x
		$Rotation/Recoil/Body/ArmR/HandR.position.y = $ArmR/HandR.position.y * facing
		$Anim.play("Throw_Lethal")
	if $Sentry.time_left > 0.1:
		throwing = true
		$Rotation/Recoil/Body/ArmR.global_position.x = global_position.x + $ArmR.position.x * facing
		$Rotation/Recoil/Body/ArmR.global_position.y = global_position.y + $ArmR.position.y 
		$Rotation/Recoil/Body/ArmR/HandR.position.x = $ArmR/HandR.position.x
		$Rotation/Recoil/Body/ArmR/HandR.position.y = $ArmR/HandR.position.y * facing
		$Anim.play("Throw_Sentry")
	if tactical_hold:
		$Anim.play("Hold_Tac")
	if $Tactical.time_left > 0.1 or $Chaser.time_left > 0.1:
		throwing = true
		$Anim.play("Throw_Tac")
	if $Tactical.time_left > 0 and $Tactical.time_left < 0.1 or $Chaser.time_left > 0 and $Chaser.time_left < 0.1:
		throwing = false
	if $Ignitor.time_left > 0:
		$Anim.play("Blast")
	if hacking or hack_hold > 0 or Key.map:
		if walk:
			$Anim.play("HackWalk")
		else:
			$Anim.play("Hack")
	strengt = 2000 + hold * 50
	if Inventory.lethal.size() > 0:
		lethal = Inventory.lethal[0]
	if Inventory.tactical.size() > 0:
		tactical = Inventory.tactical[0]
	if Key.lethal and Inventory.lethal.size() > 0 and lethal_hold:
		var ins
		match Inventory.lethal[0]:
			0: ins = frag.instantiate()
			1: ins = fire.instantiate()
			2: ins = knife.instantiate()
			3: ins = mine.instantiate()
		match Inventory.lethal[0]:
			2: ins.apply_impulse(Vector2(strengt + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.05 * facing), Vector2())
			3: ins.apply_impulse(Vector2(strengt / 2 + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.05 * facing), Vector2())
			_:
				ins.apply_impulse(Vector2(strengt + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.2 * facing), Vector2())
				var ins1 = ring.instantiate()
				ins1.global_position = global_position
				ins1.apply_impulse(Vector2(-1000, -500).rotated($Rotation/Recoil.global_rotation), Vector2())
				get_tree().get_root().add_child(ins1)
		ins.global_position = global_position
		ins.angular_velocity = 40 * facing
		ins.id = get_parent().id
		get_tree().get_root().add_child(ins)
		Inventory.lethal.remove_at(0)
		$Lethal.start(0.3)
		hold = 0
		lethal_hold = false
	if Key.tactical and Inventory.tactical.size() > 0 and tactical_hold:
		var ins
		match Inventory.tactical[0]:
			4: ins = smoke.instantiate()
			5: ins = flash.instantiate()
			7: ins = decoy.instantiate()
		ins.global_position = global_position
		ins.angular_velocity = 20 * facing
		ins.apply_impulse(Vector2(strengt * 0.75 + get_parent().velocity.x * facing,get_parent().velocity.y * facing).rotated($Rotation/Recoil.global_rotation - 0.2 * facing), Vector2())
		get_tree().get_root().add_child(ins)
		Inventory.tactical.remove_at(0)
		$Tactical.start(0.3)
		hold = 0
		tactical_hold = false
	if recharge > 0:
		if Inventory.lethal.size() < 2:
			charging_lethal += (0.001 + 0.00025 * get_parent().overload) * Setting.inverse
		if Inventory.tactical.size() < 2:
			charging_tactical += (0.001 + 0.00025 * get_parent().overload) * Setting.inverse
	else:
		charging_lethal = 0
		charging_tactical = 0
	if charging_lethal > 1:
		Inventory.lethal.append(lethal)
		charging_lethal = 0
	if charging_tactical > 1:
		Inventory.tactical.append(tactical)
		charging_tactical = 0

var hack_hold = 0
var hacking = false
var level = 0
signal hack_fail
var hack_try = 0
var circle = load("res://Screen/Asset/Function/Hack/Circle.tscn")
func hack():
	$Hack.global_position = $Rotation/Recoil/Body/ArmL.global_position + Vector2(0,-64)
	if $PickRange.is_colliding() and $PickRange.get_collider(0) != null and $PickRange.get_collider(0).is_in_group("hack"):
		if Key.using and !hacking:
			hack_hold += 1 * Setting.inverse
		else:
			if hacking:
				hack_hold = 30
				$Hack/RayCast2D.target_position.y = 25 * (5 - level)
				$Hack/RayCast2D/Line2D.points[1].y = $Hack/RayCast2D.target_position.y
				if Key.use or Input.is_action_just_pressed("ui_select"):
					if $Hack/RayCast2D.is_colliding():
						$Hack/RayCast2D.get_collider().get_parent().queue_free()
						level -= 1
					else:
						emit_signal("hack_fail")
						get_parent().hp -= 50
						hack_try -= 1
			else:
				if hack_hold > 0:
					hack_hold -= Setting.inverse
		if hack_hold == 60:
			hacking = true
			level = $PickRange.get_collider(0).get_parent().hack_level
			hack_try = 3
			for i in level:
				var ins = circle.instantiate()
				ins.level = 5 - i
				ins.rotation = randf_range(0,6)
				$Hack.add_child(ins)
				
	else:
		for i in $Hack.get_children():
			if i.get_index() > 0:
				i.queue_free()
		if hack_hold > 0:
			hack_hold -= Setting.inverse
		hacking = false
		
func replacing_gun(code):
	var instance
	match int((code % 100000000000)/10000000000):
		0: match int((code % 10000000000)/1000000000):
			0: instance = PistolA.instantiate()
			1: instance = PistolB.instantiate()
			2: instance = PistolC.instantiate()
			3: instance = PistolD.instantiate()
			4: instance = SMGA.instantiate()
			5: instance = SMGB.instantiate()
			6: instance = SMGC.instantiate()
		1: match int((code % 10000000000)/1000000000):
			0: instance = RifleA.instantiate()
			1: instance = RifleB.instantiate()
			2: instance = RifleC.instantiate()
			3: instance = DMR.instantiate()
			4: instance = LMG.instantiate()
		2: match int((code % 10000000000)/1000000000):
			0: instance = ShotgunA.instantiate()
			1: instance = ShotgunB.instantiate()
			2: instance = ShotgunC.instantiate()
		3: match int((code % 10000000000)/1000000000):
			0: instance = SniperA.instantiate()
			1: instance = SniperB.instantiate()
		4: instance = LauncherA.instantiate()
	instance.position = $Idle.position
	instance.global_rotation_degrees = $Rotation/Recoil.global_rotation_degrees
	if slot_1:
		instance.gun = code
		if get_child(0).get_class() == "Node2D":
			if get_child(1).get_class() == "Node2D":
				weapon_1.queue_free()
				add_child(instance)
				move_child(instance,0)
				Inventory.weapon[0] = code
				$Switch.start(0.5)
			else:
				add_child(instance)
				move_child(instance,1)
				Inventory.weapon[1] = code
				$Switch.start(0.5)
		else:
			add_child(instance)
			move_child(instance,0)
			Inventory.weapon[0] = code
			$Switch.start(0.5)
	if slot_2:
		instance.gun = code
		weapon_2.queue_free()
		add_child(instance)
		move_child(instance,1)
		Inventory.weapon[1] = code
		$Switch.start(0.5)
			
func perk_load(code):
	for i in $Inventory/Perk/PerkBox.get_children():
		i.queue_free()
	Inventory.perk_slot = 0
	loadout = 0
	get_parent().conscious = 0
	get_parent().recovery = 0
	get_parent().overclock = 0
	get_parent().resilience = 0
	echo = 0
	get_parent().succinct = 0
	spotter = 0
	get_parent().sonic = 0
	payout = 0
	get_parent().overload = 0
	get_parent().berserk = 0
	get_parent().phantom = 0
	get_parent().alert = 0
	recharge = 0
	get_parent().shifter = 0
	for i in code:
		match i % 10:
			9: if Inventory.perk_slot < 13:
				var ins = Perk4.instantiate()
				match int((i % 1000)/100):
					1: if get_parent().phantom < 1:
						get_parent().phantom += 1
						ins.code = 61
						$Inventory/Perk/PerkBox.add_child(ins)
						Inventory.perk_slot += 4
					2: if get_parent().alert < 1:
						get_parent().alert += 1
						ins.code = 62
						$Inventory/Perk/PerkBox.add_child(ins)
						Inventory.perk_slot += 4
					3: if recharge < 1:
						recharge += 1
						ins.code = 63
						$Inventory/Perk/PerkBox.add_child(ins)
						Inventory.perk_slot += 4
					4: if get_parent().shifter < 1:
						get_parent().shifter += 1
						ins.code = 64
						$Inventory/Perk/PerkBox.add_child(ins)
						Inventory.perk_slot += 4
			_: match int((i % 100)/10):
				5: if Inventory.perk_slot < 15:
					var ins = Perk2.instantiate()
					match i % 10:
						1: if get_parent().resilience < 1:
							get_parent().resilience += 1
							ins.code = 51
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						2: if echo < 1:
							echo += 1
							ins.code = 52
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						3: if get_parent().succinct < 1:
							get_parent().succinct += 1
							ins.code = 53
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						4: if spotter < 1:
							spotter += 1
							ins.code = 54
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						5: if get_parent().sonic < 2:
							get_parent().sonic += 1
							ins.code = 55
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						6: if payout < 2:
							payout += 1
							ins.code = 56
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						7: if get_parent().overload < 4:
							get_parent().overload += 1
							ins.code = 57
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
						8: if get_parent().berserk < 4:
							get_parent().berserk += 1
							ins.code = 58
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 2
				_: if Inventory.perk_slot < 16:
					var ins = Perk1.instantiate()
					match i:
						1: if loadout < 6:
							loadout += 1
							ins.code = 1
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 1
						2: if get_parent().conscious < 2:
							get_parent().conscious += 1
							ins.code = 2
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 1
						3: if get_parent().recovery < 4:
							get_parent().recovery += 1
							ins.code = 3
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 1
						4: if get_parent().overclock < 4:
							get_parent().overclock += 1
							ins.code = 4
							$Inventory/Perk/PerkBox.add_child(ins)
							Inventory.perk_slot += 1
func refill():
	for i in 2 - Inventory.lethal.size():
		Inventory.lethal.append(lethal)
	for i in 2 - Inventory.tactical.size():
		Inventory.tactical.append(tactical)
	Inventory.ammo[1] = move_toward(Inventory.ammo[1],600,120)
	Inventory.ammo[0] = move_toward(Inventory.ammo[0],600,120)
	Inventory.ammo[2] = move_toward(Inventory.ammo[2],300,60)
	Inventory.ammo[3] = move_toward(Inventory.ammo[3],300,60)
	Inventory.ammo[4] = move_toward(Inventory.ammo[4],100,20)
	emit_signal("picked")

var kill_count = 0
var streak = 0
var streak_count = 0
func killstreak():
	if streak_count > 0:
		streak_count -= Setting.inverse
	else:
		streak = 0

@onready var missile = preload("res://Screen/Asset/Weapon/Streak/Missile.tscn")
func airstrike():
	if Key.sentry:
		$Camera2D.enabled = false
		get_parent().can_move = false
		get_parent().fight = false
		var ins = missile.instantiate()
		ins.get_node("Camera2D").make_current()
		ins.position = Vector2(global_position.x + randi_range(-2000,2000),-10000)
		ins.rotation_degrees = 90
		get_tree().get_root().add_child(ins)

func hit(dmg):
	$Hit.play()
	var tween = create_tween()
	$CrossHair/Hit.rotation_degrees = randf_range(-5,5)
	tween.tween_property($CrossHair/Hit,"modulate",Color(1,1,1,1), 0)
	tween.tween_property($CrossHair/Hit,"scale",Vector2(1.2,1.2), 0)
	tween.chain().tween_property($CrossHair/Hit,"modulate",Color(1,1,1,0), 0.2)
	tween.tween_property($CrossHair/Hit,"scale",Vector2(1,1), 0.2)
	tween.play()
	if Inventory.medic and get_parent().corruptor:
		get_parent().hp += (dmg/5 + dmg/20 * get_parent().recovery) * Setting.inverse
		get_parent().ignite_time += (dmg + dmg/4 * get_parent().overload) * Setting.inverse
		get_parent().crash_cool += (dmg + dmg/4 * get_parent().overload) * Setting.inverse
		get_parent().break_cool += (dmg + dmg/4 * get_parent().overload) * Setting.inverse
var slow = 0
func slash(dmg):
	$Hit.play()
	$Camera2D.shake(10,5)
	slow = 0.5
	if Inventory.medic and get_parent().corruptor:
		get_parent().hp += (dmg/5 + dmg/20 * get_parent().recovery) * Setting.inverse
		get_parent().ignite_time += (dmg + dmg/4 * get_parent().overload) * Setting.inverse
		get_parent().crash_cool += (dmg + dmg/4 * get_parent().overload) * Setting.inverse
		get_parent().break_cool += (dmg + dmg/4 * get_parent().overload) * Setting.inverse
func kill(type):
	if get_parent().resilience > 0:
		if get_parent().corruptor:
			get_parent().hp += (10 + 2.5 * get_parent().recovery) * Setting.inverse
		else:
			get_parent().heal_cool = 0
	$CrossHair/Kill.show()
	$CrossHair/Kill/Hit.position = Vector2(47,-47)
	$CrossHair/Kill/Hit2.position = Vector2(47,47)
	$CrossHair/Kill/Hit3.position = Vector2(-47,47)
	$CrossHair/Kill/Hit4.position = Vector2(-47,-47)
	var tween = create_tween().set_parallel(true)
	tween.tween_property($CrossHair/Kill/Hit, "position", Vector2(17,-17), 0.1)
	tween.tween_property($CrossHair/Kill/Hit2, "position", Vector2(17,17), 0.1)
	tween.tween_property($CrossHair/Kill/Hit3, "position", Vector2(-17,17), 0.1)
	tween.tween_property($CrossHair/Kill/Hit4, "position", Vector2(-17,-17), 0.1)
	tween.chain().tween_property($CrossHair/Kill/Hit, "position", Vector2(17,-17), 0.2)
	tween.play()
	tween.chain().tween_callback($CrossHair/Kill.hide)
	match type:
		0: 
			Inventory.cash += 50
			$Kill6.play()
		
		_:
			kill_count += 1
			match streak:
				0:
					$Kill.play()
					streak_count = 60
				1:
					$Kill2.play()
					streak_count = 80
				2:
					$Kill3.play()
					streak_count = 100
				3:
					$Kill4.play()
					streak_count = 120
				_:
					$Kill5.play()
					streak_count = 160
			streak += 1
func shaked():
	$Camera2D.shake(10,5)

