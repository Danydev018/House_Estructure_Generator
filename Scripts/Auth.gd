extends Control

# Señales para notificar el resultado de la autenticación
signal login_successful
signal registration_successful

# Nodos de la UI
onready var email_input = $VBoxContainer/EmailInput
onready var password_input = $VBoxContainer/PasswordInput
onready var login_button = $VBoxContainer/LoginButton
onready var register_button = $VBoxContainer/RegisterButton
onready var status_label = $VBoxContainer/StatusLabel

# Referencia al SupabaseManager
onready var supabase_manager = get_node("/root/Main/SupabaseManager")

func _ready():
	# Conectar botones a sus funciones
	login_button.connect("pressed", self, "_on_login_button_pressed")
	register_button.connect("pressed", self, "_on_register_button_pressed")
	
	# Conectar señales del SupabaseManager
	supabase_manager.connect("login_succeeded", self, "_on_login_succeeded")
	supabase_manager.connect("login_failed", self, "_on_login_failed")
	supabase_manager.connect("signup_succeeded", self, "_on_signup_succeeded")
	supabase_manager.connect("signup_failed", self, "_on_signup_failed")
	
	status_label.text = ""

func _on_login_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	if email.empty() or password.empty():
		status_label.text = "Email y contraseña no pueden estar vacíos."
		return
		
	status_label.text = "Iniciando sesión..."
	login_button.disabled = true
	register_button.disabled = true
	supabase_manager.sign_in(email, password)

func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	if not email.is_valid_email():
		status_label.text = "Por favor, introduce un email válido."
		return
	
	if password.length() < 6:
		status_label.text = "La contraseña debe tener al menos 6 caracteres."
		return
		
	status_label.text = "Registrando..."
	login_button.disabled = true
	register_button.disabled = true
	supabase_manager.sign_up(email, password)

# Callbacks de SupabaseManager
func _on_login_succeeded(user_data):
	status_label.text = "¡Login exitoso!"
	print("Usuario autenticado: ", user_data.user.email)
	emit_signal("login_successful")
	# La escena principal se encargará de ocultar esta UI

func _on_login_failed(error_message):
	status_label.text = "Error de login: " + error_message
	login_button.disabled = false
	register_button.disabled = false

func _on_signup_succeeded():
	status_label.text = "¡Registro exitoso! Revisa tu email para confirmar."
	login_button.disabled = false
	register_button.disabled = false
	emit_signal("registration_successful")

func _on_signup_failed(error_message):
	status_label.text = "Error de registro: " + error_message
	login_button.disabled = false
	register_button.disabled = false
