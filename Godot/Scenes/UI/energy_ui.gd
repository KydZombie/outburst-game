class_name EnergyUI
extends HBoxContainer

@onready var energy_label: Label = $Energy/EnergyLabel

func update_energy(amount: int) -> void:
	if energy_label:
		energy_label.text = str(amount)
