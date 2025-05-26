extends Control

@onready var item_list: ItemList = $TabContainer/ItemList
@onready var terrain_node: Node = get_node("../../Terrain")  # ✅ Updated to use the correct node name
@onready var wood_label = $TabContainer/TabInfo/WoodLabel
@onready var pop_label = $TabContainer/TabInfo/PopulationLabel
@onready var house_label = $TabContainer/TabInfo/HousingLabel


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
	
func update_info_tab(wood: int, total_citizens: int, occupied_slots: int, total_slots: int):
	wood_label.text = "Total wood: %d" % wood
	pop_label.text = "Population: %d" % total_citizens
	house_label.text = "Houses full: %d / %d" % [occupied_slots, total_slots]
	
#func update_work_tab(workplaces: Array):
#	var tab = $TabContainer/TabWork
#	tab.clear_children()
#
#	for work_data in workplaces:
#		var row = preload("res://ui/WorkRow.tscn").instantiate()
#		row.get_node("Label").text = work_data.name
#		row.get_node("WorkerCount").text = "%d / %d" % [work_data.current, work_data.max]
#		row.get_node("Button").pressed.connect(func(): assign_worker_to(work_data))
#		tab.add_child(row)
