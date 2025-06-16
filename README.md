# Threadbare

THREADBARE es un proyecto desarrollado en Godot Engine. Este documento describe la estructura del proyecto y el propósito de cada carpeta y archivo principal, para facilitar la comprensión y la realización de cambios sin afectar su funcionamiento.

[Play it here!](https://endlessm.github.io/threadbare/)

## License

Threadbare's original source code in Threadbare itself is covered by [Mozilla
Public License Version 2.0](./COPYING).

Threadbare's original assets are covered by [Creative Commons
Attribution-ShareAlike 4.0 International](./LICENSES/CC-BY-SA-4.0.txt).

Threadbare includes third-party assets and addons that are covered by different
licenses. Using the [REUSE](https://reuse.software/) specification, all files in
the repository are labelled with their license in a machine-readable way,
through a combination of comments in the files themselves, supplementary
`.license` files, and [REUSE.toml](./REUSE.toml).
<!--
SPDX-FileCopyrightText: The Threadbare Authors
SPDX-License-Identifier: MPL-2.0
-->

---

## Estructura del Proyecto

### 1. `addons/`
Contiene complementos (addons) de Godot que amplían la funcionalidad del editor o del juego.

- **dialogue_manager/**  
  Sistema para gestionar diálogos, árboles de conversación, localización y lógica relacionada.
  - **components/**: Scripts reutilizables para la interfaz y lógica del editor de diálogos.
  - **compiler/**: Scripts que validan y procesan los archivos de diálogo.
  - **l10n/**: Archivos de localización para traducir el addon a varios idiomas.
  - **views/**: Scripts de las vistas principales del editor de diálogos.
  - **plugin.gd**: Script principal que registra el addon en Godot.
  - **settings.gd**: Configuración y utilidades del addon.
  - **import_plugin.gd**: Permite importar archivos de diálogo externos.

> Modifica aquí si necesitas cambiar cómo se crean, editan o procesan los diálogos del juego.

---

### 2. `assets/`
Recursos gráficos, sonidos, fuentes, animaciones, etc.

> Modifica aquí si agregas o cambias imágenes, sonidos, música, etc.

---

### 3. `build/`
Archivos generados automáticamente o temporales para la construcción y distribución del juego.

> No es necesario modificar manualmente.

---

### 4. `linux/`
Recursos o scripts específicos para la plataforma Linux.

> Solo relevante si vas a exportar o correr el juego en Linux.

---

### 5. `scenes/`
Contiene las escenas principales del juego (niveles, menús, UI, etc.).

> Modifica aquí si agregas, editas o reorganizas niveles, menús o interfaces.

## Mecánica de Movimiento del Personaje

La lógica de movimiento del personaje en los mapas se encuentra principalmente en los siguientes archivos:

*   **`scenes/game_elements/characters/player/player.tscn`**: Escena principal del jugador.
*   **`scenes/game_elements/characters/player/components/player.gd`**: Script que controla el movimiento del jugador, la entrada del usuario, las animaciones y las interacciones.

Dentro de `player.gd`:

*   La función `_physics_process(delta)` es donde se maneja la lógica de movimiento principal. Aquí se leen las entradas del usuario, se calcula la velocidad del jugador y se llama a `move_and_slide()` para aplicar el movimiento.
*   También hay funciones para manejar animaciones (`_set_animation()`) y otras acciones del jugador.

### Posibles Mejoras y Adiciones

Para entender qué más puedes agregar a la mecánica de movimiento, considera lo siguiente:

*   **Tipos de movimiento:** Agregar diferentes tipos de movimiento (correr, saltar, gatear) o modificar la velocidad y la aceleración.
*   **Interacciones con el entorno:** Agregar lógica para detectar colisiones con objetos del entorno y reaccionar a ellas (por ejemplo, detener el movimiento al chocar con una pared).
*   **Estados del personaje:** Implementar un sistema de estados para el personaje (por ejemplo, "idle", "walking", "running", "jumping") y cambiar el comportamiento del personaje según su estado actual.
*   **Habilidades:** Agregar habilidades especiales al personaje, como un dash o un ataque.

### Recomendaciones para Agregar Funcionalidades

1.  **Planifica:** Definir claramente qué quieres agregar y cómo quieres que funcione.
2.  **Implementa:** Escribe el código necesario para implementar la nueva funcionalidad.
3.  **Prueba:** Probar la nueva funcionalidad a fondo para asegurarte de que funciona correctamente y no introduce errores.
4.  **Documenta:** Escribe comentarios en el código para explicar cómo funciona la nueva funcionalidad.

---

### 6. `script_templates/`
Plantillas de scripts para facilitar la creación de nuevos scripts en el proyecto.

---

### 7. `.github/`
Workflows de GitHub Actions, configuración de dependabot, y otros archivos para automatización y CI/CD.

> No afecta la lógica del juego.

---

### 8. `.godot/`
Archivos internos de Godot (cachés, configuraciones temporales).

> No modificar manualmente.

---

### 9. `.vscode/`
Configuración específica para Visual Studio Code (tareas, extensiones, etc.).

> Solo afecta tu entorno de desarrollo.

---

### 10. Archivos raíz importantes

- **project.godot**: Configuración global del proyecto Godot.
- **export_presets.cfg**: Configuración de exportación para distintas plataformas.
- **README.md**: Explicación general del proyecto.
- **default_bus_layout.tres**: Configuración de buses de audio.
- **icon.png**: Icono del proyecto.
- **Archivos de licencia y metadatos**: Información legal y de autores.

---

## Resumen visual

```
threadbare/
│
├─ addons/
│   └─ dialogue_manager/
│       ├─ components/
│       ├─ compiler/
│       ├─ l10n/
│       ├─ views/
│       ├─ plugin.gd
│       ├─ settings.gd
│       └─ import_plugin.gd
│
├─ assets/
├─ build/
├─ linux/
├─ scenes/
├─ script_templates/
├─ .github/
├─ .godot/
├─ .vscode/
├─ project.godot
├─ export_presets.cfg
├─ README.md
├─ default_bus_layout.tres
└─ icon.png
```

---

## Notas

- Realiza cambios en las carpetas y archivos según el propósito descrito para evitar romper la funcionalidad del proyecto.
- Si tienes dudas sobre dónde implementar una mecánica o funcionalidad, consulta esta guía o