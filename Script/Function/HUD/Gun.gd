extends TextureButton
var type = 0
@export var code = 0
var count = 0
func _ready():
	update()
func update():
	$Type.frame = int((code % 100000000000)/10000000000)
	$Gun.frame = int((code % 100000000000)/1000000000)
	if int((code % 100000000000)/1000000000) > 3:
		$Gun.position.x = 64
		custom_minimum_size.x = 128
		size.x = 128
		texture_normal = load("res://Asset/UI/Box/1x2/normal.png")
		texture_focused = load("res://Asset/UI/Box/1x2/hovered.png")
	else:
		$Gun.position.x = 32
		custom_minimum_size.x = 64
		size.x = 64
		texture_normal = load("res://Asset/UI/Box/1x1/normal.png")
		texture_focused = load("res://Asset/UI/Box/1x1/hovered.png")
