# Contexto del Proyecto — "Los Fragmentos del Soñador" (StoryQuest en Threadbare)

> Documento para pegar en un chat nuevo de Claude (web). Resume TODO lo necesario
> para ayudarnos a prototipar 3 minijuegos en Godot lo más rápido posible.
> Última actualización: 2026-06-04.

---

## 0. TL;DR (lee esto primero)

- Hacemos un **StoryQuest** llamado **"Los Fragmentos del Soñador"** dentro de
  **Threadbare**, un juego open-source de Endless Access hecho en **Godot 4.6
  (renderer GL Compatibility)**.
- Equipo: **DreamMakers** (5 personas). Quest no-canónica.
- **Meta inmediata: prototipos jugables de 3 minijuegos.**
- **HALLAZGO CLAVE:** NO partimos de cero. Threadbare ya trae las 3 mecánicas como
  scripts reutilizables (`SequencePuzzle`, `FillGameLogic`, `StealthGameLogic`), y
  nuestra quest **ya está scaffoldeada** (copia del template) con los árboles de
  nodos funcionales. El trabajo real es **re-tematizar al estilo onírico + ajustar
  mecánicas a la narrativa**, no inventar sistemas nuevos.
- Carpeta de la quest:
  `scenes/quests/story_quests/los_fragmentos_del_s/`

---

## 1. Narrativa (GDD condensado)

**Premisa:** un protagonista sin memoria despierta en un sueño en descomposición.
El **Soñador** —ser que sostenía el mundo soñándolo— desapareció, y los sueños se
quebraron en fragmentos. El jugador reconstruye los fragmentos sin saber que **él
mismo es uno de los sueños perdidos** (giro final).

**Personajes:**
- **Protagonista:** sin nombre ni recuerdos. La mirada del jugador.
- **El Soñador:** ausente. Solo voz, eco, presencia indirecta.
- **Los Buscadores:** criaturas con linternas que detectan recuerdos perdidos. No
  son guardias, son sensores. Si te encuentran, te marcan como "intruso".
- **La Tormenta Negra:** sueño olvidado que persigue al protagonista. Solo consume.

**Estructura narrativa:** Intro → Minijuego 1 → Minijuego 2 → Minijuego 3 → Outro.
Cada minijuego entrega un **fragmento / núcleo de sueño**. Al unir los tres se abre
el último recuerdo y arranca el outro con el plot twist.

**Justificación diegética de cada mecánica** (importante para el diseño):
- Los **sonidos** son ecos de recuerdos → el jugador los repite porque reconstruye memorias.
- Las **gotas oscuras** son corrupción que pudre los recuerdos → el jugador las
  devuelve y llena jarrones de energía de sueños.
- Los **Buscadores** detectan recuerdos perdidos → el jugador los evita porque él
  mismo es, sin saberlo, un recuerdo perdido.

---

## 2. Estética

- **Arte:** ilustración pintada a mano, paletas oníricas. Sueño 1: azules pálidos,
  violetas suaves, dorados tenues. Sueño 2: grises azulados, ocres apagados, negros
  profundos. Siluetas flotantes, partículas suspendidas, luz difusa (como ver a
  través de agua).
- **Música:** introspectiva, campanas de cristal, cuerdas pulsadas, motivos breves
  recurrentes. En el nivel 2, los mismos temas a media velocidad con disonancias.
- **SFX:** ecos y susurros; hilos vibrando; chirrido metálico de las linternas;
  gotas en cámara lenta con eco grave; latido sordo de la Tormenta Negra.

---

## 3. Los 3 minijuegos

> Nota: el GDD numera por **orden narrativo**; las carpetas del repo usan otro orden
> (ver sección 5). Lo aclaro en cada uno.

### Minijuego 1 — "Ecos de Memoria" (puzle musical)
- **Escenario (mockup `1MINIGAME.png`):** claro flotante en el cielo nocturno
  violeta. **6 campanas grandes** colgando alrededor de un círculo rúnico dorado;
  el protagonista en el centro; notas musicales flotando; luna creciente. Vista
  isométrica/aérea.
