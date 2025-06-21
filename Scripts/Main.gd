extends Spatial

var block_scene = preload("res://Scenes/Block.tscn")

onready var raycast = $Camera/RayCast
onready var blocks_container = $BlocksContainer

func _ready():
	if raycast == null:
		print("❌ RayCast no encontrado.")
	else:
		print("✅ RayCast listo.")

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if raycast and raycast.is_colliding():
			var block = block_scene.instance()
			var point = raycast.get_collision_point().snapped(Vector3.ONE)
			block.translation = point
			blocks_container.add_child(block)
			print("✅ Bloque colocado en: ", point)

func _process(delta):
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		print("🎯 true: ", collider)
	else:
		print("❌ false")
