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
  
# Variables para doble clic    
var click_count = 0  
var last_click_time = 0.0    
var last_clicked_block = null    
var double_click_threshold = 0.3  # 300ms para doble clic    
  
# Variables para manejar la rotacion  
var rotation_handles_scene = preload("res://Scenes/RotationHandles.tscn")    
var current_rotation_handles = null    
var is_rotating = false    
var rotation_axis = ""  
  
# Variables de UI  
onready var delete_button = $CanvasLayer/DeleteButton  
onready var scale_slider = $CanvasLayer/ScaleSlider  
onready var create_button = $CanvasLayer/CreateButton
	  
func _ready():  
	if raycast == null:  
		print("❌ RayCast no encontrado.")  
	else:  
		print("✅ RayCast listo.")  
		  
	selected_material = SpatialMaterial.new()    
	selected_material.albedo_color = Color(Color.green, 0.2)   
	  
	# Conectar controles de UI  
	delete_button.connect("pressed", self, "_on_delete_button_pressed")  
	scale_slider.connect("value_changed", self, "_on_scale_slider_changed")  
	create_button.connect("pressed", self, "_on_create_button_pressed")
  
func _input(event):      
	if event is InputEventMouseButton:      
		if event.button_index == BUTTON_LEFT:      
			if event.pressed:      
				handle_left_click(event.position)  # Pasar posición del touch  
			else:      
				if is_dragging:      
					finish_drag()      
				elif is_rotating:      
					# Solo rotación de 90 grados    
					if rotation_axis == "HandleZPos":    
						selected_block.rotation_degrees.y += 90    
					elif rotation_axis == "HandleZNeg":    
						selected_block.rotation_degrees.y -= 90    
					update_rotation_handles_position()    
					finish_rotation()    
						
	elif event is InputEventMouseMotion:      
		if is_dragging:      
			update_drag_position(event.position)  # También pasar posición para drag
  
func handle_left_click(touch_position = null):          
	var camera = $Camera  
	var raycast = $Camera/RayCast  
	  
	# Si se proporciona posición de touch, usar raycast desde esa posición  
	if touch_position != null:  
		var from = camera.project_ray_origin(touch_position)  
		var to = from + camera.project_ray_normal(touch_position) * 100  
		  
		var space_state = get_world().direct_space_state  
		var result = space_state.intersect_ray(from, to)  
		  
		if result:  
			var collider = result.collider  
			var collision_point = result.position  
			process_collision(collider, collision_point)  
		# Si no hay colisión, no hacer nada (permitir movimiento de cámara)  
	else:  
		# Usar el raycast tradicional del crosshair  
		if raycast.is_colliding():          
			var collider = raycast.get_collider()          
			var collision_point = raycast.get_collision_point()  
			process_collision(collider, collision_point)  
  
func process_collision(collider, collision_point):  
	var current_time = OS.get_ticks_msec() / 1000.0        
		  
	# Handles de rotación    
	if collider.name.begins_with("HandleZ") or (collider.get_parent() and collider.get_parent().name.begins_with("HandleZ")):          
		var handle_node = collider if collider.name.begins_with("HandleZ") else collider.get_parent()          
		start_rotation(handle_node.name)      
		return    
			
	elif collider.get_parent().has_method("is_block"):          
		var block = collider.get_parent()          
		if selected_block == block:          
			# Verificar doble clic        
			if last_clicked_block == block and (current_time - last_click_time) < double_click_threshold:        
				deselect_block()        
			else:        
				start_drag(collision_point)          
		else:          
			select_block(block)          
				
		# Actualizar variables de doble clic        
		last_clicked_block = block        
		last_click_time = current_time
  
# FUNCIONES PARA SELECCIONAR BLOQUE  
func select_block(block):      
	# Deseleccionar bloque anterior      
	if selected_block != null:      
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")      
		mesh_instance.material_override = normal_material      
		# Remover handles de rotación anteriores    
		if current_rotation_handles != null:    
			current_rotation_handles.queue_free()    
		  
	# Seleccionar nuevo bloque      
	selected_block = block      
	var mesh_instance = block.get_node("StaticBody/MeshInstance")      
	mesh_instance.material_override = selected_material      
		  
	# Crear handles de rotación    
	show_rotation_handles()    
	  
	# Mostrar controles de UI  
	delete_button.visible = true  
	scale_slider.visible = true    
	scale_slider.value = selected_block.scale.x  # Sincronizar con escala actual  
	  
func deselect_block():      
	if selected_block != null:      
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")        
		mesh_instance.material_override = normal_material        
		  
		# Remover handles de rotación    
		if current_rotation_handles != null:    
			current_rotation_handles.queue_free()    
			current_rotation_handles = null    
			  
		selected_block = null    
		  
		# Ocultar controles de UI  
		delete_button.visible = false  
		scale_slider.visible = false  
  
func _on_scale_slider_changed(value):    
	if selected_block != null:    
		selected_block.scale.x = value  
  
func _on_delete_button_pressed():    
	if selected_block != null:    
		delete_block(selected_block)    
		delete_button.visible = false  

