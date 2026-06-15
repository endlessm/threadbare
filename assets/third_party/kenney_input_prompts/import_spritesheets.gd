# Copyright 2024 iseesharp83
# Copyright 2025 The Threadbare Authors
# SPDX-License-Identifier: MIT
#
# Derived from
# https://bitbucket.org/iseesharp83workspace/kenney-spritesheet-importer-godot-plugin.
@tool
class_name KenneyImporter
extends EditorScript

const BASE_PATH := "res://assets/third_party/kenney_input_prompts"

# Keycodes outside the ASCII printable range
const NONPRINTABLES: Array[Key] = [
	Key.KEY_ALT,
	Key.KEY_ALT,
	Key.KEY_BACKSPACE,
	Key.KEY_CAPSLOCK,
	Key.KEY_CTRL,
	Key.KEY_DELETE,
	Key.KEY_END,
	Key.KEY_ENTER,
	Key.KEY_ESCAPE,
	Key.KEY_HOME,
	Key.KEY_INSERT,
	Key.KEY_KP_ADD,
	Key.KEY_KP_ENTER,
	Key.KEY_META,
	Key.KEY_PAGEDOWN,
	Key.KEY_PAGEUP,
	Key.KEY_PAUSE,
	Key.KEY_PRINT,
	Key.KEY_SHIFT,
	Key.KEY_TAB,
]

const GODOT_TO_KENNEY := {
	# ASCII printable range symbols are not all present in the spritesheet.
	# The missing ones cannot be typed without holding shift on a US English
	# keyboard, e.g. hash/numbersign. (But some of the present ones also can't be
	# typed without holding shift...)
	"Exclam": "exclamation",
	"QuoteDbl": "quote",
	"NumberSign": "",
	"Dollar": "",
	"Percent": "",
	"Ampersand": "",
	"ParenLeft": "",
	"ParenRight": "",
	"Slash": "slash_forward",
	"Less": "bracket_less",
	"Equal": "equals",
	"Greater": "bracket_greater",
	"At": "",
	"BracketLeft": "bracket_open",
	"BackSlash": "slash_back",
	"BracketRight": "bracket_close",
	"AsciiCircum": "caret",
	"UnderScore": "underscore",
	"QuoteLeft": "",
	"BraceLeft": "",
	"Bar": "",
	"BraceRight": "",
	"AsciiTilde": "tilde",
	# Non-printables
	"Kp Add": "numpad_plus",
	"Kp Enter": "numpad_enter",
	"Meta": "win",
	"PageDown": "page_down",
	"PageUp": "page_up",
	"Print": "printscreen",
}

const STEAM_DECK_BUTTONS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "button_a",
	JOY_BUTTON_B: "button_b",
	JOY_BUTTON_X: "button_x",
	JOY_BUTTON_Y: "button_y",
	JOY_BUTTON_BACK: "button_view",
	JOY_BUTTON_START: "button_options",
	JOY_BUTTON_LEFT_SHOULDER: "button_l1",
	JOY_BUTTON_RIGHT_SHOULDER: "button_r1",
}
const STEAM_DECK_TRIGGERS: Dictionary[JoyAxis, String] = {
	JOY_AXIS_TRIGGER_LEFT: "button_l2_outline",
	JOY_AXIS_TRIGGER_RIGHT: "button_r2_outline",
}

const PLAYSTATION_BUTTONS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "button_cross",
	JOY_BUTTON_B: "button_circle",
	JOY_BUTTON_X: "button_square",
	JOY_BUTTON_Y: "button_triangle",
	# Annoyingly these two buttons are different between PS3, PS4, PS5
	JOY_BUTTON_BACK: "playstation5_button_create",
	JOY_BUTTON_START: "playstation5_button_options",
	JOY_BUTTON_LEFT_SHOULDER: "trigger_l1_alternative",
	JOY_BUTTON_RIGHT_SHOULDER: "trigger_r1_alternative",
}
const PLAYSTATION_TRIGGERS: Dictionary[JoyAxis, String] = {
	JOY_AXIS_TRIGGER_LEFT: "trigger_l2_outline",
	JOY_AXIS_TRIGGER_RIGHT: "trigger_r2_outline",
}

const XBOX_BUTTONS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "button_a",
	JOY_BUTTON_B: "button_b",
	JOY_BUTTON_X: "button_x",
	JOY_BUTTON_Y: "button_y",
	JOY_BUTTON_BACK: "button_view",
	JOY_BUTTON_START: "button_menu",
	# Does not have button_ prefix.
	JOY_BUTTON_LEFT_SHOULDER: "lb",
	JOY_BUTTON_RIGHT_SHOULDER: "rb",
}
const XBOX_TRIGGERS: Dictionary[JoyAxis, String] = {
	JOY_AXIS_TRIGGER_LEFT: "lt_outline",
	JOY_AXIS_TRIGGER_RIGHT: "rt_outline",
}

