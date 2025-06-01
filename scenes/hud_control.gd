extends Control

@onready var item_list: ItemList = $TabContainer/ItemList
@onready var terrain_node: Node = get_node("../../Terrain")
@onready var wood_label = $TabContainer/TabInfo/WoodLabel
@onready var berry_label = $TabContainer/TabInfo/BerryLabel
@onready var water_label = $TabContainer/TabInfo/WaterLabel
@onready var pop_label = $TabContainer/TabInfo/PopulationLabel
@onready var house_label = $TabContainer/TabInfo/HousingLabel
@onready var tab_work = $TabContainer/TabWork
@onready var grid_overlay = get_node("../../GridOverlay")
@onready var tab_container = $TabContainer

var spinbox_timers = {}
const DEBOUNCE_DELAY := 0.5

var workplace_spinboxes = {}
var last_spinbox_values = {}
var check_timer := 0.0
const CHECK_INTERVAL := 5.0
var main_scene  
var building_id = null
var building_data = {
	1: {
		"name": "Eraser", 
		"png":"res://Assets/eraser.png", 
		"unlocked": true
	},
	2: {
		"name": "Small House", 
		"scene": preload("res://scenes/Buildings/Small_House.tscn"), 
		"png":"res://Assets/house.png", 
		"size": Vector2i(2,2), 
		"occupancy": 2,
		"cost": {"wood": 2},
		"unlocked": false
	},
	3: {
		"name": "Tree", 
		"scene": preload("res://scenes/Buildings/Tree.tscn"), 
		"png":"res://Assets/tree.png", 
		"size": Vector2i(1,1),
		"cost": {},
		"unlocked": false
	},
	4: {
		"name": "Greatfire", 
		"scene": preload("res://scenes/Buildings/GreatFire.tscn"), 
		"png":"res://Assets/greatfire.png", 
		"size": Vector2i(2,2),
		"cost": {},
		"unlocked": true
	},
	5: {
		"name": "Dirt road", 
		"scene": preload("res://scenes/Buildings/dirt_road.tscn"), 
		"png":"res://Assets/dirt_road.png", 
		"size": Vector2i(1,1),
		"cost": {},
		"unlocked": true
	},
	6: {
		"name": "Berry Picker", 
		"scene": preload("res://scenes/Buildings/BerryPicker.tscn"), 
		"png":"res://Assets/berrypicker.png", 
		"size": Vector2i(2,2),
		"cost": {"wood": 15},
		"unlocked": false
	},
	7: {
		"name": "Berry Bush", 
		"scene": preload("res://scenes/Buildings/BerryBush.tscn"), 
		"png":"res://Assets/berrybush.png", 
		"size": Vector2i(1, 1),
		"cost": {},
		"unlocked": false
	},
	8: {
		"name": "Wood Cutter", 
		"scene": preload("res://scenes/Buildings/WoodCutter.tscn"), 
		"png":"res://Assets/WoodCutter.png", 
		"size": Vector2i(2, 2),
		"cost": {},
		"unlocked": false
	},
	9: {
		"name": "Water Workers Hut", 
		"scene": preload("res://scenes/Buildings/WaterWorkersHut.tscn"), 
		"png":"res://Assets/waterworkershut.png", 
		"size": Vector2i(2, 2),
		"cost": {"wood": 15},
		"unlocked": false
	},
}

func _ready():
	tab_container.connect("tab_changed", Callable(self, "_on_tab_changed"))
	grid_overlay.visible = (tab_container.current_tab == 0)
	for id in building_data.keys():
		var data = building_data[id]
		if data.get("unlocked") == true:
			var texture = load(data["png"]) 
			var idx = item_list.add_icon_item(texture) 
			item_list.set_item_metadata(idx, id) 
		update_work_tab(get_real_workplaces())
		
	item_list.connect("item_activated", Callable(self, "_on_item_selected"))
	$BuildingInfoPopup/VBox/CloseButton.connect("pressed", Callable($BuildingInfoPopup, "hide"))


