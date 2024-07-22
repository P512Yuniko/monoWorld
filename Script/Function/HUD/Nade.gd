extends TextureButton
var type = 1
@export var code = 0
var count = 0
func _ready():
	update()
func update():
	$Bar.value = count
	$Type.frame = code
