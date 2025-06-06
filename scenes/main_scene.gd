extends Node2D

@onready var clock = get_node("CanvasLayer/Control/Clock")
@onready var terrain = get_node("Terrain")
@onready var citizen = get_node("Citizen")
@onready var hud_control = get_node("CanvasLayer/Control")

var current_speed_multiplier: float = 1.0

var minute_counter_spawn := 0
var minute_counter_collect_ressource := 0
var total_citizens: int = 0
var max_citizens: int 
var citizens := []
var wood: int = 100
var max_wood: int = 0

var berry: int = 0
var max_berry: int = 0

var water: int = 0
var max_water: int = 0

var research_points: int = 0

var berry_bushes: Array

var current_tree_workers: int = 0
var desired_tree_workers: int = 0

var current_berry_workers: int = 0
var desired_berry_workers: int = 0

var current_water_wokers: int = 0
var desired_water_workers: int = 0

var current_wood_workers: int = 0
var desired_wood_workers: int = 0

var current_research_workers: int = 0
var desired_research_workers: int = 0


func _ready():
	hud_control.main_scene = self
	terrain.main_game = self
	terrain.connect("building_selected", hud_control.show_building_info_popup)
	if has_node("Citizen"):
		$Citizen.visible = false

	for i in range(10):
		var new_citizen = terrain.spawn_citizens(current_speed_multiplier)
		total_citizens += 1
		citizens.append(new_citizen)
		new_citizen.main_game = self
		

	if clock.has_signal("time_updated"):
		clock.connect("time_updated", Callable(self, "_on_time_updated"))

func get_current_ressource_worker(type: String):
	if type == "tree":
		return current_tree_workers
	elif type == "beryy":
		return current_berry_workers

func update_resource_capacity():
	var house_count = terrain.houses.size()

	max_wood = house_count * 5
	max_berry = house_count * 5
	max_water = house_count * 5


func _on_time_updated(current_time: String) -> void:
	minute_counter_spawn += 1
	minute_counter_collect_ressource += 1
	
	
	var delta_berry = desired_berry_workers - current_berry_workers
	if delta_berry > 0:
		assign_citizens_to_gather("berry", delta_berry)
	elif delta_berry < 0:
		remove_citizens_from_gathering("berry", -delta_berry)

		
	var delta_tree = desired_tree_workers - current_tree_workers
	if delta_tree > 0:
		assign_citizens_to_gather("tree", delta_tree)
	elif delta_tree < 0:
		remove_citizens_from_gathering("tree", -delta_tree)
		
	var delta_water = desired_water_workers - current_water_wokers
	if delta_water > 0:
		assign_citizens_to_gather("water", delta_water)
	elif delta_water < 0:
		remove_citizens_from_gathering("water", -delta_water)
		
	var delta_wood = desired_wood_workers - current_wood_workers
	if delta_wood > 0:
		assign_citizens_to_gather("wood", delta_wood)
	elif delta_wood < 0:
		remove_citizens_from_gathering("wood", -delta_wood)
		
	var delta_research = desired_research_workers - current_research_workers
	if delta_research > 0:
		assign_citizens_to_gather("research", delta_research)
	elif delta_research < 0:
		remove_citizens_from_gathering("research", -delta_research)

		
	# Manage citizens time_to_live:
	for i in range(citizens.size() - 1, -1, -1):
		var c = citizens[i]
		if not is_instance_valid(c):
			citizens.remove_at(i)
			total_citizens -= 1
			continue
		c.time_to_live -= 1
		if c.time_to_live <= 0:
			if c.is_gathering:
				var res_type = c.current_ressource_type_to_gather
				c.stop_gathering()
				if res_type == "tree":
					current_tree_workers = max(0, current_tree_workers - 1)
				elif res_type == "berry":
					current_berry_workers = max(0, current_berry_workers - 1)
				elif res_type == "water":
					current_water_wokers = max(0, current_water_wokers - 1)
				elif res_type == "wood":
					current_wood_workers = max(0, current_wood_workers - 1)
				elif res_type == "researh":
					current_research_workers = max(0, current_research_workers - 1)
					
			
			c.cleanup_before_removal()
			c.queue_free()
			citizens.remove_at(i)
			total_citizens -= 1
			print("Citizen removed due to expired time_to_live")


	if minute_counter_spawn >= 30:
		minute_counter_spawn = 0
		if total_citizens < max_citizens:
			var new_citizen = terrain.spawn_citizens(current_speed_multiplier)
			if new_citizen:
				citizens.append(new_citizen)
				total_citizens += 1
				new_citizen.main_game = self
				
			print("Total citizens = ", total_citizens)
			print("Max = ", max_citizens)
		else:
			print("Max citizens reached. No new spawn.")
	if minute_counter_collect_ressource >= 40:
		minute_counter_collect_ressource = 0
		increment_berry(current_berry_workers)
		increment_wood(current_wood_workers)
		increment_water(current_water_wokers)
		increment_research(current_research_workers)
		
			
	check_sleep_cycle()
	update_resource_capacity()

			
