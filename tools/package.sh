#!/bin/bash
# Export the Windows build and package it for release.
set -e
GD=${GD:-godot}
cd "$(dirname "$0")/.."
rm -rf build/win build/pkg && mkdir -p build/win build/pkg/OperationValueChain
$GD --headless --path . --export-release "Windows Desktop" build/win/OperationValueChain.exe
cp build/win/OperationValueChain.exe build/pkg/OperationValueChain/
cp assets/audio/CREDITS.txt build/pkg/OperationValueChain/CREDITS-audio.txt
cp assets/fonts/OFL.txt build/pkg/OperationValueChain/LICENSE-fonts-OFL.txt
cp assets/anim/UAL_License.txt build/pkg/OperationValueChain/LICENSE-animations.txt 2>/dev/null || true
cat > build/pkg/OperationValueChain/README.txt <<'TXT'
OPERATION VALUE CHAIN
A story-driven tactical shooter that teaches Kotler, Armstrong, Trifts & Buchwitz,
Marketing: An Introduction (7th Canadian edition), Chapters 1-7.

Run OperationValueChain.exe. No install needed. Needs a Vulkan-capable GPU
(most cards from ~2016 on). If it won't start, create a shortcut and add
   --rendering-driver d3d12
to the end of the Target field.

Controls: WASD move, mouse look, LMB fire, RMB aim, Shift sprint, Ctrl crouch,
Space jump, R reload, G grenade, F takedown, E interact/read, 1-4 answer, Esc pause.

Saves and settings: %APPDATA%\Godot\app_userdata\Operation Value Chain\
Main menu > Intel archive > Weak spots drills every question you've missed.

Full credits are in the game (Main menu > Credits) and in CREDITS-audio.txt.
Engine: Godot 4.5 (MIT). Voices: Kokoro-82M (Apache 2.0).
Music: Tanner Helland (CC BY 4.0), Omri Lahav / 0 A.D. (CC BY-SA 3.0),
Xonotic team (GPLv2+), Godot TPS demo (CC BY 3.0).
Models: Godot TPS demo (CC BY 3.0), Dive by Mugen87 (MIT), Quaternius (CC0),
Lee Perry-Smith head by Infinite-Realities (CC BY 3.0). Fonts: SIL OFL.
TXT
cd build/pkg
rm -f ../OperationValueChain-win64.zip ../OperationValueChain-win64.7z.*
zip -q -r -9 ../OperationValueChain-win64.zip OperationValueChain
7z a -v28m -mx=7 ../OperationValueChain-win64.7z OperationValueChain > /dev/null
ls -la ..