func unlock_building_by_name(building_name: String) -> bool:
	for id in building_data.keys():
		if building_data[id].get("name") == building_name:
			if building_data[id]["unlocked"] == false:
				building_data[id]["unlocked"] = true
				var texture = load(building_data[id]["png"])
				var idx = item_list.add_icon_item(texture)
				item_list.set_item_metadata(idx, id)
				return true  
	print("Building not found: ", building_name)
	return false 

		
func _on_item_selected(index: int):
	var building_id = item_list.get_item_metadata(index)
	var data = building_data[building_id]
	
	print("Selected building cost: ", data.get("cost", {}))
	
	terrain_node.set_current_building(data)
	
func update_info_tab(wood: int, max_wood: int, berry: int, max_berry: int, water: int, max_water: int, total_citizens: int, max_citizens:int, occupied_slots: int, total_slots: int):
	wood_label.text = "Total wood: %d / %d" % [wood, max_wood]
	berry_label.text = "Total berry: %d / %d" % [berry, max_berry]
	water_label.text = "Total water: %d / %d" % [water, max_water]
	
	pop_label.text = "Population: %d / %d" % [total_citizens, max_citizens]
	house_label.text = "Houses full: %d / %d" % [occupied_slots, total_slots]
	
func _process(delta):
	if not main_scene:
		return

	check_timer += delta
	if check_timer >= CHECK_INTERVAL:
		check_timer = 0.0
		update_work_tab(get_real_workplaces())

	var wood = main_scene.wood
	var max_wood = main_scene.max_wood
	var berry = main_scene.berry
	var max_berry = main_scene.max_berry
	var water = main_scene.water
	var max_water = main_scene.max_water
	
	var total_citizens = main_scene.total_citizens
	var max_citizens = main_scene.max_citizens
	var occupied = total_citizens
	var total_slots = main_scene.max_citizens
	update_info_tab(wood, max_wood, berry, max_berry, water, max_water,total_citizens, max_citizens, occupied, total_slots)

func get_real_workplaces() -> Array:
	if not main_scene:
		return []

	var result = []
	
	var workplace_types = {
		1: {"name": "Berry Picker", "type": "berry"},
		2: {"name": "Tree", "type": "tree"},
		3: {"name": "Water Workers Hut", "type": "water"},
		4: {"name": "Wood Cutter", "type": "wood"}
		
	}

	for id in workplace_types.keys():
		var data = workplace_types[id]
		var stats = terrain_node.get_worker_stats_for(data.type)
		result.append({
			"id": id,
			"name": data.name,
			"current": stats.current,
			"max": stats.total_max
		})

	return result



func update_work_tab(workplaces):
	for child in tab_work.get_children():
		tab_work.remove_child(child)
		child.queue_free()
	workplace_spinboxes.clear()
	last_spinbox_values.clear()

	for work_data in workplaces:
		var row = preload("res://scenes/WorkRow.tscn").instantiate()
		row.get_node("Label").text = work_data.name
		row.get_node("WorkerCount").text = "%d / %d" % [work_data.current, work_data.max]

		var spinbox = row.get_node("MaxWorker")
		spinbox.min_value = 0
		spinbox.max_value = work_data.max
		spinbox.value = work_data.current
		spinbox.connect("value_changed", Callable(self, "_on_spinbox_value_changed").bind(work_data.id))

		workplace_spinboxes[work_data.id] = spinbox
		last_spinbox_values[work_data.id] = spinbox.value

		tab_work.add_child(row)
		
		
func _on_spinbox_value_changed(value: float, id: int):
	var int_value = int(value)

	if last_spinbox_values.has(id) and last_spinbox_values[id] == int_value:
		return 

	last_spinbox_values[id] = int_value

	if spinbox_timers.has(id):
		spinbox_timers[id].queue_free()
		spinbox_timers.erase(id)


	var timer := Timer.new()
	timer.wait_time = DEBOUNCE_DELAY
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)

	timer.connect("timeout", Callable(self, "_on_spinbox_delay_timeout").bind(id, int_value))

	spinbox_timers[id] = timer

