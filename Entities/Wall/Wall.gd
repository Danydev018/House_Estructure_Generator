extends Spatial

func _ready():
	pass

func highlight(active: bool):
	if active:
		$MeshInstance.material_override = preload("res://Materials/HighlightMaterial.tres")
	else:
		$MeshInstance.material_override = null

func is_block():  
	return true
