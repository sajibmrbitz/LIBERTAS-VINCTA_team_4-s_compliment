extends "res://scripts/ui/menu_page.gd"
@export var atmosphere_texture: Texture2D
const STORY_COPY := "Els Vantree, a locksmith hired for a private appraisal at Hollowmere Estate, wakes on the foyer floor with no memory of entering.\n\nShe remembers the offer — far too generous to refuse.\nShe remembers signing the contract without reading the addendum.\n\nThe next six hours are gone.\n\nSomewhere inside Hollowmere, three sealed keys wait behind locks older than the estate itself.\n\nEvery lock Els opens gives her a way forward.\n\nNot every freedom she recovers belongs to her."

func _ready() -> void:
	build_page("STORY")
	var layout: VBoxContainer = $PageLayout
	layout.anchor_top = 0.07
	layout.anchor_bottom = 0.96
	layout.add_theme_constant_override("separation", 8)
	content.add_theme_constant_override("separation", 10)
	var metadata := make_label("HOLLOWMERE ESTATE  /  2:47 A.M.", "Small")
	layout.add_child(metadata)
	layout.move_child(metadata, 1)
	var divider: HSeparator = layout.get_child(2)
	divider.add_theme_stylebox_override("separator", get_theme_stylebox("grabber_area", "HSlider"))
	content.add_child(make_label(STORY_COPY, "StoryBody"))
	content.add_child(HSeparator.new())
	content.add_child(make_label("Freedom is never destroyed.\nIt only changes hands.", "NarrativeAccent"))
	$PageAtmosphereTexture.texture = atmosphere_texture
