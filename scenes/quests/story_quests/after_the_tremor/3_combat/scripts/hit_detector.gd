# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var golpes_para_morir := 8
var golpes := 0

func _on_area_entered(area):
	golpes += 1
	print("Golpe detectado! Total:", golpes)

	var boss_parent := get_parent()
	if not boss_parent:
		return

	var barrel := boss_parent.get_node_or_null("FillingBarrel")
	if barrel and is_instance_valid(barrel):
		# cada golpe incrementa 1 en el barrel (usa API pública)
		barrel.increment(1)

	if golpes >= golpes_para_morir:
		print("JEFE DERROTADO")
		boss_parent.queue_free()
