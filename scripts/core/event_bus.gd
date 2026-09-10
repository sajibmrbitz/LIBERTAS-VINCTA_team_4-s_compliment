extends Node

signal sense_restored(sense: String)
signal noise_created(world_position: Vector2, intensity: float, surface_type: String)
signal player_detected(source: Node)
signal player_hidden(hiding_spot_id: String)
signal player_left_hiding(hiding_spot_id: String)
signal player_caught
signal letter_collected(letter_id: String)
signal interaction_started(interactable: Node)
signal interaction_finished(interactable: Node)
signal flashlight_changed(enabled: bool)
signal ending_triggered(ending_type: String)
signal subtitle_requested(speaker: String, text: String, duration: float)
signal audio_requested(cue: String)
signal tension_changed(state: String)
