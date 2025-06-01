extends Control

func notify(message: String, timer: float = 15.0):
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	$VBoxContainer.add_child(label)

	var t = Timer.new()
	t.wait_time = timer
	t.one_shot = true
	add_child(t)
	t.connect("timeout", func():
		if is_instance_valid(label):
			label.queue_free()
		t.queue_free()
	)
	t.start()
