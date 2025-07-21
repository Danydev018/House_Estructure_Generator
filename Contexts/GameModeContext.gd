# cON

extends Node

signal game_mode_changed(game_mode)

const MODE_BUILD := "BUILD"
const MODE_PLACE := "PLACE"

export var game_mode := MODE_BUILD setget set_game_mode

func set_game_mode(value):
    game_mode = value
    emit_signal("game_mode_changed", game_mode)

func set_modo_build():
    set_game_mode(MODE_BUILD)

func set_modo_place():
    set_game_mode(MODE_PLACE)
