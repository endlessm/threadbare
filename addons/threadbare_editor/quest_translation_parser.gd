# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorTranslationParserPlugin
## Extracts the translatable strings of a [Quest] resource.
##
## A [Quest] is a custom resource, so by default is not recognized by the translation system.
## This parser makes it possible, so adding a quest.tres to the list of translatable
## files puts its title and description in the catalog.

const TITLE_COMMENT := "Quest title"
const DESCRIPTION_COMMENT := "Quest description"


func _get_recognized_extensions() -> PackedStringArray:
	return ["tres"]


func _parse_file(path: String) -> Array[PackedStringArray]:
	var messages: Array[PackedStringArray] = []

	# Skip .tres files that aren't Quests.
	var quest := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Quest
	if not quest:
		return messages

	if quest.title:
		messages.append(PackedStringArray([quest.title, "", "", TITLE_COMMENT]))
	if quest.description:
		messages.append(PackedStringArray([quest.description, "", "", DESCRIPTION_COMMENT]))

	return messages
