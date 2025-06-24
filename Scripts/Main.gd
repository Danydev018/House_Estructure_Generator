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
	
# Variables de UI    
onready var delete_button = $CanvasLayer/DeleteButton    
onready var scale_slider = $CanvasLayer/ScaleSlider    
onready var create_button = $CanvasLayer/CreateButton  
onready var rotate_button = $CanvasLayer/RotateButton  
  
func _ready():    
	if raycast == null:    
		print("❌ RayCast no encontrado.")    
	else:    
		print("✅ RayCast listo.")    
			
	# Cargar el material original    
	var original_material = preload("res://Materials/Block.tres")    
	# Crear una copia para selección con brillo    
	selected_material = original_material.duplicate()    
	selected_material.emission_enabled = true    
	selected_material.emission = Color(0.5, 0.5, 0.5)    
	# Ajustar intensidad según la plataforma    
	if OS.get_name() == "Android":    
		selected_material.emission_energy = 0.5  # Menos intenso en Android    
	else:    
		selected_material.emission_energy = 0.5  # Intensidad normal en PC  
		
	# Conectar controles de UI    
	delete_button.connect("pressed", self, "_on_delete_button_pressed")    
	scale_slider.connect("value_changed", self, "_on_scale_slider_changed")    
	create_button.connect("pressed", self, "_on_create_button_pressed")  
	rotate_button.connect("pressed", self, "_on_rotate_button_pressed")  
	  
	# Crear bloque de prueba automáticamente    
	var test_position = Vector3(0, 1, 0)  # Posición en el centro    
	var test_block = block_scene.instance()    
	test_block.translation = test_position    
	test_block.scale = Vector3(4.0, 3.5, 0.25)  # Dimensiones de pared    
	blocks_container.add_child(test_block)    
	# Seleccionar automáticamente el bloque de prueba    
	select_block(test_block)  
	
func _input(event):        
	if event is InputEventMouseButton:        
		if event.button_index == BUTTON_LEFT:        
			if event.pressed:  
				# Verificar si el clic fue en un elemento de UI  
				if is_click_on_ui(event.position):  
					return  # No procesar interacción con bloques  
					  
				# En PC, no pasar posición para usar el raycast tradicional  
				if OS.get_name() == "Android":  
					handle_left_click(event.position)  # Touch en móvil  
				else:  
					handle_left_click()  # Mouse en PC  
			else:        
				if is_dragging:        
					finish_drag()        
					  
	elif event is InputEventMouseMotion:        
		if is_dragging:        
			# Similar lógica para drag  
			if OS.get_name() == "Android":  
				update_drag_position(event.position)  
			else:  
				update_drag_position()   
	
func is_click_on_ui(click_position: Vector2) -> bool:  
	# Verificar si el clic está sobre algún botón visible  
	var ui_elements = [delete_button, create_button, rotate_button]  
	  
	for element in ui_elements:  
		if element.visible and element.get_global_rect().has_point(click_position):  
			return true  
	  
	return false
	
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
			
	if collider.get_parent().has_method("is_block"):            
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
			
	# Seleccionar nuevo bloque        
	selected_block = block        
	var mesh_instance = block.get_node("StaticBody/MeshInstance")        
	mesh_instance.material_override = selected_material        
		
	# Mostrar controles de UI    
	delete_button.visible = true    
	scale_slider.visible = true      
	scale_slider.value = selected_block.scale.x  # Sincronizar con escala actual    
	rotate_button.visible = true  # Mostrar botón de rotación  
		
func deselect_block():        
	if selected_block != null:        
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")          
		mesh_instance.material_override = normal_material          
		selected_block = null      
			
		# Ocultar controles de UI    
		delete_button.visible = false    
		scale_slider.visible = false    
		rotate_button.visible = false  # Ocultar botón de rotación  
	
func _on_scale_slider_changed(value):      
	if selected_block != null:      
		selected_block.scale.x = value    
	