const SWITCH_BUTTONS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "button_b",
	JOY_BUTTON_B: "button_a",
	JOY_BUTTON_X: "button_y",
	JOY_BUTTON_Y: "button_x",
	JOY_BUTTON_BACK: "button_minus",
	JOY_BUTTON_START: "button_plus",
	JOY_BUTTON_LEFT_SHOULDER: "button_l",
	JOY_BUTTON_RIGHT_SHOULDER: "button_r",
}
const SWITCH_TRIGGERS: Dictionary[JoyAxis, String] = {
	JOY_AXIS_TRIGGER_LEFT: "button_zl_outline",
	JOY_AXIS_TRIGGER_RIGHT: "button_zl_outline",
}


func tex(full_image: Texture2D, sprite: Dictionary) -> Texture2D:
	var texture := AtlasTexture.new()

	# The Sparrow/Kenney y-axis is inverted compared to Godot's
	var y: float = full_image.get_height() - (sprite.y + sprite.height)
	var region := Rect2(sprite.x, y, sprite.width, sprite.height)

	texture.atlas = full_image
	texture.region = Rect2(
		sprite.x, full_image.get_height() - (sprite.y + sprite.height), sprite.width, sprite.height
	)
	return texture


func import_keyboard(
	xml_name: String = "keyboard-&-mouse_sheet_default.xml",
	target_name: String = "keyboard.tres",
) -> void:
	var xml_atlas := read_kenney_sprite_sheet(BASE_PATH.path_join(xml_name))
	var target := BASE_PATH.path_join(target_name)
	var source_file: String = xml_atlas["imagePath"]

	var full_image: Texture2D = load(source_file)
	if not full_image:
		printerr("Failed to load image file: " + source_file)
		return

	var res: KeyboardMouseTextures
	if ResourceLoader.exists(target, "KeyboardMouseTextures"):
		res = ResourceLoader.load(target, "KeyboardMouseTextures")
	else:
		res = KeyboardMouseTextures.new()

	var sprites: Dictionary
	for sprite: Dictionary in xml_atlas.sprites:
		sprites[sprite.name] = sprite

	# The gap is the lowercase letters
	for keycode: int in range(32, 97) + range(123, 127) + NONPRINTABLES:
		var godot_name := OS.get_keycode_string(keycode)
		var kenney_name: String = GODOT_TO_KENNEY.get(godot_name, godot_name.to_lower())
		if kenney_name:
			res.keys[keycode] = tex(full_image, sprites["keyboard_%s_outline" % kenney_name])

	# Arrows need special care and feeding
	if not res.arrow_keys:
		res.arrow_keys = DirectionalInputTextures.new()
	res.arrow_keys.unpressed = tex(full_image, sprites["keyboard_arrows_none"])
	res.arrow_keys.up = tex(full_image, sprites["keyboard_arrows_up_outline"])
	res.arrow_keys.down = tex(full_image, sprites["keyboard_arrows_down_outline"])
	res.arrow_keys.left = tex(full_image, sprites["keyboard_arrows_left_outline"])
	res.arrow_keys.right = tex(full_image, sprites["keyboard_arrows_right_outline"])

	res.mouse_buttons[MouseButton.MOUSE_BUTTON_LEFT] = tex(
		full_image, sprites["mouse_left_outline"]
	)
	res.mouse_buttons[MouseButton.MOUSE_BUTTON_RIGHT] = tex(
		full_image, sprites["mouse_right_outline"]
	)
	res.mouse_buttons[MouseButton.MOUSE_BUTTON_MIDDLE] = tex(
		full_image, sprites["mouse_scroll_outline"]
	)

	save_resource(target, res)