func _on_create_button_pressed():    
	# Crear bloque en el centro de la vista de la cámara  
	var camera = $Camera  
	var screen_center = get_viewport().size / 2  
	var from = camera.project_ray_origin(screen_center)  
	var to = from + camera.project_ray_normal(screen_center) * 100  
	  
	# Usar raycast para encontrar posición en el suelo  
	var space_state = get_world().direct_space_state  
	var result = space_state.intersect_ray(from, to)  
	  
	if result:  
		place_new_block(result.position)  
	else:  
		# Si no hay colisión, usar posición frente a la cámara  
		var forward_position = camera.global_transform.origin + camera.global_transform.basis.z * -5  
		place_new_block(forward_position)
	  
func place_new_block(position):        
	var point = position.snapped(Vector3.ONE)      
	point.y = max(point.y, 1)  # Asegurar que esté sobre el suelo  
	var block = block_scene.instance()        
	block.translation = point        
		
	# Establecer dimensiones de pared  
	block.scale = Vector3(3.0, 2.0, 0.5)  
		
	$BlocksContainer.add_child(block)        
		
	var mesh_instance = block.get_node("StaticBody/MeshInstance")        
	mesh_instance.material_override = normal_material
	
func delete_block(block):    
	if block == null:    
		return    
		
	# Si es el bloque seleccionado, deseleccionarlo primero    
	if selected_block == block:    
		deselect_block()    
		
	# Eliminar el bloque del contenedor    
	if block.get_parent() == $BlocksContainer:    
		block.queue_free()    
		
	# Resetear variables de clic    
	click_count = 0    
	last_clicked_block = null  
  
# FUNCIONES DE ARRASTRE  
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
	
func update_drag_position(touch_position = null):        
	if touch_position != null:  
		var camera = $Camera  
		var from = camera.project_ray_origin(touch_position)  
		var to = from + camera.project_ray_normal(touch_position) * 100  
		  
		var space_state = get_world().direct_space_state  
		var result = space_state.intersect_ray(from, to)  
		  
		if result:  
			var new_position = result.position.snapped(Vector3.ONE) + drag_offset      
			new_position.y = max(new_position.y, 0)  
			selected_block.translation = new_position  
	else:  
		# Usar raycast tradicional como fallback  
		var raycast = $Camera/RayCast        
		if raycast.is_colliding():        
			var new_position = raycast.get_collision_point().snapped(Vector3.ONE) + drag_offset      
			new_position.y = max(new_position.y, 0)  
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
  
# FUNCIONES PARA LA ROTACIÓN  
func start_rotation(handle_name):    
	if selected_block == null:    
		return    
	is_rotating = true  
	rotation_axis = handle_name  
  
func finish_rotation():    
	is_rotating = false    
	rotation_axis = ""  
  
func show_rotation_handles():    
	if selected_block == null:    
		return    
	current_rotation_handles = rotation_handles_scene.instance()    
	add_child(current_rotation_handles)    
	var cube_pos = selected_block.global_transform.origin    
	var scale = selected_block.scale  
	var up_vec = selected_block.global_transform.basis.y  
	var handle_z_pos = current_rotation_handles.get_node("HandleZPos")    
	var handle_z_neg = current_rotation_handles.get_node("HandleZNeg")    
	# Offset para Z positivo (más cercano)  
	var margin = 0.0  
	var offset_z = Vector3(0, 0, scale.z * 0.5 + margin)  
	offset_z = selected_block.global_transform.basis.xform(offset_z)  
	handle_z_pos.global_transform.origin = cube_pos + offset_z  
	handle_z_pos.look_at(cube_pos + selected_block.global_transform.basis.z, up_vec)  
	# Offset para Z negativo (más cercano)  
	var offset_z_neg = Vector3(0, 0, -scale.z * 0.5 - margin)  
	offset_z_neg = selected_block.global_transform.basis.xform(offset_z_neg)  
	handle_z_neg.global_transform.origin = cube_pos + offset_z_neg  
	handle_z_neg.look_at(cube_pos - selected_block.global_transform.basis.z, up_vec)  
  
func update_rotation_handles_position():  
	if current_rotation_handles != null and selected_block != null:  
		var handle_z_pos = current_rotation_handles.get_node("HandleZPos")  
		var handle_z_neg = current_rotation_handles.get_node("HandleZNeg")  
		var cube_pos = selected_block.global_transform.origin  
		var scale = selected_block.scale  
		var up_vec = selected_block.global_transform.basis.y  
		var margin = 0.0  
		# Offset para Z positivo (más cercano)  
		var offset_z = Vector3(0, 0, scale.z * 0.5 + margin)  
		offset_z = selected_block.global_transform.basis.xform(offset_z)  
		handle_z_pos.global_transform.origin = cube_pos + offset_z  
		handle_z_pos.look_at(cube_pos + selected_block.global_transform.basis.z, up_vec)  
		# Offset para Z negativo (más cercano)  
		var offset_z_neg = Vector3(0, 0, -scale.z * 0.5 - margin)  
		offset_z_neg = selected_block.global_transform.basis.xform(offset_z_neg)  
		handle_z_neg.global_transform.origin = cube_pos + offset_z_neg  
		handle_z_neg.look_at(cube_pos - selected_block.global_transform.basis.z, up_vec)