- **Objetivo:** completar secuencias musicales para restaurar el recuerdo y obtener
  el **Fragmento 1**.
- **Mecánica:** estilo "Simon/memoria". El escenario reproduce una secuencia de
  notas en las campanas; el jugador la repite. Las secuencias crecen (3 → 4 → 5).
  Cada secuencia completada reconstruye visualmente el entorno (hilos que se tensan).
- **Mapea a:** `SequencePuzzle` + `SequencePuzzleStep` + `SequencePuzzleObject`
  (campanas = objetos de secuencia; carteles = hint signs).

### Minijuego 2 — "Sombras en el Agua" (corrupción + sigilo + persecución)
- **Escenario (mockup `2MINIGAME.png`):** sueño amplio, suelo de piedra,
  **jarrones/linternas de cristal** alineados, gotas oscuras cayendo, conos de luz
  de los Buscadores barriendo. Al fondo, un rostro/horizonte negro: la Tormenta.
- **Objetivo:** limpiar corrupción llenando jarrones, evitar la luz de los
  Buscadores y escapar de la Tormenta → **Fragmento 2**.
- **Mecánicas (3 sistemas):**
  1. **Combate por timing:** golpear gotas oscuras con la espada las revierte y
     llena un jarrón cercano.
  2. **Sigilo:** evitar el cono de luz de los Buscadores; si te detectan, reinicias el sector.
  3. **Persecución final:** aparece la Tormenta; el jugador usa la tela (hilos del
     sueño) para engancharse a puntos altos y huir.
- **Mapea a:** `FillGameLogic` (jarrones = `FillingBarrel`, gotas = `Projectile` /
  `ThrowingEnemy`) + `StealthGameLogic` (Buscadores = `Guard` con `player_detected`).

### Minijuego 3 — "El Sueño Abandonado" (las 3 mecánicas combinadas + plot twist)
- **Escenario (mockup `3MINIGAME.png`):** el segundo sueño, más viejo. Muros
  agrietados, hilos rotos, luz amarillenta y polvorienta, **altar central** con tres
  núcleos de sueño (rosa/azul/dorado) sobre gradas circulares. Versión triste del
  tema del Minijuego 1 (media velocidad, disonancias).
- **Objetivo:** usar las 3 mecánicas para alcanzar 3 núcleos y unirlos en el altar
  central → abre el recuerdo final → Outro.
- **Mecánicas:** tres zonas, una por mecánica:
  - **Núcleo 1:** puzle musical extendido; las notas se "olvidan" (desaparecen) si tardas.
  - **Núcleo 2:** corrupción intensa; gotas más rápidas y varios jarrones a la vez.
  - **Núcleo 3:** sigilo avanzado; varios Buscadores en patrones cruzados.
- **Mapea a:** combinación de los tres sistemas anteriores en una sola escena.

---

## 4. La base técnica (Threadbare)

- **Motor:** Godot **4.6**, `config/features = ("4.6", "GL Compatibility")`.
- **Lenguaje:** GDScript. **Todo el código y comentarios en inglés** (convención del
  proyecto upstream).
- **Licencias (REUSE):** código original = **MPL-2.0**; assets = **CC-BY-SA-4.0**.
  Cada archivo nuevo necesita encabezado SPDX, p. ej.:
  ```gdscript
  # SPDX-FileCopyrightText: The Threadbare Authors
  # SPDX-License-Identifier: MPL-2.0
  ```
- **Git LFS:** assets grandes (música, arte) van por LFS. Configurar LFS antes de clonar.
- **Diálogos:** archivos `.dialogue` (addon **Dialogue Manager**).
- **Escena principal del juego:** `run/main_scene = uid://huuo8mnwsphv`.

### Scripts de lógica reutilizables (`scenes/game_logic/`)
Estos son los ladrillos. **No reescribir; reusar.**

