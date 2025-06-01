extends PopupPanel

func show_citizen_info(citizen):
	# Status boxes
	var home_label = $VBoxContainer/HBoxContainer/HomeLabel
	var job_label = $VBoxContainer/HBoxContainer/JobLabel
	var age_label = $VBoxContainer/HBoxContainer/AgeLabel

	home_label.text = "[no home]" if citizen.house_position == Vector2i.ZERO else "[has a home]"
	job_label.text = "[has a job]" if (citizen.is_gathering or citizen.is_returning_home) else "[no work]"
	age_label.text = "Age: %ds" % citizen.get_age_seconds()

	# Progress bars
	$VBoxContainer/HungerBar.value = citizen.hunger
	$VBoxContainer/ThirstBar.value = citizen.thirst
	$VBoxContainer/SleepBar.value = citizen.sleep
	$VBoxContainer/BerryBar.value = citizen.berries
