# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

var llaves = 0

func _ready():
	
	$KeysCollectText.text = "0/3"

func handleKeyCollector(llaves_actuales: int, llaves_maximas: int):
	print("Key Collected - UI Updated")
	llaves = llaves_actuales
	$KeysCollectText.text = str(llaves_actuales) + "/" + str(llaves_maximas)
