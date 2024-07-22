extends Camera2D

var rng = RandomNumberGenerator.new()
var shake_strength = 0.0
var shake_fade = 0.0
var shake_offset = Vector2()
func shake(strength,fade):
	shake_strength = strength
	shake_fade = fade
func _physics_process(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shake_fade * delta)
		shake_offset = randomoffset()
func randomoffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
