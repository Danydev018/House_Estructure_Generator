extends CanvasLayer

func _ready():
	var size = get_viewport().size
	$Label.rect_position = size / 2 - $Label.rect_size / 2
	
	
