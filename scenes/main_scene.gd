extends Node2D

@onready var clock = get_node("CanvasLayer/Control/Clock")
@onready var terrain = get_node("Terrain")
@onready var citizen = get_node("Citizen")


var minute_counter := 0
var total_citizens: int = 0
var max_citizens: int = 15  # Initial max citizens
var citizens := []

func _ready():
	for i in range(10):
		var new_citizen = terrain.spawn_citizens()
		total_citizens += 1
		citizens.append(new_citizen)
		new_citizen.go_gather("tree")

	if clock.has_signal("time_updated"):
		clock.connect("time_updated", Callable(self, "_on_time_updated"))

func _on_time_updated(current_time: String) -> void:
	minute_counter += 1

	# Manage citizens time_to_live:
	for i in range(citizens.size() - 1, -1, -1):
		var c = citizens[i]
		if not is_instance_valid(c):
			citizens.remove_at(i)
			total_citizens -= 1
			continue
		c.time_to_live -= 1
		if c.time_to_live <= 0:
			c.queue_free()
			citizens.remove_at(i)
			total_citizens -= 1
			print("Citizen removed due to expired time_to_live")

	# Spawn new citizens every 60 minutes (if under max)
	if minute_counter >= 20:
		minute_counter = 0
		if total_citizens < max_citizens:
			var new_citizen = terrain.spawn_citizens()
			if new_citizen:
				citizens.append(new_citizen)
				total_citizens += 1
				new_citizen.go_gather("tree")
			print("Total citizens = ", total_citizens)
			print("Max = ", max_citizens)
		else:
			print("Max citizens reached. No new spawn.")


func increase_max_citizens(amount: int = 1) -> void:
	max_citizens += amount
	print("max_citizens increased to:", max_citizens)
