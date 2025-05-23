extends Node

func IsInGame() -> bool:
	return get_tree().current_scene.name == "main_scene"
