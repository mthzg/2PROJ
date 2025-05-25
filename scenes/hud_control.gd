extends Control

@onready var item_list: ItemList = $ItemList
@onready var terrain_node: Node = get_node("../../Terrain")  # ✅ Updated to use the correct node name

var building_id = null
# Building ID to name/scene
var building_data = {
	1: {
		"name": "Small House", 
		"scene": preload("res://scenes/Buildings/Small_House.tscn"), 
		"png":"res://Assets/house.png", 
		"size": Vector2i(2,2), 
		"occupancy": 2,
		"cost": {"wood": 2}  # <--- Added cost here
	},
	2: {
		"name": "Tree", 
		"scene": preload("res://scenes/Buildings/Tree.tscn"), 
		"png":"res://Assets/tree.png", 
		"size": Vector2i(1,1),
		"cost": {}
	},
	3: {
		"name": "Greatfire", 
		"scene": preload("res://scenes/Buildings/GreatFire.tscn"), 
		"png":"res://Assets/greatfire.png", 
		"size": Vector2i(2,2),
		"cost": {}
	},
	4: {
		"name": "Dirt road", 
		"scene": preload("res://scenes/Buildings/dirt_road.tscn"), 
		"png":"res://Assets/dirt_road.png", 
		"size": Vector2i(1,1),
		"cost": {}
	}	
}

func _ready():
	for id in building_data.keys():
		var data = building_data[id]
		var texture = load(data["png"])  # Load the PNG as a Texture2D
		var idx = item_list.add_icon_item(texture)  # Use icon only
		item_list.set_item_metadata(idx, id)  # Attach ID to each item

	item_list.connect("item_activated", Callable(self, "_on_item_selected"))


func _on_item_selected(index: int):
	var building_id = item_list.get_item_metadata(index)
	var data = building_data[building_id]
	
	# For debugging, print cost:
	print("Selected building cost: ", data.get("cost", {}))
	
	# Pass data including cost to terrain node
	terrain_node.set_current_building(data)
