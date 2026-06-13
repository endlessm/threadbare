# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

# For dialogue etc.
@onready var musician_quest_unlocker: QuestProgressUnlocker = %MusicianQuestUnlocker
@onready var guarded_stones_unlocker: QuestProgressUnlocker = %GuardedStonesUnlocker
@onready var oops_all_inkdrinkers_unlocker: QuestProgressUnlocker = %OopsAllInkDrinkersUnlocker

# TODO: demodulate & fix houses as more song sanctuary quests are completed?
