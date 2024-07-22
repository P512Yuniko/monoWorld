extends Control

func _ready():
	import_setting()
	for i in get_all_button($Setting):
		if i.get_class() == "TextureButton" and i.get_parent().get_class() == "CheckButton":
			i.get_parent().focus_entered.connect(i.grab_focus)
			i.get_parent().focus_exited.connect(i.release_focus)
			i.pressed.connect(focus_press.bind(i.get_parent()))
		if i.get_class() == "OptionButton" and i.get_parent().get_class() == "TextureButton":
			i.get_parent().focus_entered.connect(i.grab_focus)
			i.get_parent().focus_exited.connect(i.release_focus)
			i.pressed.connect(focus_press.bind(i.get_parent()))
		if i.get_class() == "HSlider" and i.get_parent().get_class() == "TextureButton":
			i.get_parent().button_down.connect(i.grab_focus)
			i.get_parent().button_up.connect(i.release_focus)
			i.get_parent().mouse_exited.connect(unpress.bind(i.get_parent()))
	for i in get_all_button($Menu):
		if i.get_class() == "TextureButton":
			i.pressed.connect(HUDSound.pressed2)
			i.mouse_entered.connect(HUDSound.select)
	for i in $Setting.get_children():
		if i.get_class() == "TextureButton":
			i.pressed.connect(HUDSound.pressed2)
			i.mouse_entered.connect(HUDSound.select)
	for i in get_all_button($Setting):
		if i.get_class() == "TextureButton" and i.get_parent() != $Setting:
			i.pressed.connect(HUDSound.pressed)
			i.mouse_entered.connect(HUDSound.select)
			i.mouse_exited.connect(i.release_focus)
		if i.get_class() == "OptionButton":
			i.get_popup().transparent_bg = true
	$Setting/Control/Scroll/Setting/Key.pressed.connect(HUDSound.pressed2)
	$Setting/Control/Scroll/Setting/Key.mouse_entered.connect(HUDSound.select)

func get_all_button(node) -> Array:
	var nodes : Array = []
	for i in node.get_children():
		if i.get_child_count() > 0:
			nodes.append(i)
			nodes.append_array(get_all_button(i))
		else:
			nodes.append(i)
	return nodes
	
