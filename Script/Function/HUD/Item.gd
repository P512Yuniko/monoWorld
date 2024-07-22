extends TextureButton

var type = 2
@export var code = 0
func _ready():
	$Type.frame = code
