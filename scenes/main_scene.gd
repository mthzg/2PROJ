extends Node2D

@onready var clock = get_node("CanvasLayer/Control/Clock")
@onready var terrain = get_node("Terrain")
@onready var citizen = get_node("Citizen")
@onready var hud_control = get_node("CanvasLayer/Control")

var current_speed_multiplier: float = 1.0

var minute_counter := 0
var total_citizens: int = 0
var max_citizens: int 
var citizens := []
var wood: int = 100
var berry: int = 100
var water: int = 100

var berry_bushes: Array

var current_tree_workers: int = 0
var desired_tree_workers: int = 0

var current_berry_workers: int = 0
var desired_berry_workers: int = 0

var current_water_wokers: int = 0
var desired_water_workers: int = 0

var current_wood_workers: int = 0
var desired_wood_workers: int = 0

func _ready():
	# Pass self reference to terrain for resource access
	hud_control.main_scene = self
	terrain.main_game = self  # terrain script will have `var main_game` to hold this

	for i in range(10):
		var new_citizen = terrain.spawn_citizens(current_speed_multiplier)
		total_citizens += 1
		citizens.append(new_citizen)
		new_citizen.main_game = self
		#new_citizen.go_gather("tree")
		

	if clock.has_signal("time_updated"):
		clock.connect("time_updated", Callable(self, "_on_time_updated"))

func get_current_ressource_worker(type: String):
	if type == "tree":
		return current_tree_workers
	elif type == "beryy":
		return current_berry_workers

func _on_time_updated(current_time: String) -> void:
	minute_counter += 1
	
	
	
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

		
	# Manage citizens time_to_live:
	for i in range(citizens.size() - 1, -1, -1):
		var c = citizens[i]
		if not is_instance_valid(c):
			citizens.remove_at(i)
			total_citizens -= 1
			continue
		c.time_to_live -= 1
		if c.time_to_live <= 0:
			# If gathering, remove from their workplace counts
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
					
			
			c.cleanup_before_removal()
			c.queue_free()
			citizens.remove_at(i)
			total_citizens -= 1
			print("Citizen removed due to expired time_to_live")


	# Spawn new citizens every 60 minutes (if under max)
	if minute_counter >= 20:
		minute_counter = 0
		#set_desired_berry_workers(3)
		#set_desired_tree_workers(3)
		if total_citizens < max_citizens:
			var new_citizen = terrain.spawn_citizens(current_speed_multiplier)
			if new_citizen:
				citizens.append(new_citizen)
				total_citizens += 1
				new_citizen.main_game = self
				#new_citizen.go_gather("tree")
				#new_citizen.go_gather("berry")
				
			print("Total citizens = ", total_citizens)
			print("Max = ", max_citizens)
		else:
			print("Max citizens reached. No new spawn.")
			
	#check_sleep_cycle()
	#hud_control.update_work_tab(hud_control.get_real_workplaces())


			
func check_sleep_cycle():
	for c in citizens:
		if not is_instance_valid(c):
			continue

		# Citizen is sleeping
		if c.is_sleeping:
			c.sleep_timer += 1
			if c.sleep_timer >= 5:  # 5 in-game hours
				c.is_sleeping = false
				c.sleep_timer = 0
				#print("Citizen waking up and resuming", c.previous_resource_type)

				#if c.previous_resource_type != "":
				#	c.go_gather(c.previous_resource_type)
				#	if c.previous_resource_type == "tree":
				#		current_tree_workers += 1
				#	elif c.previous_resource_type == "berry":
				#		current_berry_workers += 1
				#c.previous_resource_type = ""

		# Citizen is working
		elif c.is_gathering:
			c.work_hours_elapsed += 1
			if c.work_hours_elapsed >= 20:  # 19 in-game hours
				c.work_hours_elapsed = 0
				c.previous_resource_type = c.current_ressource_type_to_gather
				c.stop_gathering()
				if c.previous_resource_type == "tree":
					current_tree_workers = max(0, current_tree_workers - 1)
				elif c.previous_resource_type == "berry":
					current_berry_workers = max(0, current_berry_workers - 1)
				elif c.previous_resource_type == "water":
					current_water_wokers = max(0, current_water_wokers - 1)
				elif c.previous_resource_type == "wood":
					current_wood_workers = max(0, current_wood_workers - 1)
				c.is_sleeping = true
				print("Citizen is going to sleep after 19h of work.")


	
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

	print("Removed %d citizens from gathering %s" % [removed, resource_type])

func set_desired_berry_workers(value: int):
	desired_berry_workers = value

func set_desired_tree_workers(value: int):
	desired_tree_workers = value

func set_desired_water_workers(value: int):
	desired_water_workers = value
	
func set_desired_wood_workers(value: int):
	desired_wood_workers = value

	
func assign_citizens_to_gather(resource_type: String, max_to_assign: int) -> void:
	var assigned = 0
	for c in citizens:
		if assigned >= max_to_assign:
			break
		if not is_instance_valid(c):
			continue
		# Check if citizen is idle (you can define this flag in your citizen)
		if c.is_gathering or c.is_returning_home or c.has_gathered_resource:
			continue
		
		# Check if there is at least one work spot with free space for resource_type
		var can_assign = false
		for spot_cell in c.work_spot_cells.keys():
			var spot = c.work_spot_cells[spot_cell]
			if spot.type == resource_type and spot.current_workers < spot.max_workers:
				can_assign = true
				break
		
		if can_assign:
			print("citizen going to work = ", resource_type)
			c.go_gather(resource_type)
			assigned += 1
			if resource_type == "berry":
				current_berry_workers += 1
			elif resource_type == "tree":
				set_desired_tree_workers(desired_tree_workers - 1)
			elif resource_type == "water":
				current_water_wokers += 1
			elif resource_type == "wood":
				current_wood_workers += 1				


func set_speed_multiplier(multiplier: float) -> void:
	current_speed_multiplier = multiplier
	print("setter called value = ", multiplier)
	for c in citizens:
		if is_instance_valid(c):
			c.set_speed_multiplier(multiplier)
			c.refresh_velocity()  # Optional if you want immediate effect

func can_spend_wood(amount: int) -> bool:
	return wood >= amount

func spend_wood(amount: int) -> void:
	wood -= amount
	print("Wood spent:", amount, " Remaining wood:", wood)

func increment_wood(amount: int):
	wood += amount

func increase_max_citizens(amount: int = 1) -> void:
	max_citizens += amount
	print("max_citizens increased to:", max_citizens)
