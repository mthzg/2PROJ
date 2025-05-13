extends Control

signal building_selected(building_name: String)

@onready var building_grid = $Panel/BuildingGrid

# Liste des bâtiments débloqués
var unlocked_buildings := []

# Dictionnaire des bâtiments disponibles avec leurs icônes
var all_buildings := {
	"house": preload("res://Assets/house.png"),
	"farm": preload("res://Assets/house.png"),
	"storage": preload("res://Assets/house.png"),
	"workshop": preload("res://Assets/house.png"),
}

func _ready():
	print("building_grid found:", building_grid)
	unlock_building("house")  # Débloque la maison au démarrage

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
		emit_signal("building_selected", building_name)
	)

	building_grid.add_child(btn)
