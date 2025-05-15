extends Control

signal building_selected(building_name: String)

@onready var building_grid = $Panel/BuildingGrid

@export var tilemap: TileMap



# Liste des bâtiments débloqués
var unlocked_buildings := []

# Dictionnaire des bâtiments disponibles avec leurs icônes
var all_buildings := {
	"house": preload("res://Assets/house.png"),
	"farm": preload("res://Assets/house.png"),
	"storage": preload("res://Assets/house.png"),
	"workshop": preload("res://Assets/house.png"),
}

var selected_building: String = ""
var ghost_building: Sprite2D

func _ready():
	unlock_building("house")
	unlock_building("farm")
	unlock_building("storage")
	unlock_building("workshop")
	set_process(true)
	set_process_input(true)

func unlock_building(building_name: String):
	if building_name in all_buildings and building_name not in unlocked_buildings:
		unlocked_buildings.append(building_name)
		_add_building_button(building_name)

func _add_building_button(building_name: String):
	var btn := TextureButton.new()
	btn.texture_normal = all_buildings[building_name]
	btn.custom_minimum_size = Vector2(64, 64)
	btn.tooltip_text = building_name.capitalize()

	btn.pressed.connect(func():
		_select_building(building_name)
	)

	building_grid.add_child(btn)

func _select_building(building_name: String):
	selected_building = building_name
	emit_signal("building_selected", building_name)

	if ghost_building:
		ghost_building.queue_free()

	ghost_building = Sprite2D.new()
	ghost_building.texture = all_buildings[building_name]
	ghost_building.modulate.a = 0.5
	ghost_building.z_index = 100
	add_child(ghost_building)

func _process(_delta):
	if selected_building != "" and ghost_building:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = mouse_pos.snapped(Vector2(32, 32))
		ghost_building.global_position = snapped_pos

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_place_building(event.position)

func _place_building(mouse_position: Vector2):
	if tilemap == null:
		push_error("TileMap not assigned or not found!")
		return

	var camera := get_viewport().get_camera_2d()
	var world_pos = camera.get_screen_center_position() - (get_viewport().get_visible_rect().size / 2) + mouse_position
	var cell = tilemap.local_to_map(tilemap.to_local(world_pos))

	var tile_data = tilemap.get_cell_tile_data(0, cell)
	if tile_data == null:
		print("No tile on Ground2 at cell: ", cell)
		return

	var building_pos = tilemap.map_to_local(cell)

	var building := Sprite2D.new()
	building.texture = all_buildings[selected_building]
	building.position = building_pos
	tilemap.get_parent().add_child(building)