- `sequence_puzzle.gd` → `class_name SequencePuzzle extends Node2D`
  - Señales: `solved`, `step_solved(step_index)`.
  - Auto-descubre nodos `SequencePuzzleStep` hijos (orden depth-first).
  - Auto-descubre objetos del grupo `&"sequence_object"` (tipo `SequencePuzzleObject`).
  - Cada objeto emite `kicked` al interactuar; el script valida contra `step.sequence`.
  - `interactive_hints: bool`, `debug: bool`. Métodos: `is_solved()`, `get_progress()`.
- `sequence_puzzle_step.gd` → cada paso tiene `sequence: Array[SequencePuzzleObject]`
  y un `hint_sign`.
- `fill_game_logic.gd` → `class_name FillGameLogic extends Node`
  - Señal: `goal_reached`. `@export barrels_to_win`, `@export autostart`.
  - Grupos usados: `"filling_barrels"` (tipo `FillingBarrel`, con `label`/`color`),
    `"throwing_enemy"` (tipo `ThrowingEnemy`), `"projectiles"`.
  - Asigna a cada enemigo qué `label`/`color` puede lanzar según los jarrones vivos.
  - `start()` arranca; al completar `barrels_to_win` emite `goal_reached`.
  - Tutorial upstream: github.com/endlessm/threadbare/discussions/1323
- `stealth_game_logic.gd` → `class_name StealthGameLogic extends Node` (`@tool`)
  - Conecta cada `Guard` del grupo `&"guard_enemy"` a `player_detected`.
  - Al detectar, llama `player.defeat()`.
- Otros útiles: `throw_projectile_behavior.gd`, `talk_behavior.gd`,
  `walk_behaviors/`, `camera_behaviors/`, `light2d_behaviors/`, `player_mode.gd`.

### Minijuego de referencia ya terminado
`scenes/eternal_loom_sokoban/` — un minijuego sokoban completo (levels + components +
`.dialogue`). Útil como ejemplo de cómo se ensambla un minijuego de principio a fin.

---

## 5. Estado ACTUAL de nuestra quest (lo más importante)

Carpeta: `scenes/quests/story_quests/los_fragmentos_del_s/`

Ya existe scaffolding (copia del `template_quest`) con **5 escenas** y árboles de
nodos **ya funcionales**. Orden de carpetas:

```
los_fragmentos_del_s/
├── quest.tres                      # definición de la quest
├── player_components/              # .tres del player de la quest
├── tiles/                          # ~12 tilesets propios (water, foam, grass, void, etc.)
├── 0_intro/        los_fragmentos_del_s_intro.tscn        + intro.dialogue
├── 1_stealth/      los_fragmentos_del_s_stealth.tscn      (Buscadores)
├── 2_combat/       los_fragmentos_del_s_combat.tscn       (gotas/jarrones = fill)
├── 3_sequence_puzzle/ los_fragmentos_del_s_sequence_puzzle.tscn  (musical)
└── 4_outro/        los_fragmentos_del_s_outro.tscn        + outro.dialogue
```

> ⚠️ El orden de carpetas (stealth → combat → puzzle) **no** coincide con el orden
> narrativo del GDD (musical → sombras → abandonado). Decidir si reordenamos para que
> el flujo del jugador siga la historia.

**Qué trae cada escena hoy (ya armadas, no vacías):**

- **`3_sequence_puzzle` (≈160 líneas):** TileMaps (water/foam/grass/sand), Player con
  Camera2D, un `SequencePuzzle` con **6 objetos** (Blue/Pink/Yellow/Green/Purple/Red),
  **2 HintSigns**, **2 Steps**, `CollectibleItem` (el fragmento) y un `Sign`.
- **`2_combat` (≈133 líneas):** `PlayerMode`, `Cinematic`, `FillGameLogic`, TileMaps,
  Player, `ThrowingNPC`, **6 Targets** (jarrones), `CollectibleItem`, `RepelPowerup`,
  `HUD`, Camera2D.