func check_sleep_cycle():
	for c in citizens:
		if not is_instance_valid(c):
			continue

		if c.is_sleeping:
			c.sleep_timer += 1
			if c.sleep_timer >= 5:  # 5 in-game hours
				c.is_sleeping = false
				c.sleep_timer = 0

		# Citizen is working
		elif c.is_gathering:
			c.work_hours_elapsed += 1
			if c.work_hours_elapsed >= 20:  # 19 in-game hours
				c.work_hours_elapsed = 0
				c.stop_gathering()
				if c.current_ressource_type_to_gather == "tree":
					current_tree_workers = max(0, current_tree_workers - 1)
				elif c.current_ressource_type_to_gather == "berry":
					current_berry_workers = max(0, current_berry_workers - 1)
				elif c.current_ressource_type_to_gather == "water":
					current_water_wokers = max(0, current_water_wokers - 1)
				elif c.current_ressource_type_to_gather == "wood":
					current_wood_workers = max(0, current_wood_workers - 1)
				elif c.current_ressource_type_to_gather == "research":
					current_research_workers = max(0, current_research_workers - 1)
				c.is_sleeping = true
				var consumed_ressources: int = 0
				consumed_ressources = consume_ressources()
				c.increment_time_to_live(consumed_ressources)
				print("Citizen is going to sleep after 19h of work.")

func consume_ressources() -> int:
	var ressource_consumed = 0
	if water > 0:
		if can_spend_water(1):
			print("consomme 1 d'eau")
			spend_water(1)
			ressource_consumed += 1
	if berry > 0:
		if can_spend_berry(1):
			print("consome 1 berry")
			spend_berry(1)
			ressource_consumed += 1

	return ressource_consumed

	
	
func remove_citizens_from_gathering(resource_type: String, max_to_remove: int) -> void:
	var removed = 0
	for c in citizens:
		if removed >= max_to_remove:
			break
		if not is_instance_valid(c):
			continue
		if c.is_gathering and c.current_ressource_type_to_gather == resource_type:
			c.stop_gathering()
			removed += 1
			if resource_type == "berry":
				current_berry_workers -= 1
			elif resource_type == "tree":
				current_tree_workers -= 1
			elif resource_type == "water":
				current_water_wokers -= 1 
			elif resource_type == "wood":
				current_wood_workers -= 1 
			elif resource_type == "researh":
				current_research_workers -= 1

	print("Removed %d citizens from gathering %s" % [removed, resource_type])

func set_desired_berry_workers(value: int):
	desired_berry_workers = value

func set_desired_tree_workers(value: int):
	desired_tree_workers = value

func set_desired_water_workers(value: int):
	desired_water_workers = value
	
func set_desired_wood_workers(value: int):
	desired_wood_workers = value

func set_desired_research_workers(value: int):
	desired_research_workers = value
	
	
func assign_citizens_to_gather(resource_type: String, max_to_assign: int) -> void:
	var assigned = 0
	for c in citizens:
		if assigned >= max_to_assign:
			break
		if not is_instance_valid(c):
			continue
		if c.is_gathering or c.is_returning_home or c.has_gathered_resource:
			continue

		var success = c.go_gather(resource_type)
		if success:
			assigned += 1

			match resource_type:
				"berry":
					current_berry_workers += 1
					print("Assigned to berry")
				"tree":
					set_desired_tree_workers(desired_tree_workers - 1)
				"water":
					current_water_wokers += 1
				"wood":
					current_wood_workers += 1
				"research":
					current_research_workers += 1


		


func set_speed_multiplier(multiplier: float) -> void:
	current_speed_multiplier = multiplier
	print("setter called value = ", multiplier)
	for c in citizens:
		if is_instance_valid(c):
			c.set_speed_multiplier(multiplier)
			c.refresh_velocity() 

func can_spend_wood(amount: int) -> bool:
	return wood >= amount

func spend_wood(amount: int) -> void:
	wood -= amount
	print("Wood spent:", amount, " Remaining wood:", wood)

func increment_wood(amount: int):
	if wood + amount <= max_wood:
		wood += amount
	
func can_spend_berry(amount: int) -> bool:
	return berry >= amount

func spend_berry(amount: int) -> void:
	berry -= amount
	print("berry spent:", amount, " Remaining berry:", berry)

func increment_berry(amount: int):
	if berry + amount <= max_berry:
		berry += amount
		
func can_spend_water(amount: int) -> bool:
	return water >= amount

func spend_water(amount: int) -> void:
	water -= amount
	print("water spent:", amount, " Remaining water:", water)

func increment_water(amount: int):
	if water + amount <= max_water:
		water += amount
		
func can_spend_research(amount: int) -> bool:
	return research_points >= amount

func spend_research(amount: int) -> void:
	research_points -= amount
	print("research spent:", amount, " Remaining research:", research_points)

func increment_research(amount: int):
		research_points += amount

func increase_max_citizens(amount: int = 1) -> void:
	max_citizens += amount
	print("max_citizens increased to:", max_citizens)
	
	
func show_citizen_popup(citizen):
	print("show_citizen_popup called with: ", citizen)
	var popup = $CanvasLayer/Control/CitizenInfoPopup
	popup.show_citizen_info(citizen)
	popup.popup_centered()
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos = get_viewport().get_mouse_position()
		for c in citizens:
			if c and c.has_node("CollisionShape2D"):
				var shape = c.get_node("CollisionShape2D").shape
				var to_local = c.to_local(pos)
				if shape and shape is RectangleShape2D:
					var extents = shape.extents
					if abs(to_local.x) < extents.x and abs(to_local.y) < extents.y:
						print("Clicked citizen via manual check!")
						c._input_event(get_viewport(), event, 0)
						break
