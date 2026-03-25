# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label
## A label which shows the project version
##
## The version is determined from the project configuration, falling back to
## [code]git describe[/code] if necessary.


func _ready() -> void:
	text = preload("./version.gd").get_version()
