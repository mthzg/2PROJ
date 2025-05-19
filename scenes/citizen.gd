extends CharacterBody2D

var terrain_tilemap: TileMap  # Parent TileMap that owns the layers
var ground_layer: TileMapLayer
var rocks_layer: TileMapLayer
var water_layer: TileMapLayer

@export var speed: float = 50.0

func _ready():
	if terrain_tilemap == null:
		push_error("❌ terrain_tilemap is not set!")
		return
	velocity = Vector2.RIGHT * speed
	print("✅ Citizen ready with velocity: ", velocity)

func _physics_process(delta):
	if terrain_tilemap == null:
		return

	if is_over_water():
		velocity = Vector2.ZERO
	else:
		velocity = Vector2.RIGHT * speed

	move_and_slide()

func is_over_water() -> bool:
	var local_pos = terrain_tilemap.to_local(global_position)
	var cell = terrain_tilemap.local_to_map(local_pos)

	var ground_tile = ground_layer.get_cell_source_id(cell)
	var rocks_tile = rocks_layer.get_cell_source_id(cell)
	var water_tile = water_layer.get_cell_source_id(cell)

	# ❌ Water tile exists, or ❌ no ground and no rock = blocked
	if water_tile != -1 or (ground_tile == -1 and rocks_tile == -1):
		return true

	return false
