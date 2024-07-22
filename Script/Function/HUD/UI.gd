extends CanvasLayer

var hp = 0.0
var hp_shake = false
var current_gun = 0.0
var fire_mode = 0

func _ready():
	lethal_out = lethal_left
	tactical_out = tactical_left
	$Menu/Menu/Quit/Quit.pressed.connect(get_tree().quit)
	$Menu/Back.mouse_entered.connect(HUDSound.select)
func _physics_process(_delta):
	ammo()
	grenade()
	armor()
	menu()
	$Weapon/Gun.frame = current_gun
	$Stat/HP.value = hp
	$Stat/Label.text = str("$",Inventory.cash)
	$Stat/HP/SmoothHP.value = lerpf($Stat/HP/SmoothHP.value,hp,0.05 * 60.0/Engine.physics_ticks_per_second)
	$Hurt.modulate = Color(1,1,1,1-(hp/50))
	$Weapon/Gun/FireMode.frame = int(fire_mode/10)
	$Weapon/Gun/FireMode2.frame = fire_mode%10
	if int(fire_mode/10) == fire_mode%10:
		$Weapon/Gun/FireMode2.hide()
	else:
		$Weapon/Gun/FireMode2.show()
	if hp_shake:
		var tween = create_tween().set_loops(2)
		tween.tween_property($Stat/HP,"scale", Vector2(1.1,1.1), 0.05)
		tween.chain().tween_property($Stat/HP,"scale", Vector2(1,1), 0.05)
		tween.play()
		hp_shake = false

