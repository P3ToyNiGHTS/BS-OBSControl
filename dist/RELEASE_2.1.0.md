# OBSControl 2.1.0

Automatically start/stop OBS recording when you play a song.

## What's new

- **Beat Saber 1.29.1 support** — a dedicated build for the legacy 1.29.1 game version, alongside the existing 1.40.x build.
- **Fix: "Restart Recording" no longer restarts on quit** — the Restart Action setting now only applies when you actually restart a song. Quitting to the menu (or finishing a song) always stops the recording as expected.

## Which file do I download?

| Your Beat Saber | Download |
|---|---|
| 1.40.x | `OBSControl-2.1.0-bs1.40.8.zip` |
| 1.29.1 | `OBSControl-2.1.0-bs1.29.1.zip` |

## Install

Requires **BSIPA**, **SiraUtil**, and **BeatSaberMarkupLanguage** (install via your mod manager).

Unzip the file into your Beat Saber install folder — it drops `OBSControl.dll` straight into `Plugins\`.

Then set your OBS WebSocket address/port/password in **Mod Settings → OBSControl**.