func _on_delete_button_pressed():      
	if selected_block != null:      
		delete_block(selected_block)      
		delete_button.visible = false  
		
func _on_create_button_pressed():  
	var raycast = $Camera/RayCast  
	var crosshair = $CanvasLayer/Label  # El crosshair "+" 
	# Verificar si el raycast está detectando algo  
	if not raycast.is_colliding():  
		# Cambiar color del crosshair a rojo por 1 segundo  
		crosshair.modulate = Color.red  
		yield(get_tree().create_timer(1.0), "timeout")  
		crosshair.modulate = Color.white 
		return  # No hacer nada si no hay colisión  
	  
	var collider = raycast.get_collider()  
	var collision_point = raycast.get_collision_point()  
	  
	# Verificar si es el suelo usando diferentes métodos  
	var is_floor = false  
	  
	# Método 1: Por nombre del padre  
	if collider.get_parent().name == "Floor":  
		is_floor = true  
		crosshair.modulate = Color.green  
		yield(get_tree().create_timer(1.0), "timeout")  
		crosshair.modulate = Color.white  
	# Método 2: Por posición Y (el suelo debería estar en Y=0 o cerca)  
	elif collision_point.y <= 1.0:  
		is_floor = true 
	# Método 3: Por grupo (si agregas el suelo a un grupo)  
	elif collider.get_parent().is_in_group("floor"):  
		is_floor = true  
	  
	if is_floor:  
		place_new_block(collision_point) 

  
func _on_rotate_button_pressed():    
	if selected_block != null:    
		selected_block.rotation_degrees.y += 90  
		  
func place_new_block(position):          
	var point = position.snapped(Vector3.ONE)        
	# Colocar el bloque directamente en el suelo (Y=0)  
	point.y = 1.0  # Altura para que la base del bloque toque el suelo  
	var block = block_scene.instance()          
	block.translation = point          
		  
	# Establecer dimensiones de pared    
	block.scale = Vector3(5.0, 3.5, 0.25)    
		  
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
		
	# Calcular offset solo en X y Z, ignorar Y completamente    
	var snapped_point = collision_point.snapped(Vector3.ONE)        
	snapped_point.y = selected_block.translation.y  # Forzar misma altura    
	drag_offset = selected_block.translation - snapped_point        
	drag_offset.y = 0  # Eliminar cualquier componente Y del offset        
			
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
	var new_position    
		
	if touch_position != null:    
		var camera = $Camera    
		var from = camera.project_ray_origin(touch_position)    
		var to = from + camera.project_ray_normal(touch_position) * 100    
			
		var space_state = get_world().direct_space_state    
		var result = space_state.intersect_ray(from, to)    
			
		if result:    
			new_position = result.position.snapped(Vector3.ONE) + drag_offset        
		else:    
			return  # No hacer nada si no hay colisión    
	else:    
		var raycast = $Camera/RayCast          
		if raycast.is_colliding():          
			new_position = raycast.get_collision_point().snapped(Vector3.ONE) + drag_offset        
		else:    
			return    
		
	# Mantener SIEMPRE la altura original, sin excepciones    
	new_position.y = original_position.y    
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
  
# Botones de movimiento de cámara  
func _on_TextureButton_button_up():  
	Input.action_release("ui_up")  
  
func _on_TextureButton_button_down():  
	Input.action_press("ui_up")  
  
# Botones Derecha  
func _on_right_button_down():  
	Input.action_press("ui_right")  
  
func _on_right_button_up():  
	Input.action_release("ui_right")  
  
# Botones Izquierda  
func _on_left_button_down():  
	Input.action_press("ui_left")  
  
func _on_left_button_up():  
	Input.action_release("ui_left")  
  
# Botones Atras  
func _on_down_button_down():  
	Input.action_press("ui_down")  
  
func _on_down_button_up():  
	Input.action_release("ui_down")
