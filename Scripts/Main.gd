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

# Agregar estas variables al inicio del script  
var click_count = 0
var last_click_time = 0.0  
var last_clicked_block = null  
var double_click_threshold = 0.3  # 300ms para doble clic  

#Variables para manejar la rotacion
var rotation_handles_scene = preload("res://Scenes/RotationHandles.tscn")  
var current_rotation_handles = null  
var is_rotating = false  
var rotation_axis = ""
var rotation_start_angle = 0.0
var rotation_start_mouse = Vector2.ZERO

# Variables para distinguir clic de arrastre en rotación
var rotation_mouse_down_pos = Vector2.ZERO
var rotation_click_threshold = 8.0 # píxeles


# Agregar después de las variables existentes  
onready var delete_button = $CanvasLayer/DeleteButton
	
func _ready():
	if raycast == null:
		print("❌ RayCast no encontrado.")
	else:
		print("✅ RayCast listo.")
		
	  
	selected_material = SpatialMaterial.new()  
	selected_material.albedo_color = Color(Color.green, 0.2) 
	# Conectar botón de eliminación  
	delete_button.connect("pressed", self, "_on_delete_button_pressed")

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
				elif is_rotating:  
					# Solo rotación de 90 grados
					if rotation_axis == "HandleZPos":
						selected_block.rotation_degrees.y += 90
					elif rotation_axis == "HandleZNeg":
						selected_block.rotation_degrees.y -= 90
					update_rotation_handles_position()
					update_handles_position()
					finish_rotation()
	elif event is InputEventMouseMotion:  
		if is_dragging:  
			update_drag_position()  
		elif is_scaling:  
			update_scaling()  
		elif is_rotating:  
			update_rotation()


  
# Modificar handle_left_click()  
# Modificar la función handle_left_click()  
func handle_left_click():      
	var raycast = $Camera/RayCast      
	if raycast.is_colliding():      
		var collider = raycast.get_collider()      
		var current_time = OS.get_ticks_msec() / 1000.0    
		  
		# Handles de rotación
		if collider.name.begins_with("HandleZ") or (collider.get_parent() and collider.get_parent().name.begins_with("HandleZ")):      
			var handle_node = collider if collider.name.begins_with("HandleZ") else collider.get_parent()      
			start_rotation(handle_node.name)  
			return
		# Handles de escalado
		if collider.name.begins_with("HandleX") or (collider.get_parent() and collider.get_parent().name.begins_with("HandleX")):      
			var handle_node = collider if collider.name.begins_with("HandleX") else collider.get_parent()      
			start_scaling(handle_node.name, raycast.get_collision_point())  
			return
		elif collider.get_parent().has_method("is_block"):      
			var block = collider.get_parent()      
			if selected_block == block:      
				# Verificar doble clic    
				if last_clicked_block == block and (current_time - last_click_time) < double_click_threshold:    
					deselect_block()    
				else:    
					start_drag(raycast.get_collision_point())      
			else:      
				select_block(block)      
				
			# Actualizar variables de doble clic    
			last_clicked_block = block    
			last_click_time = current_time    
		else:      
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
		# Remover handles de rotación anteriores  
		if current_rotation_handles != null:  
			current_rotation_handles.queue_free()  
		
	# Seleccionar nuevo bloque    
	selected_block = block    
	var mesh_instance = block.get_node("StaticBody/MeshInstance")    
	mesh_instance.material_override = selected_material    
		
	# Crear handles de escalado    
	show_scale_handles()  
	# Crear handles de rotación  
	show_rotation_handles()  
	# Mostrar botón de eliminación    
	delete_button.visible = true
	
func deselect_block():    
	if selected_block != null:    
		var mesh_instance = selected_block.get_node("StaticBody/MeshInstance")      
		mesh_instance.material_override = normal_material      
		# Remover handles de escalado  
		if current_handles != null:      
			current_handles.queue_free()    
			current_handles = null  
		# Remover handles de rotación  
		if current_rotation_handles != null:  
			current_rotation_handles.queue_free()  
			current_rotation_handles = null  
		selected_block = null  
		# Ocultar botón de eliminación    
		delete_button.visible = false

func _on_delete_button_pressed():  
	if selected_block != null:  
		delete_block(selected_block)  
		delete_button.visible = false
	