- **`1_stealth` (≈130 líneas):** `StealthGameLogic`, `CanvasModulate` (oscuridad),
  TileMaps, Player+Camera, **2 Guards** con `Path2D` de patrulla, `Checkpoint`, `HUD`,
  `CollectibleItem`, `Cinematic`.

**Conclusión:** los "prototipos" base ya corren con la mecánica genérica del template.
Lo que falta para que sean **nuestros prototipos**:

1. **Re-tematización visual** al estilo onírico (tiles, paletas, partículas, las
   campanas reales en vez de objetos genéricos, jarrones de cristal, linternas de Buscadores).
2. **Ajuste de mecánicas a la narrativa** (secuencias 3→4→5; notas que se olvidan en
   el M3; gotas como corrupción; conos de luz; persecución de la Tormenta).
3. **Diálogos** (`.dialogue`) con las líneas de la Voz del Soñador del GDD.
4. **Conexión narrativa** entre escenas (transiciones, entrega de fragmentos, altar final).
5. **Audio** (campanas, ecos, latido de la Tormenta).
6. **Persecución de la Tormenta Negra** (mecánica de tela/gancho) — esta es la pieza
   menos cubierta por los scripts existentes; revisar si hay un behavior de hook/grapple.

---

## 6. Cómo correr / probar

- Abrir el proyecto con **Godot 4.6** (carpeta raíz con `project.godot`).
- Para probar un minijuego aislado: abrir su `.tscn` y darle "Run Current Scene" (F6).
- Convenciones del repo: `.pre-commit-config.yaml` (hooks), `.editorconfig`, REUSE.
- **No** buildear tras cada cambio; probar escenas individuales es más rápido.

---

## 7. Plan sugerido de prototipos (orden de ataque)

Priorizar por menor riesgo / mayor cobertura existente:

1. **Minijuego 1 (musical)** — el más autocontenido y ya casi completo. Ajustar a
   secuencias 3→4→5, mapear los 6 objetos a campanas con nota/SFX, validar `solved`
   → entrega del Fragmento 1. **Mejor punto de partida.**
2. **Minijuego 2 (fill)** — usar `FillGameLogic` con 6 jarrones; gotas como
   `ThrowingEnemy`; afinar timing del combate. Dejar el sigilo y la persecución de la
   Tormenta como capas siguientes.
3. **Sigilo** — `StealthGameLogic` ya conecta guards; ajustar patrullas, conos de luz
   y reinicio de sector.
4. **Persecución de la Tormenta Negra** — investigar mecánica de gancho/tela (lo menos
   resuelto). Prototipar aparte antes de integrar.
5. **Minijuego 3** — recién al final: combinar las 3 mecánicas + altar + plot twist.

---

## 8. Preguntas abiertas para decidir

- ¿Reordenamos las carpetas para seguir el orden narrativo del GDD?
- ¿Existe ya un behavior de gancho/tela para la persecución, o lo construimos?
- ¿Hasta qué fidelidad visual llega el "prototipo" (placeholder vs. arte final)?
- ¿La Tormenta Negra es escena propia o fase final dentro del Minijuego 2?

---

## 9. Archivos clave (rutas para referencia rápida)

```
project.godot                                   # Godot 4.6, GL Compatibility
scenes/game_logic/sequence_puzzle.gd            # mecánica musical
scenes/game_logic/sequence_puzzle_step.gd
scenes/game_logic/fill_game_logic.gd            # mecánica corrupción/jarrones
scenes/game_logic/stealth_game_logic.gd         # mecánica Buscadores
scenes/eternal_loom_sokoban/                     # minijuego de referencia completo
scenes/quests/story_quests/los_fragmentos_del_s/ # NUESTRA quest (ya scaffoldeada)
docs-grupo/EQUIPO 4 ... GDD ... .pdf/.docx       # GDD completo
docs-grupo/1MINIGAME.png / 2MINIGAME.png / 3MINIGAME.png  # mockups
docs-grupo/INTRO.png / OUTRO.png / OUTRO-2.png   # mockups intro/outro
```
</content>
</invoke>
