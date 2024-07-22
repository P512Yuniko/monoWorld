extends Node2D

@export var k = 0.015
@export var d = 0.1
@export var spread: float = 1
@export var wave = 1
var springs = []
var passes = 12
@export var distance_between_springs = 32
var spring_number = 6
var water_lenght = distance_between_springs * spring_number

@onready var water_spring = preload("res://Screen/Asset/Function/Terrain/Water_Spring.tscn")

var target_height = global_position.y

var bottom = 0

@export var border_thickness = 10


func _ready():
	$Timer.start(5)
	spring_number = $Marker2D.position.x / distance_between_springs
	$Water_Border.width = border_thickness
	bottom = target_height + $Marker2D.position.y
	for i in range(spring_number):
		var x_position = distance_between_springs * i
		var w = water_spring.instantiate()
		add_child(w)
		springs.append(w)
		w.motion_factor = k
		w.initialize(x_position, i)
		w.set_collision_width(distance_between_springs)
		w.splash.connect(self.splash)
	$Water_Body_Area/CollisionShape2D.shape.size = $Marker2D.position
	$Water_Body_Area/CollisionShape2D.position = $Water_Body_Area/CollisionShape2D.shape.size/2
func _process(_delta):
	for i in springs:
		i.water_update(k,d)
	var left_deltas = []
	var right_deltas = []
	for i in range (springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)
	
	for j in range(passes):
		for i in range(springs.size()):
			if i > 0:
				left_deltas[i] = float(spread / 1000) * (springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
			if i < springs.size()-1:
				right_deltas[i] = float(spread / 1000) * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i]
	new_border()
	draw_water_body()
	

func draw_water_body():
	var curve = $Water_Border.curve
	var points = Array(curve.get_baked_points())
	var water_polygon_points = points
	var first_index = 0
	var last_index = water_polygon_points.size()-1
	water_polygon_points.append(Vector2(water_polygon_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(water_polygon_points[first_index].x, bottom))
	water_polygon_points = PackedVector2Array(water_polygon_points)
	$Water_Polygon.set_polygon(water_polygon_points)
	$Water_Polygon.set_uv(water_polygon_points)

func new_border():
	var curve = Curve2D.new().duplicate()
	var surface_points = []
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
	for i in range(surface_points.size()):
		curve.add_point(surface_points[i])
	$Water_Border.curve = curve
	$Water_Border.smooth(true)
	$Water_Border.queue_redraw()

func splash(index, speed):
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
	set_process(true)
	$Timer.start(5)

func _on_timer_timeout():
	set_process(false)
