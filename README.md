# IMPERIUM

Historical grand-strategy and ruler-life game for Android and PC.

## Project status
The existing Android WebView build is an early 2D management build, not the finished game. The new Godot 4 project is being built as the long-term 3D game runtime under `godot/`.

## Godot project
Open `godot/project.godot` with Godot 4.x. The current committed 3D foundation includes:
- A navigable 3D palace room with collision geometry and lighting.
- A first-person player controller with mouse look, WASD movement, sprint, and interaction input.
- Mobile-compatible GL Compatibility renderer selection.

## Planned complete game systems
The target release includes date/civilization/ruler selection, historical world map, province and economy simulation, diplomacy, dynasties and succession, tactical army command, sieges, and offline historical data. These systems are not yet complete and will be implemented and tested in the Godot project before calling the game finished.

## Android build
The existing GitHub Actions workflow builds the current Android WebView application. It does not yet export the new Godot 3D project. Do not treat its APK as the finished 3D game.