var pre_armor = 0
var armor_plate = 0
var infantry_armor = 0
var infantry_cool = 0
var current_plate = 0
var armor_use = false
var succinct = 0
func armor():
	$Stat/Armor1.value = armor_plate
	$Stat/Armor2.value = armor_plate - 50
	$Stat/Armor3.value = armor_plate - 100
	$Stat/Armor4.value = infantry_armor
	$Stat/Armor5.value = armor_plate
	$Stat/Armor6.value = armor_plate - 75
	$Stat/Armor7.value = infantry_armor
	$Stat/Armor/TextureProgressBar.value = 300 - infantry_cool
	$Stat/Armor/Label.text = str(Inventory.armor)
	if succinct > 0:
		$Stat/Armor1.hide()
		$Stat/Armor2.hide()
		$Stat/Armor3.hide()
		$Stat/Armor4.hide()
		$Stat/Armor5.show()
		$Stat/Armor6.show()
		if infantry_armor > 0:
			$Stat/Armor7.show()
			if armor_plate > 75:
				$Stat/Armor7.position = $Stat/Armor6.position
				$Stat/Armor7.scale = $Stat/Armor6.scale
				$Stat/Armor7.fill_mode = $Stat/Armor6.fill_mode
			else:
				$Stat/Armor7.position = $Stat/Armor5.position
				$Stat/Armor7.scale = $Stat/Armor5.scale
				$Stat/Armor7.fill_mode = $Stat/Armor5.fill_mode
		else:
			$Stat/Armor7.hide()
	else:
		$Stat/Armor1.show()
		$Stat/Armor2.show()
		$Stat/Armor3.show()
		$Stat/Armor5.hide()
		$Stat/Armor6.hide()
		$Stat/Armor7.hide()
		if infantry_armor > 0:
			$Stat/Armor4.show()
			if armor_plate > 50:
				if armor_plate > 100:
					$Stat/Armor4.position = $Stat/Armor3.position
				else:
					$Stat/Armor4.position = $Stat/Armor2.position
			else:
				$Stat/Armor4.position = $Stat/Armor1.position
		else:
			$Stat/Armor4.hide()
	if armor_plate != pre_armor:
		if armor_plate >= 50 and armor_plate < pre_armor or armor_plate > 50 and armor_plate > pre_armor:
			if armor_plate >= 100 and armor_plate < pre_armor or armor_plate > 100 and armor_plate > pre_armor:
				var tween = create_tween()
				tween.tween_property($Stat/Armor3,"scale", Vector2(1.1,1.1), 0.1)
				tween.chain().tween_property($Stat/Armor3,"scale", Vector2(1,1), 0.1)
				tween.play()
			else:
				var tween = create_tween()
				tween.tween_property($Stat/Armor2,"scale", Vector2(1.1,1.1), 0.1)
				tween.chain().tween_property($Stat/Armor2,"scale", Vector2(1,1), 0.1)
				tween.play()
		else:
			var tween = create_tween()
			tween.tween_property($Stat/Armor1,"scale", Vector2(1.1,1.1), 0.1)
			tween.chain().tween_property($Stat/Armor1,"scale", Vector2(1,1), 0.1)
			tween.play()
		if armor_plate >= 75 and armor_plate < pre_armor or armor_plate > 75 and armor_plate > pre_armor:
			var tween = create_tween()
			tween.tween_property($Stat/Armor6,"scale", Vector2(-1.1,1.1), 0.1)
			tween.chain().tween_property($Stat/Armor6,"scale", Vector2(-1,1), 0.1)
			tween.play()
		else:
			var tween = create_tween()
			tween.tween_property($Stat/Armor5,"scale", Vector2(1.1,1.1), 0.1)
			tween.chain().tween_property($Stat/Armor5,"scale", Vector2(1,1), 0.1)
			tween.play()
		var tween = create_tween()
		tween.tween_property($Stat/Armor4,"scale", Vector2(1.1,1.1), 0.1)
		tween.chain().tween_property($Stat/Armor4,"scale", Vector2(1,1), 0.1)
		tween.play()
		var tween2 = create_tween()
		tween2.tween_property($Stat/Armor7,"scale", Vector2(-1.1,1.1), 0.1)
		tween2.chain().tween_property($Stat/Armor7,"scale", Vector2(-1,1), 0.1)
		tween2.play()
		pre_armor = armor_plate
	if Inventory.armor > current_plate:
		var tween = create_tween().set_loops(2)
		tween.tween_property($Stat/Armor,"self_modulate", Color(0.44,0.44,0.44,0), 0.1)
		tween.chain().tween_property($Stat/Armor,"self_modulate", Color(0.44,0.44,0.44,1), 0.1)
		tween.play()
		var tween2 = create_tween().set_loops(2)
		tween2.tween_property($Stat/Armor/Armor,"modulate", Color(0.7,0.7,0.7,0), 0.1)
		tween2.chain().tween_property($Stat/Armor/Armor,"modulate", Color(0.7,0.7,0.7,1), 0.1)
		tween2.play()
		current_plate = Inventory.armor
	if armor_use:
		var tween = create_tween().set_loops(2)
		tween.tween_property($Stat/Armor/Armor,"modulate", Color(1,1,1,1), 0.1)
		tween.chain().tween_property($Stat/Armor/Armor,"modulate", Color(0.7,0.7,0.7,1), 0.1)
		tween.play()
		armor_use = false
var current_ammo = 0
var pre_current = 0
var reverse_ammo = 0
var pre_reverse = 0
var fire_delay = false
var fire = false
func ammo():
	$Weapon/Ammo/CurrentAmmo.text = str(current_ammo)
	$Weapon/Ammo/ReverseAmmo.text = str(reverse_ammo)
	$Weapon/Ammo/AmmoBar.value = move_toward($Weapon/Ammo/AmmoBar.value,current_ammo,2 * 60.0/Engine.physics_ticks_per_second)
	$Weapon/Ammo/Type.frame = int(current_gun/10)
	if pre_current != current_ammo:
		var tween = create_tween().set_ease(Tween.EASE_OUT)
		tween.tween_property($Weapon/Ammo/CurrentAmmo,"scale", Vector2(1.2,1.2), 0.01)
		tween.chain().tween_property($Weapon/Ammo/CurrentAmmo,"scale", Vector2(1,1), 0.05)
		tween.play()
		pre_current = current_ammo
	if fire_delay:
		$Weapon/Ammo/Ani.play("Fire")
	else:
		$Weapon/Ammo/Ani.play("Stop")
	if pre_reverse != reverse_ammo:
		var tween = create_tween().set_ease(Tween.EASE_OUT)
		tween.tween_property($Weapon/Ammo/ReverseAmmo,"scale", Vector2(1.05,1.05), 0.01)
		tween.chain().tween_property($Weapon/Ammo/ReverseAmmo,"scale", Vector2(1,1), 0.05)
		tween.play()
		pre_reverse = reverse_ammo
		
