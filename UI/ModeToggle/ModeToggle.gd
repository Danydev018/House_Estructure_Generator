extends CheckButton

func _ready():
    connect("toggled", self, "_on_toggle_toggled")
    pressed = GameModeContext.game_mode == GameModeContext.MODE_BUILD

func _on_toggle_toggled(pressed):
    if pressed:
        GameModeContext.set_modo_build()
    else:
        GameModeContext.set_modo_place()
