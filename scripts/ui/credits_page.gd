extends "res://scripts/ui/menu_page.gd"

func _ready() -> void:
	build_page("CREDITS")
	content.add_child(make_label("LIBERTAS VINCTA", "MenuText"))
	content.add_child(make_label("TEAM 4'S COMPLIMENT", "Small"))
	var roles := {"Sajib": "Design / Direction", "Ifat": "Assets", "Ramim": "Godot Implementation", "Tanvir": "Testing / Debugging"}
	for person in roles:
		content.add_child(make_label(person + "  /  " + roles[person]))
	content.add_child(make_label("ENGINE", "Small"))
	content.add_child(make_label("Godot 4.7.2"))
	content.add_child(make_label("EXTERNAL ASSETS", "Small"))
	content.add_child(make_label("Player art: AI-generated, supplied by the project owner; provenance accompanies the player assets.\n\nZombie sprites and Antons_Footsteps wood recordings: supplied by the project owner. Creator and license details have not been supplied.\n\nRepository icon: provenance remains unconfirmed. See ASSET_CREDITS.md for the source record."))
	content.add_child(make_label("AI-ASSISTED DEVELOPMENT", "Small"))
	content.add_child(make_label("AI tools assisted code implementation and player art creation. The team directs development and reviews the final game.", "Small"))