var opening_menu = false
var exit = 0
var pause_delay = 0
func _physics_process(_delta):
	if Key.escape or $Back.is_hovered() and Input.is_action_just_released("ui_select") or Input.is_action_just_released("ui_back"):
		if opening_menu:
			HUDSound.cancel()
		if $Setting/Setting.button_pressed or $Setting/Control.button_pressed or $Setting/Graphic.button_pressed or $Setting/Audio.button_pressed or $Setting/Support.button_pressed:
			if $Setting/Control/Scroll/Setting/Shift.button_pressed or $Setting/Control/Scroll/Setting/Doubletap.button_pressed or $Setting/Control/Scroll/Setting/Crosshair.button_pressed or $Setting/Control/Scroll/Setting/Sens.button_pressed or $Setting/Control/Scroll/Setting/JoyX.button_pressed or $Setting/Control/Scroll/Setting/JoyY.button_pressed:
				$Setting/Control/Scroll/Setting/Doubletap.button_pressed = false
				$Setting/Control/Scroll/Setting/Crosshair.button_pressed = false
				$Setting/Control/Scroll/Setting/Shift.button_pressed = false
				$Setting/Control/Scroll/Setting/Sens.button_pressed = false
				$Setting/Control/Scroll/Setting/JoyX.button_pressed = false
				$Setting/Control/Scroll/Setting/JoyY.button_pressed = false
			else:
				$Setting/Setting.button_pressed = false
				$Setting/Control.button_pressed = false
				$Setting/Graphic.button_pressed = false
				$Setting/Audio.button_pressed = false
				$Setting/Support.button_pressed = false
		else:
			$Menu/Setting.button_pressed = false
		$Menu/Quit.button_pressed = false
		$Menu/Self.button_pressed = false
		$Menu/Achieve.button_pressed = false
		$Menu/Lobby.button_pressed = false
		$Menu/Quit.button_pressed = false
	$Menu.visible = opening_menu
	$Back.visible = $Menu.visible
	$Setting.visible = $Menu/Setting.button_pressed
	$Setting/Control/Scroll.visible = $Setting/Control.button_pressed
	$Setting/Audio/Scroll.visible = $Setting/Audio.button_pressed
	if opening_menu:
		update_setting()
		$Menu/Quit/Quit.visible = $Menu/Quit.button_pressed
		$Menu/Quit/Label2.visible = $Menu/Quit.button_pressed
		$Menu/Quit/ProgressBar.value = exit
		$Setting/Control/Scroll.visible = $Setting/Control.button_pressed
		$Menu/Quit/Quit.visible = $Menu/Quit.button_pressed
		$Menu/Quit/Label2.visible = $Menu/Quit.button_pressed
		$Menu/Quit/ProgressBar.value = exit
		$Setting/Control/Scroll.visible = $Setting/Control.button_pressed
		if $Menu/Setting.button_pressed:
			$Back/Line.position.y = lerpf($Back/Line.position.y,31,0.2 * 60.0/Engine.physics_ticks_per_second)
			$Back/Line2.position.y = lerpf($Back/Line2.position.y,31,0.2 * 60.0/Engine.physics_ticks_per_second)
			if $Setting/Control.button_pressed:
				$Menu.position.x = lerpf($Menu.position.x,-352,0.5 * 60.0/Engine.physics_ticks_per_second)
				$Back.position.x = lerpf($Back.position.x,160,0.5 * 60.0/Engine.physics_ticks_per_second)
				$Setting.position.x = lerpf($Setting.position.x,-64,0.5 * 60.0/Engine.physics_ticks_per_second)
				if $Setting/Control/Scroll/Setting/Faststep.button_pressed:
					$Setting/Control/Scroll/Setting/Faststep.text = Library.control(0)
				else:
					$Setting/Control/Scroll/Setting/Faststep.text = Library.control(1)
				if $Setting/Control/Scroll/Setting/Crouch.button_pressed:
					$Setting/Control/Scroll/Setting/Crouch.text = Library.control(3)
				else:
					$Setting/Control/Scroll/Setting/Crouch.text = Library.control(2)
				$Setting/Control/Scroll/Setting/Sens.disabled = Setting.mouse_pos == 3
				$Setting/Control/Scroll/Setting/Sens/SpinBox.editable = Setting.mouse_pos != 3
				$Setting/Control/Scroll/Setting/Sens/HSlider.editable = Setting.mouse_pos != 3
				if $Setting/Control/Scroll/Setting/Sens/HSlider.has_focus():
					$Setting/Control/Scroll/Setting/Sens/SpinBox.value = $Setting/Control/Scroll/Setting/Sens/HSlider.value
				if $Setting/Control/Scroll/Setting/JoyX/HSlider.has_focus():
					$Setting/Control/Scroll/Setting/JoyX/SpinBox.value = $Setting/Control/Scroll/Setting/JoyX/HSlider.value
				if $Setting/Control/Scroll/Setting/JoyY/HSlider.has_focus():
					$Setting/Control/Scroll/Setting/JoyY/SpinBox.value = $Setting/Control/Scroll/Setting/JoyY/HSlider.value
				if Input.is_action_just_released("apply"):
					$Setting/Control/Scroll/Setting/Sens/SpinBox.apply()
					$Setting/Control/Scroll/Setting/Sens/SpinBox.release_focus()
					$Setting/Control/Scroll/Setting/Sens/HSlider.value = $Setting/Control/Scroll/Setting/Sens/SpinBox.value
					$Setting/Control/Scroll/Setting/JoyX/SpinBox.apply()
					$Setting/Control/Scroll/Setting/JoyX/SpinBox.release_focus()
					$Setting/Control/Scroll/Setting/JoyX/HSlider.value = $Setting/Control/Scroll/Setting/JoyX/SpinBox.value
					$Setting/Control/Scroll/Setting/JoyY/SpinBox.apply()
					$Setting/Control/Scroll/Setting/JoyY/SpinBox.release_focus()
					$Setting/Control/Scroll/Setting/JoyY/HSlider.value = $Setting/Control/Scroll/Setting/JoyY/SpinBox.value
				$Setting/Control/Scroll/Setting/Input.visible = $Setting/Control/Scroll/Setting/Key.button_pressed
				$Setting/Control/Scroll/Setting/Crosshair/OptionButton.button_pressed = $Setting/Control/Scroll/Setting/Crosshair.button_pressed
				$Setting/Control/Scroll/Setting/Doubletap/OptionButton.button_pressed = $Setting/Control/Scroll/Setting/Doubletap.button_pressed
				$Setting/Control/Scroll/Setting/Shift/OptionButton.button_pressed = $Setting/Control/Scroll/Setting/Shift.button_pressed
				if $Setting/Control/Scroll/Setting/Key.button_pressed:
					$Setting/Control/Scroll/Setting/Key.text = Library.control(5)
				else:
					$Setting/Control/Scroll/Setting/Key.text = Library.control(4)
			elif $Setting/Audio.button_pressed:
				$Menu.position.x = lerpf($Menu.position.x,-352,0.5 * 60.0/Engine.physics_ticks_per_second)
				$Back.position.x = lerpf($Back.position.x,160,0.5 * 60.0/Engine.physics_ticks_per_second)
				$Setting.position.x = lerpf($Setting.position.x,-64,0.5 * 60.0/Engine.physics_ticks_per_second)
				if $Setting/Audio/Scroll/Setting/Master/HSlider.has_focus():
					$Setting/Audio/Scroll/Setting/Master/SpinBox.value = $Setting/Audio/Scroll/Setting/Master/HSlider.value
				if Input.is_action_just_released("apply"):
					$Setting/Audio/Scroll/Setting/Master/SpinBox.apply()
					$Setting/Audio/Scroll/Setting/Master/SpinBox.release_focus()
					$Setting/Audio/Scroll/Setting/Master/HSlider.value = $Setting/Audio/Scroll/Setting/Master/SpinBox.value
			else:
				$Menu.position.x = lerpf($Menu.position.x,544,0.5 * 60.0/Engine.physics_ticks_per_second)
				$Back.position.x = lerpf($Back.position.x,1058,0.5 * 60.0/Engine.physics_ticks_per_second)
				$Setting.position.x = lerpf($Setting.position.x,832,0.5 * 60.0/Engine.physics_ticks_per_second)
		else:
			$Menu.position.x = lerpf($Menu.position.x,832,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Back.position.x = lerpf($Back.position.x,1058,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Back/Line.position.y = lerpf($Back/Line.position.y,20,0.2 * 60.0/Engine.physics_ticks_per_second)
			$Back/Line2.position.y = lerpf($Back/Line2.position.y,41,0.2 * 60.0/Engine.physics_ticks_per_second)
			$Setting/Setting.button_pressed = false
			$Setting/Control.button_pressed = false
			$Setting/Graphic.button_pressed = false
			$Setting/Audio.button_pressed = false
			$Setting/Support.button_pressed = false
		if $Menu/Quit.button_pressed:
			$Menu/Quit/Label.text = "back"
			$Menu/Quit/Quit.modulate.a = lerpf($Menu/Quit/Quit.modulate.a,1.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Quit/Label2.modulate.a = lerpf($Menu/Quit/Label2.modulate.a,1.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Quit/Quit.position.x = lerpf($Menu/Quit/Quit.position.x,128,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Quit/Label2.position.y = lerpf($Menu/Quit/Label2.position.y,-34,0.5 * 60.0/Engine.physics_ticks_per_second)
		else:
			$Menu/Quit/Label.text = "exit"
			$Menu/Quit/Quit.modulate.a = lerpf($Menu/Quit/Quit.modulate.a,0.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Quit/Label2.modulate.a = lerpf($Menu/Quit/Label2.modulate.a,0.0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Quit/Quit.position.x = lerpf($Menu/Quit/Quit.position.x,0,0.5 * 60.0/Engine.physics_ticks_per_second)
			$Menu/Quit/Label2.position.y = lerpf($Menu/Quit/Label2.position.y,0,0.5 * 60.0/Engine.physics_ticks_per_second)
	else:
		$Menu/Quit.button_pressed = false
		$Menu/Setting.button_pressed = false
		$Menu/Self.button_pressed = false
		$Menu/Achieve.button_pressed = false
		$Menu/Lobby.button_pressed = false
		$Menu/Quit.button_pressed = false
		$Setting/Setting.button_pressed = false
		$Setting/Control.button_pressed = false
		$Setting/Graphic.button_pressed = false
		$Setting/Audio.button_pressed = false
		$Setting/Support.button_pressed = false
		$Menu/Quit/Quit.modulate.a = 0
		$Menu/Quit/Label2.modulate.a = 0
		$Menu/Quit/Quit.position.x = 0
		$Menu/Quit/Label2.position.y = 0

func import_setting():
	$Setting/Control/Scroll/Setting/Faststep.button_pressed = Setting.fast_step
	$Setting/Control/Scroll/Setting/Crouch.button_pressed = Setting.crouch_hold
	$Setting/Control/Scroll/Setting/Doubletap/OptionButton.selected = Setting.dash_mode
	$Setting/Control/Scroll/Setting/Shift/OptionButton.selected = Setting.sprint_mode
	$Setting/Control/Scroll/Setting/Crosshair/OptionButton.selected = Setting.mouse_pos
	$Setting/Control/Scroll/Setting/Zoom.button_pressed = Setting.to_mouse_zoom
	$Setting/Control/Scroll/Setting/Controller.button_pressed = Setting.controller
	$Setting/Control/Scroll/Setting/Stick.button_pressed = Setting.stick_aim
	$Setting/Control/Scroll/Setting/Sens/SpinBox.value = Setting.mouse_sens
	$Setting/Control/Scroll/Setting/Sens/HSlider.value = Setting.mouse_sens
	$Setting/Audio/Scroll/Setting/Master/SpinBox.value = db_to_linear(AudioServer.get_bus_volume_db(0))*50
	$Setting/Audio/Scroll/Setting/Master/HSlider.value = db_to_linear(AudioServer.get_bus_volume_db(0))*50
func update_setting():
	Setting.fast_step = $Setting/Control/Scroll/Setting/Faststep.button_pressed
	Setting.crouch_hold = $Setting/Control/Scroll/Setting/Crouch.button_pressed
	Setting.to_mouse_zoom = $Setting/Control/Scroll/Setting/Zoom.button_pressed
	Setting.controller = $Setting/Control/Scroll/Setting/Controller.button_pressed
	Setting.stick_aim = $Setting/Control/Scroll/Setting/Stick.button_pressed
	Setting.mouse_sens = $Setting/Control/Scroll/Setting/Sens/SpinBox.value
	AudioServer.set_bus_volume_db(0,linear_to_db($Setting/Audio/Scroll/Setting/Master/SpinBox.value/50))
func double_tap_dash(index):
	Setting.dash_mode = index
	HUDSound.pressed()
func sprint(index):
	Setting.sprint_mode = index
	HUDSound.pressed()
func crosshair(index):
	Setting.mouse_pos = index
	HUDSound.pressed()
func focus_press(node):
	node.button_pressed = !node.button_pressed
func unpress(node):
	node.button_pressed = false
	node.release_focus()
