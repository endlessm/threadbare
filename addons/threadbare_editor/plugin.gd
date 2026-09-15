# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ThreadbareEditorPlugin
extends EditorPlugin

const ThreadbareDebugger := preload("res://addons/threadbare_editor/threadbare_debugger.gd")
const QuestTranslationParser := preload(
	"res://addons/threadbare_editor/quest_translation_parser.gd"
)

var threadbare_debugger: EditorDebuggerPlugin
var quest_translation_parser: EditorTranslationParserPlugin


func _enter_tree() -> void:
	threadbare_debugger = ThreadbareDebugger.new()
	add_debugger_plugin(threadbare_debugger)

	quest_translation_parser = QuestTranslationParser.new()
	add_translation_parser_plugin(quest_translation_parser)


func _exit_tree() -> void:
	if threadbare_debugger:
		remove_debugger_plugin(threadbare_debugger)
		threadbare_debugger = null

	if quest_translation_parser:
		remove_translation_parser_plugin(quest_translation_parser)
		quest_translation_parser = null
