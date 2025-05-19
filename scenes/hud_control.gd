extends Control

@onready var item_list: ItemList = $ItemList
@onready var terrain_node: Node = get_node("/root/Main/TileMap")

# Building ID to name/scene
var building_data = {
	1: {"name": "Small House", "scene": preload("res://scenes/Buildings/Small_House.tscn")},
	2: {"name": "Tree", "scene": preload("res://scenes/Buildings/Tree.tscn")},
	3: {"name": "Greatfire", "scene": preload("res://scenes/Buildings/GreatFire.tscn")}
}

# Reference to the tilemap to set the building
var tilemap_script: Node = null

func _ready():
	# Populate the item list with building names and icons if needed
	for id in building_data.keys():
		var name = building_data[id]["name"]
		var idx = item_list.add_item(name)
		item_list.set_item_metadata(idx, id)  # Store building ID with each item

	# Connect the signal
	item_list.connect("item_selected", Callable(self, "_on_item_selected"))

	# Optionally: find the tilemap script if it's in the scene
	tilemap_script = get_node("/root/Main/TileMap")  # Adjust path as needed


func _on_item_selected(index: int):
	var building_id = item_list.get_item_metadata(index)
	print("Selected building ID:", building_id)

	if tilemap_script and tilemap_script.has_method("set_current_building"):
		tilemap_script.call("set_current_building", building_id)
