# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends VBoxContainer

@export var studio: CreditsStudio:
	set = set_studio

## Scene to instantiate to display each team in [member studio]. Should have a
## [code]team[/code] property of type [CreditsTeam].
@export var team_view_scene: PackedScene

var _team_views: Array[Node]

@onready var _title: Label = %Title
@onready var _logo: TextureRect = %Logo
@onready var _description: RichTextLabel = %Description


func _ready() -> void:
	set_studio(studio)


func set_studio(new_value: CreditsStudio) -> void:
	studio = new_value

	if not is_node_ready():
		return

	for s in _team_views:
		remove_child(s)
		s.queue_free()
	_team_views.clear()

	if not studio:
		_title.text = ""
		_logo.texture = null
		_logo.visible = false
		_description.text = ""
		_description.visible = false
		return

	_title.text = studio.name
	_logo.texture = studio.logo
	_logo.visible = studio.logo != null
	if studio.description:
		_description.text = studio.description
		_description.visible = true
	else:
		_description.visible = false

	if studio.roster:
		for team: CreditsTeam in studio.roster.teams:
			var team_view := team_view_scene.instantiate()
			team_view.team = team
			add_child(team_view)
			_team_views.append(team_view)
