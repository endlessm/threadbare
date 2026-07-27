# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends AnimatedSprite2D

func play_default():
	play("default")
	
func play_walk1():
	play("walk_right")
	
func play_steady2():
	play("steady_left")
