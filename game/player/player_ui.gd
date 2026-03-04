extends CanvasLayer

@onready var player = $".."

func _process(_delta: float) -> void:
	$Label.text = "Sneakiness: " + str(player.sneakiness * 100.0) + "%"