func place_new_block(collision_point):      
	var point = collision_point.snapped(Vector3.ONE)    
	point.y += 0   
	var block = block_scene.instance()      
	block.translation = point      
	  
	# Establecer dimensiones de pared (ejemplo: ancho=3, altura=2, grosor=0.5)  
	block.scale = Vector3(3.0, 2.0, 0.5)  # X=ancho, Y=altura, Z=grosor  
	  
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
	add_child(current_handles)    
	
	var handle_x = current_handles.get_node("HandleX")    
	var handle_x_neg = current_handles.get_node("HandleXNeg")    
	
	var cube_pos = selected_block.global_transform.origin
	var scale = selected_block.scale
	var up_vec = selected_block.global_transform.basis.y
	var margin = 0.0

	# Offset para X positivo (constante)
	var offset_x = Vector3((scale.x * 0.5) + margin, 0, 0)
	offset_x = selected_block.global_transform.basis.xform(offset_x)
	handle_x.global_transform.origin = cube_pos + offset_x
	handle_x.look_at(cube_pos + selected_block.global_transform.basis.x, up_vec)

	# Offset para X negativo (constante)
	var offset_x_neg = Vector3((-scale.x * 0.5) - margin, 0, 0)
	offset_x_neg = selected_block.global_transform.basis.xform(offset_x_neg)
	handle_x_neg.global_transform.origin = cube_pos + offset_x_neg
	handle_x_neg.look_at(cube_pos - selected_block.global_transform.basis.x, up_vec)

func hide_scale_handles():  
	if current_handles != null:  
		current_handles.queue_free()  
		current_handles = null
		
func start_scaling(handle_name, collision_point):    
	is_scaling = true    
	if handle_name == "HandleX":  
		scale_axis = "x_pos"  
	elif handle_name == "HandleXNeg":  
		scale_axis = "x_neg"  
	original_scale = selected_block.scale    
	scale_start_position = collision_point  
  

func update_scaling():    
	if not is_scaling or selected_block == null:    
		return    
	var raycast = $Camera/RayCast    
	if raycast.is_colliding():    
		var current_position = raycast.get_collision_point()    
		var delta = current_position - scale_start_position    
		var local_delta = selected_block.global_transform.basis.xform_inv(delta)
		var sensitivity = 0.2 # Menor sensibilidad
		if scale_axis == "x_pos":    
			var scale_change = local_delta.x * sensitivity
			selected_block.scale.x = clamp(original_scale.x + scale_change, 0.5, 30.0)    
		elif scale_axis == "x_neg":    
			var scale_change = -local_delta.x * sensitivity  # Invertir dirección    
			selected_block.scale.x = clamp(original_scale.x + scale_change, 0.5, 30.0)    
		update_handles_position()

  
func finish_scaling():  
	is_scaling = false  
	scale_axis = ""  
  
func update_handles_position():      
	if current_handles != null and selected_block != null:      
		var handle_x = current_handles.get_node("HandleX")      
		var handle_x_neg = current_handles.get_node("HandleXNeg")      
		
		var cube_pos = selected_block.global_transform.origin      
		var scale = selected_block.scale
		var up_vec = selected_block.global_transform.basis.y
		var margin = 0.0
		# Offset para X positivo (constante)
		var offset_x = Vector3((scale.x * 0.5) + margin, 0, 0)
		offset_x = selected_block.global_transform.basis.xform(offset_x)
		handle_x.global_transform.origin = cube_pos + offset_x
		handle_x.look_at(cube_pos + selected_block.global_transform.basis.x, up_vec)
		# Offset para X negativo (constante)
		var offset_x_neg = Vector3((-scale.x * 0.5) - margin, 0, 0)
		offset_x_neg = selected_block.global_transform.basis.xform(offset_x_neg)
		handle_x_neg.global_transform.origin = cube_pos + offset_x_neg
		handle_x_neg.look_at(cube_pos - selected_block.global_transform.basis.x, up_vec)

	#Funciones para la rotacion
func start_rotation(handle_name):  
	if selected_block == null:  
		return  
	is_rotating = true
	rotation_axis = handle_name

func update_rotation():
	pass

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
# warning-ignore:unused_argument

#func _process(delta):
#	if raycast.is_colliding():
#		var collider = raycast.get_collider()
#		print("🎯 true: ", collider)
#	else:
#		print("❌ false")
