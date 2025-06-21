extends Spatial

var block_scene = preload("res://Scenes/Block.tscn")

onready var raycast = $Camera/RayCast
onready var blocks_container = $BlocksContainer

# Variables para selección  
var selected_block = null  
var normal_material = null  
var selected_material = null

# Variables para arrastre  
var is_dragging = false  
var drag_offset = Vector3.ZERO  
var original_position = Vector3.ZERO

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
	if event is InputEventMouseButton:  
		if event.button_index == BUTTON_LEFT:  
			if event.pressed:  
				handle_left_click()  
			else:  
				# Soltar el arrastre  
				if is_dragging:  
					finish_drag()  
	  
	elif event is InputEventMouseMotion and is_dragging:  
		update_drag_position()  
  
func handle_left_click():  
	var raycast = $Camera/RayCast  
	if raycast.is_colliding():  
		var collider = raycast.get_collider()  
		  
		if collider.get_parent().has_method("is_block"):  
			var block = collider.get_parent()  
			if selected_block == block:  
				# Iniciar arrastre del bloque ya seleccionado  
				start_drag(raycast.get_collision_point())  
			else:  
				# Seleccionar nuevo bloque  
				select_block(block)  
		else:  
			# Colocar nuevo bloque  
			place_new_block(raycast.get_collision_point())


#func _input(event):  
#	if event is InputEventMouseButton and event.pressed:  
#		if event.button_index == BUTTON_LEFT:  
#			var raycast = $Camera/RayCast  
#			if raycast.is_colliding():  
#				var collider = raycast.get_collider()  
#
#				# Si el collider es un bloque existente, seleccionarlo  
#				if collider.get_parent().has_method("is_block"):  
#					select_block(collider.get_parent())  
#				else:  
#					# Si no es un bloque, colocar nuevo bloque  
#					place_new_block(raycast.get_collision_point())

#FUNCIONES PARA SELECCIONAR BLOQUE
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

#FUNCIONES DE ARRASTRE
func start_drag(collision_point):  
	is_dragging = true  
	original_position = selected_block.translation  
	drag_offset = selected_block.translation - collision_point.snapped(Vector3.ONE)  
	  
	# Cambiar material para indicar arrastre  
	var drag_material = SpatialMaterial.new()  
	drag_material.albedo_color = Color.cyan 
	drag_material.emission_enabled = true  
	drag_material.emission = Color.cyan * 0.5  
	drag_material.flags_transparent = true  
	drag_material.albedo_color.a = 0.7  
	  
	var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")  
	mesh_instance.material_override = drag_material  
  
func update_drag_position():  
	var raycast = $Camera/RayCast  
	if raycast.is_colliding():  
		var new_position = raycast.get_collision_point().snapped(Vector3.ONE) + drag_offset  
		selected_block.translation = new_position  
  
func finish_drag():  
	is_dragging = false  
	  
	# Verificar si la posición final es válida  
	if is_valid_position(selected_block.translation):  
		# Restaurar material de selección  
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")  
		mesh_instance.material_override = selected_material  
	else:  
		# Revertir a posición original si no es válida  
		selected_block.translation = original_position  
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")  
		mesh_instance.material_override = selected_material  
  
func is_valid_position(position):  
	# Verificar que no haya otro bloque en esa posición  
	for child in $BlocksContainer.get_children():  
		if child != selected_block and child.translation.distance_to(position) < 0.5:  
			return false  
	return true
#func _process(delta):
#	if raycast.is_colliding():
#		var collider = raycast.get_collider()
#		print("🎯 true: ", collider)
#	else:
#		print("❌ false")
