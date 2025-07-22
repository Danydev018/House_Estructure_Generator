extends CanvasLayer

var modo_actual = "" # "color" o "textura"

func _ready():
	# Si quieres centrar el label puedes usar esto, aunque ya no es tan necesario aquí
	var size = get_viewport().size
	$Label.rect_position = size / 2 - $Label.rect_size / 2
	
	# Opcional: oculta los paneles al iniciar
	$Panel.visible = false
	$Panel2.visible = false
	
	 # Verificar si la conexión ya existe antes de conectar
	if not $Panel2/boton_quitar_textura.is_connected("pressed", self, "_on_boton_quitar_textura_pressed"):
		$Panel2/boton_quitar_textura.connect("pressed", self, "_on_boton_quitar_textura_pressed")

func _on_TextureButton2_pressed():
	# Mostrar u ocultar el menú principal
	$Panel.visible = not $Panel.visible
	$Panel2.visible = false # Por si acaso cerrar el submenú


func _on_CambiarColor_pressed():
	modo_actual = "color"
	mostrar_submenu("color")


func _on_CambiarTextura_pressed():
	modo_actual = "textura"
	mostrar_submenu("textura")


func mostrar_submenu(modo):
	$Panel2.visible = true
	
	if modo == "color":
		$Panel2/Label.text = "Selecciona el color"
		$Panel2/OptionButton.visible = false
		$Panel2/ColorPickerButton.visible = true
	else:
		$Panel2/Label.text = "Selecciona la textura"
		$Panel2/OptionButton.visible = true
		$Panel2/ColorPickerButton.visible = false
		$Panel2/OptionButton.clear()
		$Panel2/OptionButton.add_item("Ladrillo")
		$Panel2/OptionButton.add_item("Madera")
		$Panel2/OptionButton.add_item("Piedra")


func _on_Aplicar_pressed():
	if bloque_seleccionado == null:
		print("No hay bloque seleccionado")
		$Panel2.visible = false
		$Panel.visible = false
		return

	var mesh = bloque_seleccionado.get_node("StaticBody/MeshInstance")
	
	if modo_actual == "color":
		var nuevo_color = $Panel2/ColorPickerButton.color
		
		# Clonar el material para no afectar a todos los bloques
		var original_material = mesh.get_surface_material(0)
		var nuevo_material = original_material.duplicate()
		nuevo_material.albedo_color = nuevo_color
		mesh.set_surface_material(0, nuevo_material)
		
	elif modo_actual == "textura":
		var opcion = $Panel2/OptionButton.selected
		var textura: Texture
		
		match opcion:
			0:
				textura = preload("res://assets/ceramicav.jpg")
			1:
				textura = preload("res://assets/Wood051_1K-JPG_Color.jpg")
			2:
				textura = preload("res://assets/maderita.jpg")
			_:
				print("Opción de textura no válida")
				$Panel2.visible = false
				$Panel.visible = false
				return
		
		# Crear nuevo material con la textura
		var nuevo_material = SpatialMaterial.new()
		nuevo_material.albedo_texture = textura
		nuevo_material.emission_enabled = true
		nuevo_material.emission = Color(1,1,1)*0.2
		
		mesh.set_surface_material(0, nuevo_material)
	
	else:
		print("Modo no reconocido")

	# Cerrar menús
	$Panel2.visible = false
	$Panel.visible = false
var bloque_seleccionado= null


func set_bloque(bloque):
	bloque_seleccionado = bloque




func _on_boton_quitar_textura_pressed():
	if bloque_seleccionado == null:
		return

	var mesh_instance = bloque_seleccionado.get_node("StaticBody/MeshInstance")
	
	# 1. Crear un material NUEVO (no reutilizar el mismo)
	var material_limpio = SpatialMaterial.new()
	material_limpio.albedo_color = Color(1, 1, 1)  # Blanco
	material_limpio.albedo_texture = null          # Sin textura
	material_limpio.metallic = 0.0
	material_limpio.roughness = 0.8
	
	# 2. Aplicar solo al bloque seleccionado (como material único)
	mesh_instance.set_surface_material(0, material_limpio)
	
	# 3. Actualizar en main.gd (para mantener la selección)
	if get_parent().has_method("actualizar_material_bloque"):
		get_parent().actualizar_material_bloque(bloque_seleccionado, material_limpio)
	
	# Cerrar menús
	$Panel2.visible = false
	$Panel.visible = false
