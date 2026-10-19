**Operation Value Chain**: a story-driven FPS covering Chapters 1–7 of *Marketing: An Introduction* (7th Canadian ed.).

### Download (Windows 64-bit)
**`OperationValueChain-win64.zip`**: the whole game in one file. Unzip it and run `OperationValueChain\OperationValueChain.exe`.

This is a native Godot 4.5 executable. There's no installer and no browser runtime. It needs a Vulkan-capable GPU (most cards from about 2016 on). If it won't start, launch it with `--rendering-driver d3d12`.

### What's inside
- 8 missions and 62 hand-built sectors.
- 55 recovered intel documents, each a section of the textbook rewritten as evidence.
- 122 analysis calls, plus spaced-recall checks on anything you get wrong.
- Fully voiced: 571 lines, about 108 minutes of dialogue.
- 16 in-engine cutscenes, plus briefings, debriefs with a concept review, and a Weak Spots drill in the Intel Archive.
- 7 case boards between missions: string evidence to concepts, sort each chapter's framework, and unlock Dr. Marr's voiced case notes (the chapter summary).

All third-party assets are credited in-game (Main menu → Credits) and in `CREDITS-audio.txt`.

### Your progress
Your save lives at `%APPDATA%\Godot\app_userdata\Operation Value Chain\save.json`, outside the game folder. Unzipping a new build over the old one, or into a new folder, keeps it. If you want a backup, copy that file somewhere safe.

### What's new in this build
- **Every sector is hand-built.** All 62 sectors across the 8 missions are now laid out by hand, piece by piece, with no random generation. Each one has its own floor plan, lighting, cover and guard routes: a trailer yard in the rain, a sorting hall with conveyor lines and a gantry, a container yard under two cranes, a tiered command room, a mall atrium with a mezzanine, a theatre-style launch hall, a glass lobby with a bridge 6 m up, and more.
- **Far more props.** The game now uses a modular sci-fi building kit and over 70 real-world props (furniture, vehicles, shelving, generators, street lamps and so on), so rooms no longer reuse the same few boxes.
- **Stealth works.** Every sector has routes you can use without being seen: unlit car parks and aisles, crawl ducts, catwalks, shadows behind chillers. Breaker boxes kill the lights, and searchlights and cameras sweep on a timer. Guarded combat rooms start silent and only go loud if you're spotted, and clearing a room unseen earns a bonus.
- **Answer by walking to the console.** In many sectors, Marr's questions appear on a big wall screen, and you answer by walking to the lettered console that carries your answer. A wrong choice still trips the alarm.
- **A real cast.** The five directors in the Mission 1 identity parade, Adrian Voss, Paul Ostrowski, the courier and the civilians each have their own model, in suits and street clothes that fit Castellan's world. Kessler, Hale and Ruiz wear unit armbands so you can tell them apart at a glance.
- **Better weapon handling.** The rifle reacts to everything you do: it kicks and settles after each shot, dips when you land, lags when you change direction, leans when you strafe and lowers smoothly when you sprint. Reloads are fully animated: your left hand strips the magazine, seats a new one and works the charging handle.
- **Wrong answers can't soft-lock a sector.** Alarm reinforcements arrive inside the room you're in.
- **No more giant brick blocks.** The city outside the tower floors is now distant, lit skyscrapers, well clear of every room.
- **Memory:** the previous mission's assets are freed when the next one loads.