var default_lethal = 0
var default_tactical = 0
var lethal_type = 0
var lethal_left = 0
var tactical_type = 0
var tactical_left = 0
var current_lethal = 0
var current_tactical = 0
var lethal_out = 0
var tactical_out = 0
func grenade():
	if lethal_out > int(lethal_left):
		var tween = create_tween().set_loops(2)
		tween.tween_property($Weapon/Lethal/Nade,"modulate", Color(1,1,1,1), 0.1)
		tween.chain().tween_property($Weapon/Lethal/Nade,"modulate", Color(0.7,0.7,0.7,1), 0.1)
		tween.play()
		lethal_out = int(lethal_left)
	elif lethal_out < int(lethal_left):
		var tween = create_tween().set_loops(2)
		tween.tween_property($Weapon/Lethal/Take,"scale", Vector2(0,1), 0)
		tween.chain().tween_property($Weapon/Lethal/Take,"modulate", Color(1,1,1,1), 0)
		tween.chain().tween_property($Weapon/Lethal/Take,"scale", Vector2(1,1), 0.1)
		tween.chain().tween_property($Weapon/Lethal/Take,"modulate", Color(1,1,1,0), 0.1)
		tween.play()
		lethal_out = int(lethal_left)
	else:
		$Weapon/Lethal/Nade.modulate = Color(0.7,0.7,0.7,1)
	if tactical_out > int(tactical_left):
		var tween = create_tween().set_loops(2)
		tween.tween_property($Weapon/Tactical/Nade,"modulate", Color(1,1,1,1), 0.1)
		tween.chain().tween_property($Weapon/Tactical/Nade,"modulate", Color(0.7,0.7,0.7,1), 0.1)
		tween.play()
		tactical_out = int(tactical_left)
	elif tactical_out < int(tactical_left):
		var tween = create_tween().set_loops(2)
		tween.tween_property($Weapon/Tactical/Take,"scale", Vector2(0,1), 0)
		tween.chain().tween_property($Weapon/Tactical/Take,"modulate", Color(1,1,1,1), 0)
		tween.chain().tween_property($Weapon/Tactical/Take,"scale", Vector2(1,1), 0.2)
		tween.chain().tween_property($Weapon/Tactical/Take,"modulate", Color(1,1,1,0), 0.1)
		tween.play()
		tactical_out = int(tactical_left)
	else:
		$Weapon/Tactical/Nade.modulate = Color(0.7,0.7,0.7,1)
	if current_lethal != lethal_type:
		var tween = create_tween().set_loops(2)
		tween.tween_property($Weapon/Lethal,"self_modulate", Color(0.44,0.44,0.44,0), 0.2)
		tween.chain().tween_property($Weapon/Lethal,"self_modulate", Color(0.44,0.44,0.44,1), 0.1)
		tween.play()
		var tween2 = create_tween().set_loops(2)
		tween2.tween_property($Weapon/Lethal/Nade,"self_modulate", Color(1,1,1,0), 0.1)
		tween2.chain().tween_property($Weapon/Lethal/Nade,"self_modulate", Color(1,1,1,1), 0.1)
		tween.play()
		current_lethal = lethal_type
	if current_tactical != tactical_type:
		var tween = create_tween().set_loops(2)
		tween.tween_property($Weapon/Tactical,"self_modulate", Color(0.44,0.44,0.44,0), 0.1)
		tween.chain().tween_property($Weapon/Tactical,"self_modulate", Color(0.44,0.44,0.44,1), 0.1)
		tween.play()
		var tween2 = create_tween().set_loops(2)
		tween2.tween_property($Weapon/Tactical/Nade,"self_modulate", Color(1,1,1,0), 0.1)
		tween2.chain().tween_property($Weapon/Tactical/Nade,"self_modulate", Color(1,1,1,1), 0.1)
		tween.play()
		current_tactical = tactical_type
	$Weapon/Lethal.frame = lethal_type
	$Weapon/Lethal/Nade.frame = lethal_type
	$Weapon/Lethal/Bar.value = lethal_left
	$Weapon/Tactical.frame = tactical_type
	$Weapon/Tactical/Nade.frame = tactical_type
	$Weapon/Tactical/Bar.value = tactical_left

