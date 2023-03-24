extends Control

@onready var bloop_noise: AudioStreamPlayer = %BloopNoise
@onready var main_menu: Control = %Main
@onready var settings_menu: Control = %Settings
@onready var credits_menu: Control = %Credits

# Called when the node enters the scene tree for the first time.
func _ready():
	self._show_main_menu()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _hide_all():
	bloop_noise.play()
	main_menu.visible = false
	settings_menu.visible = false
	credits_menu.visible = false

func _show_main_menu():
	self._hide_all()
	self.main_menu.visible = true

func _show_settings_menu():
	self._hide_all()
	self.settings_menu.visible = true

func _show_credits_menu():
	self._hide_all()
	self.credits_menu.visible = true

# Start

func _start_game():
	get_tree().change_scene_to_file("res://main/main_game.tscn")

#
# Settings Menu Buttons
#

# Audio Stuff:

@onready var sfx_volume_out: Label = $Settings/SFXVolume/VolumeOut
@onready var ambiance_volume_out: Label = $Settings/AmbianceVolume/VolumeOut

const MASTER_BUS_INDEX: int = 0
const MIN_DB_VALUE: int = -60
const MAX_DB_VALUE:int = 10

func _db_to_percent(db_level:float) -> float:
	# Returns a value from 0-1, given a DB value within our acceptable range.
	# Adds also some bounds protection.
	return (max(min(db_level, MAX_DB_VALUE), MIN_DB_VALUE) - MIN_DB_VALUE) / (MAX_DB_VALUE - MIN_DB_VALUE)

func _update_sfx_volume(delta_volume:int):
	var volume_db = min(max(AudioServer.get_bus_volume_db(MASTER_BUS_INDEX)+delta_volume, MIN_DB_VALUE), MAX_DB_VALUE)
	AudioServer.set_bus_volume_db(MASTER_BUS_INDEX, volume_db)
	var percent = int(self._db_to_percent(volume_db) * 100)
	self.sfx_volume_out.text = str(percent) + "%"
	bloop_noise.play()

func _on_sfx_volume_down_pressed():
	self._update_sfx_volume(-5)

func _on_sfx_volume_up_pressed():
	self._update_sfx_volume(+5)

# Text Speed Stuff

func _set_text_speed_slow():
	StoryManager.time_between_characters = 0.05

func _set_text_speed_medium():
	StoryManager.time_between_characters = 0.01

func _set_text_speed_fast():
	StoryManager.time_between_characters = 0.005
