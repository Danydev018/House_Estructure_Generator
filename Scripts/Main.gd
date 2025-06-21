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

# Variables para handles de escalado  
var scale_handles_scene = preload("res://Scenes/ScaleHandles.tscn")  
var current_handles = null  
var is_scaling = false  
var scale_axis = ""  
var original_scale = Vector3.ONE

# Variables para escalado con handles  
var scale_start_position = Vector3.ZERO


func _ready():
	if raycast == null:
		print("❌ RayCast no encontrado.")
	else:
		print("✅ RayCast listo.")
		
	  
	selected_material = SpatialMaterial.new()  
	selected_material.albedo_color = Color(Color.green, 0.2) 


func _input(event):  
	if event is InputEventMouseButton:  
		if event.button_index == BUTTON_LEFT:  
			if event.pressed:  
				handle_left_click()  
			else:  
				if is_dragging:  
					finish_drag()  
				elif is_scaling:  
					finish_scaling()  
	  
	elif event is InputEventMouseMotion:  
		if is_dragging:  
			update_drag_position()  
		elif is_scaling:  
			update_scaling()
  
func handle_left_click():  
	var raycast = $Camera/RayCast  
	if raycast.is_colliding():  
		var collider = raycast.get_collider()  
		  
		# PRIMERO verificar si es un handle de escalado  
		if collider.name.begins_with("Handle") or (collider.get_parent() and collider.get_parent().name.begins_with("Handle")):  
			var handle_node = collider if collider.name.begins_with("Handle") else collider.get_parent()  
			start_scaling(handle_node.name, raycast.get_collision_point())  
		elif collider.get_parent().has_method("is_block"):  
			var block = collider.get_parent()  
			if selected_block == block:  
				start_drag(raycast.get_collision_point())  
			else:  
				select_block(block)  
		else:  
			# Solo colocar nuevo bloque si NO es un handle  
			place_new_block(raycast.get_collision_point())


#FUNCIONES PARA SELECCIONAR BLOQUE
func select_block(block):  
	# Deseleccionar bloque anterior  
	if selected_block != null:  
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")  
		mesh_instance.material_override = normal_material  
		# Remover handles anteriores  
		if current_handles != null:  
			current_handles.queue_free()  
	  
	# Seleccionar nuevo bloque  
	selected_block = block  
	var mesh_instance = block.get_node("StaticBody/MeshInstance")  
	mesh_instance.material_override = selected_material  
	  
	# Crear handles de escalado  
	show_scale_handles()
	
	
func place_new_block(collision_point):    
	var point = collision_point.snapped(Vector3.ONE)  
	# Añadir offset Y para evitar enterramiento  
	point.y += 0 # Media altura del cubo  
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
	# Calcular offset considerando la altura del cubo  
	var snapped_point = collision_point.snapped(Vector3.ONE)  
	snapped_point.y += 0  # Añadir offset de altura  
	drag_offset = selected_block.translation - snapped_point  
	  
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
		# Asegurar que el cubo no se entierre  
		new_position.y = max(new_position.y, 0)  # Mínimo Y = 0.5  
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
	
#FUNCIONES PARA ESCALAR CUBO
func show_scale_handles():  
	if selected_block == null:  
		return  
	  
	current_handles = scale_handles_scene.instance()  
	# Añadir como hijo de Main en lugar del cubo  
	add_child(current_handles)  
	  
	# Posicionar handles en coordenadas globales  
	var handle_x = current_handles.get_node("HandleX")  
	var handle_z = current_handles.get_node("HandleZ")  
	  
	var cube_pos = selected_block.global_transform.origin  
	handle_x.global_transform.origin = cube_pos + Vector3(selected_block.scale.x * 1.5, 1, 0)  
	handle_z.global_transform.origin = cube_pos + Vector3(0, 1, selected_block.scale.z * 1.5)
  
func hide_scale_handles():  
	if current_handles != null:  
		current_handles.queue_free()  
		current_handles = null
		
func start_scaling(handle_name, collision_point):  
	is_scaling = true  
	scale_axis = handle_name.replace("Handle", "").to_lower()  
	original_scale = selected_block.scale  
	scale_start_position = collision_point  
  
func update_scaling():  
	if not is_scaling or selected_block == null:  
		return  
	  
	var raycast = $Camera/RayCast  
	if raycast.is_colliding():  
		var current_position = raycast.get_collision_point()  
		var delta = current_position - scale_start_position  
		  
		if scale_axis == "x":  
			var scale_change = delta.x * 1
			selected_block.scale.x = clamp(original_scale.x + scale_change, 0.5, 30.0)  
		elif scale_axis == "z":  
			var scale_change = delta.z * 1
			selected_block.scale.z = clamp(original_scale.z + scale_change, 0.5, 30.0)  
		  
		# Actualizar handles en tiempo real  
		update_handles_position() 
  
func finish_scaling():  
	is_scaling = false  
	scale_axis = ""  
  
func update_handles_position():    
	if current_handles != null and selected_block != null:    
		var handle_x = current_handles.get_node("HandleX")    
		var handle_z = current_handles.get_node("HandleZ")    
			
		var cube_pos = selected_block.global_transform.origin    
		  
		# Margen dinámico: 20% del tamaño del cubo + distancia base  
		var dynamic_margin_x = selected_block.scale.x * 0.5 + 0.5  
		var dynamic_margin_z = selected_block.scale.z * 0.5 + 0.5  
		  
		var distance_x = selected_block.scale.x * 0.5 + dynamic_margin_x  
		var distance_z = selected_block.scale.z * 0.5 + dynamic_margin_z  
		  
		handle_x.global_transform.origin = cube_pos + Vector3(distance_x, 1, 0)   
		handle_z.global_transform.origin = cube_pos + Vector3(0, 1, distance_z)
		
#func _process(delta):
#	if raycast.is_colliding():
#		var collider = raycast.get_collider()
#		print("🎯 true: ", collider)
#	else:
#		print("❌ false")
