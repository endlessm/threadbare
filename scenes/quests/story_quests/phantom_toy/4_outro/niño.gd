# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends AnimatedSprite2D

func play_idle():
	play("idle")

func play_walk():
	play("walk")

func play_left():
	play("left")
