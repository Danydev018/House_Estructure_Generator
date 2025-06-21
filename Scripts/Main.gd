extends Spatial

var block_scene = preload("res://Scenes/Block.tscn")

onready var raycast = $Camera/RayCast
onready var blocks_container = $BlocksContainer

# Variables para selección  
var selected_block = null  
var normal_material = null  
var selected_material = null

func _ready():
	if raycast == null:
		print("❌ RayCast no encontrado.")
	else:
		print("✅ RayCast listo.")
		
	# Crear materiales  
#	normal_material = SpatialMaterial.new()  
#	normal_material.albedo_color = Color.WHITE  
	  
	selected_material = SpatialMaterial.new()  
	selected_material.albedo_color = Color(Color.green, 0.2) 
#	selected_material.emission_enabled = true  
#	selected_material.emission = Color.YELLOW * 0.3

func _input(event):  
	if event is InputEventMouseButton and event.pressed:  
		if event.button_index == BUTTON_LEFT:  
			var raycast = $Camera/RayCast  
			if raycast.is_colliding():  
				var collider = raycast.get_collider()  
				  
				# Si el collider es un bloque existente, seleccionarlo  
				if collider.get_parent().has_method("is_block"):  
					select_block(collider.get_parent())  
				else:  
					# Si no es un bloque, colocar nuevo bloque  
					place_new_block(raycast.get_collision_point())

func select_block(block):  
	# Deseleccionar bloque anterior  
	if selected_block != null:  
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")  
		mesh_instance.material_override = normal_material  
	  
	# Seleccionar nuevo bloque  
	selected_block = block  
	var mesh_instance = block.get_node("StaticBody/MeshInstance")  
	mesh_instance.material_override = selected_material

func place_new_block(collision_point):  
	var point = collision_point.snapped(Vector3.ONE)  
	var block = block_scene.instance()  
	block.translation = point  
	$BlocksContainer.add_child(block)  
	  
	# Aplicar material normal al nuevo bloque  
	var mesh_instance = block.get_node("StaticBody/MeshInstance")  
	mesh_instance.material_override = normal_material
#func _input(event):
#	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
#		if raycast and raycast.is_colliding():
#			var block = block_scene.instance()
#			var point = raycast.get_collision_point().snapped(Vector3.ONE)
#			block.translation = point
#			blocks_container.add_child(block)
#			print("✅ Bloque colocado en: ", point)

#func _process(delta):
#	if raycast.is_colliding():
#		var collider = raycast.get_collider()
#		print("🎯 true: ", collider)
#	else:
#		print("❌ false")