var opening_menu = false
var exit = 0
var pause_delay = 0
var delay = 0
var state = 0
func menu():
	if Key.escape or $Menu/Back.is_hovered() and Input.is_action_just_released("ui_select") or get_tree().paused and Input.is_action_just_released("ui_back"):
		if exit < 100:
			if !get_tree().paused:
				exit += 50
			if exit > 50:
				$Menu/Menu/Quit.button_pressed = true
		else:
			get_tree().quit()
		if !get_tree().paused:
			await get_tree().process_frame
			get_tree().paused = true
			$Menu/Menu/Setting.grab_focus()
		else:
			if !($Menu/Menu/Quit.button_pressed and exit < 20) and !$Menu/Menu/Setting.button_pressed:
				get_tree().paused = false
	opening_menu = get_tree().paused
	$Menu.opening_menu = opening_menu
	exit = move_toward(exit,0,1  * 60.0/Engine.physics_ticks_per_second)
	$Stat.visible = !opening_menu and !$Menu/Menu/Hide.button_pressed
	$Weapon.visible = !opening_menu and !$Menu/Menu/Hide.button_pressed
	$Skill.visible = !opening_menu and !$Menu/Menu/Hide.button_pressed
	$Menu/Paused.visible = $Menu/Menu.visible
	$Menu/Glitch.size = $Menu/Color.size
	if delay > 0:
		delay -= 1
	else:
		delay = randi_range(10,30)
		$Menu/Glitch.material.set_shader_parameter("glitch_x",[-0.1,0,0,0,0,0.1].pick_random())
		$Menu/Glitch.material.set_shader_parameter("glitch_y",[-0.05,0,0,0,0,0.05].pick_random())
	if opening_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Menu/Grid.size.y = move_toward($Menu/Grid.size.y,$Menu.size.y + 8,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Grid2.size.y = move_toward($Menu/Grid2.size.y,$Menu.size.y + 8,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Color.size.y = move_toward($Menu/Color.size.y,$Menu.size.y,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Grid.position.y = move_toward($Menu/Grid.position.y,-8,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Grid2.position.y = move_toward($Menu/Grid2.position.y,-8,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Color.position.y = move_toward($Menu/Color.position.y,-8,64 * 60.0/Engine.physics_ticks_per_second)
		if $Menu/Menu/Quit.button_pressed:
			$Menu/Menu/Quit/Label.text = "back"
			$Menu/Menu/Quit/Quit.modulate.a = lerpf($Menu/Menu/Quit/Quit.modulate.a,1.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Menu/Quit/Label2.modulate.a = lerpf($Menu/Menu/Quit/Label2.modulate.a,1.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Menu/Quit/Quit.position.x = lerpf($Menu/Menu/Quit/Quit.position.x,128,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Menu/Quit/Label2.position.y = lerpf($Menu/Menu/Quit/Label2.position.y,-34,0.5 * 60.0/Engine.physics_ticks_per_second)
		else:
			$Menu/Menu/Quit/Label.text = "exit"
			$Menu/Menu/Quit/Quit.modulate.a = lerpf($Menu/Menu/Quit/Quit.modulate.a,0.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Menu/Quit/Label2.modulate.a = lerpf($Menu/Menu/Quit/Label2.modulate.a,0.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Menu/Quit/Quit.position.x = lerpf($Menu/Menu/Quit/Quit.position.x,0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Menu/Quit/Label2.position.y = lerpf($Menu/Menu/Quit/Label2.position.y,0,0.5 * 60.0/Engine.physics_ticks_per_second)
	else:
		$Menu/Grid.size.y = move_toward($Menu/Grid.size.y,0,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Grid2.size.y = move_toward($Menu/Grid2.size.y,0,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Color.size.y = move_toward($Menu/Color.size.y,0,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Grid.position.y = move_toward($Menu/Grid.position.y,$Menu.size.y,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Grid2.position.y = move_toward($Menu/Grid2.position.y,-8,64 * 60.0/Engine.physics_ticks_per_second)
		$Menu/Color.position.y = move_toward($Menu/Color.position.y,$Menu.size.y,64 * 60.0/Engine.physics_ticks_per_second)
