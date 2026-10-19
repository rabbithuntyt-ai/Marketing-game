**Operation Value Chain**: a story-driven FPS covering Chapters 1–7 of *Marketing: An Introduction* (7th Canadian ed.).

### Download (Windows 64-bit)
**`OperationValueChain-win64.zip`**: the whole game in one file. Unzip it and run `OperationValueChain\OperationValueChain.exe`.

This is a native Godot 4.5 executable. There's no installer and no browser runtime. It needs a Vulkan-capable GPU (most cards from about 2016 on). If it won't start, launch it with `--rendering-driver d3d12`.

### What's inside
- 8 missions and 62 sectors.
- 55 recovered intel documents, each a section of the textbook rewritten as evidence.
- 122 analysis calls, plus spaced-recall checks on anything you get wrong.
- Fully voiced: 571 lines, about 108 minutes of dialogue.
- 16 in-engine cutscenes, plus briefings, debriefs with a concept review, and a Weak Spots drill in the Intel Archive.
- 7 case boards between missions: string evidence to concepts, sort each chapter's framework, and unlock Dr. Marr's voiced case notes (the chapter summary).

All third-party assets are credited in-game (Main menu → Credits) and in `CREDITS-audio.txt`.

### Your progress
Your save lives at `%APPDATA%\Godot\app_userdata\Operation Value Chain\save.json`, outside the game folder. Unzipping a new build over the old one, or into a new folder, keeps it. If you want a backup, copy that file somewhere safe.

### What's new in this build
- **Wrong answers no longer soft-lock a sector.** The alarm reinforcements used to spawn behind the locked exit door, where you couldn't reach them. Now they come in on the far side of the room you're in.
- **The giant brick blocks are gone.** They were distant city buildings scaled up so far that they poked through the walls of outdoor sectors and window rooms. They're now smaller and kept well clear of every room.
- **New first-person arms.** Rigged, gloved hands and sleeves sit on the pistol grip and handguard, replacing the old boxes. The fingers curl around the grip, and both arms follow the rifle through bob, recoil and reloads.
- **Soldiers' left hands now hold the handguard.** An IK chain pins each soldier's support hand to the rifle in every rifle animation. Characters in non-combat poses (talking, jogging, sitting) put their rifles away.
- **New gunfire.** The shots are real firearm recordings, layered with a low-end thump and a distance tail outdoors. There are separate sets for enemies, the marksman rifle and suppressed fire.