func _on_spinbox_delay_timeout(id: int, value: int):
	assign_workers_to_workplace(id, value)

	if spinbox_timers.has(id):
		spinbox_timers[id].queue_free()
		spinbox_timers.erase(id)


func assign_workers_to_workplace(id: int, new_max: int):
	var workplace_types = {
		1: "berry",
		2: "tree",
		3: "water",
		4: "wood"
	}

	if not workplace_types.has(id):
		return
	
	var resource_type = workplace_types[id]
	if resource_type == "tree":
		main_scene.set_desired_tree_workers(new_max)
	elif resource_type == "berry":
		main_scene.set_desired_berry_workers(new_max)
	elif resource_type == "water":
		main_scene.set_desired_water_workers(new_max)
	elif resource_type == "wood":
		main_scene.set_desired_wood_workers(new_max)
		
func show_building_info_popup(cell: Vector2i, building_data: Dictionary):
	var popup = $BuildingInfoPopup
	var label = popup.get_node("VBox/InfoLabel")
	var progress_bar = popup.get_node("VBox/ProgressBar")
	var population_label = popup.get_node("VBox/PopulationLabel")
	var hunger_bar = popup.get_node("VBox/HungerBar")
	var thirst_bar = popup.get_node("VBox/ThirstBar")
	var sleep_bar = popup.get_node("VBox/SleepBar")
	var berry_bar = popup.get_node("VBox/BerryBar")
	var greatfire_bar = popup.get_node("VBox/GreatFireBar")

	# Hide all new widgets by default
	population_label.visible = false
	hunger_bar.visible = false
	thirst_bar.visible = false
	sleep_bar.visible = false
	berry_bar.visible = false
	greatfire_bar.visible = false

	var info_text = ""
	info_text += "Building: %s\n" % building_data.get("name", "Unknown")

	var show_progress = false
	var progress_value = 0.0

	# HOUSE LOGIC
	if building_data.get("name", "") == "Small House":
		population_label.visible = true
		hunger_bar.visible = true
		thirst_bar.visible = true
		sleep_bar.visible = true
		berry_bar.visible = true
		greatfire_bar.visible = true

		# Show population
		var assigned_citizens = building_data.get("assigned_citizens", [])
		var max_occupancy = building_data.get("occupancy", 2)
		population_label.text = "Population: %d/%d" % [assigned_citizens.size(), max_occupancy]

		# Average citizen stats for progress bars (if any assigned)
		var hunger = 0.0
		var thirst = 0.0
		var sleep = 0.0
		var berry = 0.0
		var greatfire = 0.0
		if assigned_citizens.size() > 0:
			for c in assigned_citizens:
				hunger += c.hunger
				thirst += c.thirst
				sleep += c.sleep
				berry += c.berries

			hunger /= assigned_citizens.size()
			thirst /= assigned_citizens.size()
			sleep /= assigned_citizens.size()
			berry /= assigned_citizens.size()
			greatfire /= assigned_citizens.size()
		hunger_bar.value = hunger
		thirst_bar.value = thirst
		sleep_bar.value = sleep
		berry_bar.value = berry
		greatfire_bar.value = greatfire

	if building_data.has("work_spot"):
		var ws = building_data["work_spot"]
		info_text += "Type: %s\n" % ws.get("type", "N/A")
		info_text += "Workers: %d / %d\n" % [ws.get("current_workers", 0), ws.get("max_workers", 0)]
		if ws.get("type") == "berry":
			var berries_per_worker_per_hour = 10
			var per_hour = ws.get("current_workers", 0) * berries_per_worker_per_hour
			info_text += "Berry output/hour: %d\n" % per_hour
		if ws.get("type") == "tree" and ws.has("cut_progress"):
			show_progress = true
			progress_value = ws["cut_progress"]

	if progress_bar:
		progress_bar.visible = show_progress
		if show_progress:
			progress_bar.value = progress_value 
		else:
			progress_bar.value = 0.0

	label.text = info_text
	popup.popup_centered()
	
func _on_tab_changed(tab_idx: int) -> void:
	grid_overlay.visible = (tab_idx == 0)
