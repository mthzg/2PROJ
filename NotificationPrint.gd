extends Node

var notifications_node: Control = null

func _ready():
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func _on_node_added(node):
	if node.name == "Notifications":
		notifications_node = node

func notify_print(message: String, timer: float = 15.0):
	print(message) # Still prints to terminal for debugging
	if notifications_node:
		notifications_node.notify(message, timer)
	else:
		var notif = get_tree().root.find_node("Notifications", true, false)
		if notif:
			notifications_node = notif
			notifications_node.notify(message, timer)
