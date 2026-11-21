# IMPERIUM

Historical strategy and ruler-perspective game for Android and PC.

## Current playable foundation

The Godot 4 project is under `godot/`. It is the active game project; the old WebView app is retained only as a legacy demo.

- First-person 3D palace room, movement, sprint and ambassador interaction.
- Offline campaign save/load.
- Selectable starter realm, ruler and campaign year (the currently seeded historical dataset is limited to 1300–1500).
- Province map prototype with province selection, population, tax, food and garrison information.
- Daily time advancement and basic treasury income.
- Tactical battlefield prototype with three friendly units, three opposing units, formations, advance/charge/hold/retreat orders and simple close-combat attrition.
- On-screen Android movement and interaction controls.
- Godot Android export workflow in `.github/workflows/godot-android.yml`.

## Important scope limits

This is an early playable prototype, not a finished grand-strategy release. The current map is a stylized regional prototype with eight sample provinces, not a geographically complete world map. Historical data contains only a few sample realms and rulers. Diplomacy is currently dialogue-only; trade, diplomacy AI, detailed siege simulation, full tactical combat, dynasty event chains, and complete historical coverage remain unfinished.

## Open in Godot

Use Godot 4.4.1 and open `godot/project.godot`.

## Android APK

The `Export IMPERIUM Godot Android APK` workflow builds the Godot 3D project and uploads an artifact named `imperium-godot-android-debug`. Open GitHub Actions in this repository, select the latest successful workflow run, and download its artifact. The separate legacy WebView workflow is manually triggered and is not the 3D game.
