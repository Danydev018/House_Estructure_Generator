extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func highlight(active: bool):
	if active:
		$MeshInstance.material_override = preload("res://Materials/HighlightMaterial.tres")
	else:
		$MeshInstance.material_override = null
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func is_block():  
	return true
