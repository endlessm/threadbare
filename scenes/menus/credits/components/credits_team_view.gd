# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CreditsTeamView
extends VBoxContainer

@export var team: CreditsTeam:
	set = set_team

@onready var title_ribbon: PanelContainer = %TitleRibbon
@onready var title: Label = %Title
@onready var logo: TextureRect = %Logo
@onready var body: RichTextLabel = %Body


func _ready() -> void:
	set_team(team)


static func _format_member(data: Dictionary) -> String:
	if data.get("GitHub Username") and data.get("Name"):
		return "[url=https://github.com/{GitHub Username}]{Name}[/url]".format(data)

	if data.get("GitHub Username"):
		return "[url=https://github.com/{GitHub Username}]@{GitHub Username}[/url]".format(data)

	if data.get("Name"):
		return data["Name"]

	return str(data)


func set_team(new_value: CreditsTeam) -> void:
	team = new_value

	if not team or not is_node_ready():
		return

	title_ribbon.visible = not team.name.is_empty()
	logo.visible = team.logo != null
	logo.texture = team.logo
	title.text = team.name

	var members := "\n".join(team.members.map(_format_member))
	var body_text: String
	if team.description:
		body_text = (team.description + "\n\n" + body_text)
	else:
		body_text = members

	body.text = body_text.strip_edges()
