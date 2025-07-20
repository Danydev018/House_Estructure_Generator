extends Control

# Referencia al nodo principal
onready var main_scene = get_parent()

# Botones de save/load
onready var save_button: Button
onready var load_button: Button
onready var status_label: Label

func _ready():
	print("📱 SaveLoadUI inicializado")
	
	# Crear botones si no existen
	create_ui_elements()
	
	# Conectar señales
	connect_signals()

func create_ui_elements():
	# Crear contenedor si no existe
	var container = VBoxContainer.new()
	container.name = "SaveLoadContainer"
	
	# Posicionar en la esquina superior derecha
	container.anchor_left = 1.0
	container.anchor_top = 0.0
	container.anchor_right = 1.0 
	container.anchor_bottom = 0.0
	container.margin_left = -120
	container.margin_top = 10
	container.margin_right = -10
	container.margin_bottom = 100
	
	add_child(container)
	
	# Crear botón de guardado
	save_button = Button.new()
	save_button.text = "💾 Guardar"
	save_button.rect_min_size = Vector2(100, 30)
	container.add_child(save_button)
	
	# Crear botón de carga
	load_button = Button.new()
	load_button.text = "📥 Cargar"
	load_button.rect_min_size = Vector2(100, 30)
	container.add_child(load_button)
	
	# Crear label de estado
	status_label = Label.new()
	status_label.text = "Listo"
	status_label.align = Label.ALIGN_CENTER
	container.add_child(status_label)
	
	print("✅ Elementos de UI creados")

func connect_signals():
	# Conectar botones
	save_button.connect("pressed", self, "_on_save_pressed")
	load_button.connect("pressed", self, "_on_load_pressed")
	
	# Conectar señales del SupabaseManager si existe
	if main_scene.has_node("SupabaseManager"):
		var supabase_manager = main_scene.get_node("SupabaseManager")
		supabase_manager.connect("scene_saved", self, "_on_scene_saved")
		supabase_manager.connect("scene_loaded", self, "_on_scene_loaded")
		supabase_manager.connect("error_occurred", self, "_on_error")
	
	print("🔗 Señales conectadas")

func _on_save_pressed():
	print("💾 Botón de guardado presionado")
	update_status("Guardando...", Color.yellow)
	
	# Deshabilitar botón temporalmente
	save_button.disabled = true
	
	if main_scene.has_method("manual_save"):
		main_scene.manual_save()
	else:
		update_status("Error: método manual_save no encontrado", Color.red)
		save_button.disabled = false

func _on_load_pressed():
	print("📥 Botón de carga presionado")
	update_status("Cargando...", Color.yellow)
	
	# Deshabilitar botón temporalmente
	load_button.disabled = true
	
	if main_scene.has_method("manual_load"):
		main_scene.manual_load()
	else:
		update_status("Error: método manual_load no encontrado", Color.red)
		load_button.disabled = false

func _on_scene_saved(success: bool):
	save_button.disabled = false
	
	if success:
		update_status("✅ Guardado exitoso", Color.green)
		# Ocultar mensaje después de 2 segundos
		yield(get_tree().create_timer(2.0), "timeout")
		update_status("Listo", Color.white)
	else:
		update_status("❌ Error al guardar", Color.red)

func _on_scene_loaded(scene_data: Dictionary):
	load_button.disabled = false
	
	if not scene_data.empty():
		var block_count = scene_data.get("blocks", []).size()
		update_status("✅ Cargado: " + str(block_count) + " bloques", Color.green)
		# Ocultar mensaje después de 2 segundos
		yield(get_tree().create_timer(2.0), "timeout")
		update_status("Listo", Color.white)
	else:
		update_status("ℹ️ No hay datos guardados", Color.orange)

func _on_error(error_message: String):
	save_button.disabled = false
	load_button.disabled = false
	update_status("❌ " + error_message, Color.red)

func update_status(message: String, color: Color = Color.white):
	if status_label:
		status_label.text = message
		status_label.modulate = color
		print("📱 Estado UI: ", message)
