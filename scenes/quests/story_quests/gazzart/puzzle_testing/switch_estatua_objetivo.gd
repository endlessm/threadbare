# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name SwitchEstatuaObjetivo
extends Resource

@export var estatua_path: NodePath
@export_enum("up", "right", "down", "left") var direccion: String = "down"
