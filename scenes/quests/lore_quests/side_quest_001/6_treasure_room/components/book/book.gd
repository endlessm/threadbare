# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

signal book_read

var already_read: bool = false

func reveal_thread():
	if not already_read:
		already_read = true
		book_read.emit()