func import_controller(
	xml_name: String,
	prefix: String,
	buttons: Dictionary[JoyButton, String],
	triggers: Dictionary[JoyAxis, String],
) -> void:
	print_rich("[i]%s[/i]" % [prefix])

	var target_name := prefix + ".tres"
	var xml_atlas := read_kenney_sprite_sheet(BASE_PATH.path_join(xml_name))
	var target := BASE_PATH.path_join(target_name)
	var source_file: String = xml_atlas["imagePath"]

	var full_image: Texture2D = load(source_file)
	if not full_image:
		printerr("Failed to load image file: " + source_file)
		return

	var sprites: Dictionary
	for sprite: Dictionary in xml_atlas.sprites:
		sprites[sprite.name] = sprite

		# Shorthand for easy labels
		if sprite.name.begins_with(prefix + "_"):
			sprites[sprite.name.right(-(prefix.length() + 1))] = sprite

	var res: JoypadTextures
	if ResourceLoader.exists(target, "JoypadTextures"):
		res = ResourceLoader.load(target, "JoypadTextures")
	else:
		res = JoypadTextures.new()

	for button: JoyButton in buttons:
		var kenney_name := "%s_outline" % [buttons[button]]
		res.buttons[button] = tex(full_image, sprites[kenney_name])
	res.buttons[JOY_BUTTON_LEFT_STICK] = tex(full_image, sprites["stick_l_press"])
	res.buttons[JOY_BUTTON_RIGHT_STICK] = tex(full_image, sprites["stick_r_press"])

	if not res.dpad:
		res.dpad = DirectionalInputTextures.new()
	res.dpad.unpressed = tex(full_image, sprites["dpad_none"])
	res.dpad.left = tex(full_image, sprites["dpad_left_outline"])
	res.dpad.right = tex(full_image, sprites["dpad_right_outline"])
	res.dpad.up = tex(full_image, sprites["dpad_up_outline"])
	res.dpad.down = tex(full_image, sprites["dpad_down_outline"])

	if not res.left_stick:
		res.left_stick = DirectionalInputTextures.new()
	res.left_stick.unpressed = tex(full_image, sprites["stick_l"])
	res.left_stick.left = tex(full_image, sprites["stick_l_left"])
	res.left_stick.right = tex(full_image, sprites["stick_l_right"])
	res.left_stick.up = tex(full_image, sprites["stick_l_up"])
	res.left_stick.down = tex(full_image, sprites["stick_l_down"])

	if not res.right_stick:
		res.right_stick = DirectionalInputTextures.new()
	res.right_stick.unpressed = tex(full_image, sprites["stick_r"])
	res.right_stick.left = tex(full_image, sprites["stick_r_left"])
	res.right_stick.right = tex(full_image, sprites["stick_r_right"])
	res.right_stick.up = tex(full_image, sprites["stick_r_up"])
	res.right_stick.down = tex(full_image, sprites["stick_r_down"])

	for trigger_axis in triggers:
		var glyph := triggers[trigger_axis]
		res.triggers[trigger_axis] = tex(full_image, sprites[glyph])

	save_resource(target, res)


func save_resource(name: String, texture: Resource) -> bool:
	var status := ResourceSaver.save(texture, name)
	if status != OK:
		printerr("Failed to save resource " + name)
		return false
	return true


func read_kenney_sprite_sheet(source_file: String) -> Dictionary:
	var atlas: Dictionary
	var sprites: Array[Dictionary]
	var parser := XMLParser.new()
	if OK == parser.open(source_file):
		var read := parser.read()
		if read == OK:
			atlas["sprites"] = sprites
		while read != ERR_FILE_EOF:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT:
				var node_name := parser.get_node_name()
				match node_name:
					"TextureAtlas":
						atlas["imagePath"] = source_file.get_base_dir().path_join(
							parser.get_named_attribute_value("imagePath")
						)
					"SubTexture":
						var sprite := {}
						sprite["name"] = parser.get_named_attribute_value("name")
						sprite["x"] = float(parser.get_named_attribute_value("x"))
						sprite["y"] = float(parser.get_named_attribute_value("y"))
						sprite["width"] = float(parser.get_named_attribute_value("width"))
						sprite["height"] = float(parser.get_named_attribute_value("height"))
						sprites.append(sprite)
			read = parser.read()
	return atlas


func _run() -> void:
	print_rich("[b]Reticulating splines…[/b]")
	import_keyboard()
	import_controller(
		"steam-deck_sheet_default.xml", "steamdeck", STEAM_DECK_BUTTONS, STEAM_DECK_TRIGGERS
	)
	import_controller(
		"playstation-series_sheet_default.xml",
		"playstation",
		PLAYSTATION_BUTTONS,
		PLAYSTATION_TRIGGERS
	)
	import_controller("xbox-series_sheet_default.xml", "xbox", XBOX_BUTTONS, XBOX_TRIGGERS)
	import_controller(
		"nintendo-switch_sheet_default.xml", "switch", SWITCH_BUTTONS, SWITCH_TRIGGERS
	)
	print_rich("[b]Done![/b]")
