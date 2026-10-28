# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ElHiloQueNoTejiIdiomas
extends RefCounted
## Traducciones de esta StoryQuest. El texto original está en español; el .po en español repite
## ese mismo texto, para que en español no se use el inglés como idioma de respaldo.

const TRADUCCIONES: Array[Translation] = [
	preload("../locale/el_hilo_que_no_teji_es.po"),
	preload("../locale/el_hilo_que_no_teji_en.po"),
	preload("../locale/el_hilo_que_no_teji_fr.po"),
]
const DIALOGO_FRASES: DialogueResource = preload("../dialogues/dialogos_frases.dialogue")

static var _registradas: bool = false


## Carga las traducciones una sola vez. Cada escena de la quest la llama al empezar.
static func registrar() -> void:
	if _registradas:
		return
	_registradas = true
	for traduccion in TRADUCCIONES:
		TranslationServer.add_translation(traduccion)


## Texto de una línea de dialogos_frases.dialogue en el idioma actual. Se pide justo cuando
## se va a mostrar, para que un cambio de idioma a mitad de partida se note en la siguiente.
static func frase(titulo: String) -> String:
	return await texto_de(DIALOGO_FRASES, titulo)


## Texto de la primera línea de un título de cualquier .dialogue, en el idioma actual.
static func texto_de(dialogo: DialogueResource, titulo: String) -> String:
	var linea: DialogueLine = await dialogo.get_next_dialogue_line(titulo)
	return linea.text if linea else ""
