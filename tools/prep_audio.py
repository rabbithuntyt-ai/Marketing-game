#!/usr/bin/env python3
"""Convert selected open-licence music and sound effects into assets/audio and gather per-file credits."""
import os, sys, glob, subprocess, shutil, re
S = sys.argv[1]
A = "assets/audio"
CC = f"{S}/ext3/CDDA-Soundpacks/sound/CC-Sounds"
TPS = f"{S}/tex/tps"
def mk(p): os.makedirs(p, exist_ok=True); return p
def conv(src, dst, q=4, mono=False, norm=None, trim=False):
    args = ["ffmpeg", "-v", "quiet", "-y", "-i", src]
    af = []
    if trim: af.append("silenceremove=start_periods=1:start_threshold=-50dB")
    if norm: af.append(f"loudnorm=I={norm}:TP=-1.5:LRA=11")
    if af: args += ["-af", ",".join(af)]
    if mono: args += ["-ac", "1"]
    args += ["-ar", "44100", "-c:a", "libvorbis", "-q:a", str(q), dst]
    r = subprocess.run(args)
    if r.returncode or not os.path.exists(dst): print("FAILED", src)

credits = []
# ---------- music ----------
M = mk(f"{A}/music")
TM = f"{S}/ext3/tm/mp3"
music = {
 "deeper": f"{TM}/Deeper.mp3", "retribution": f"{TM}/Retribution.mp3", "ominosity": f"{TM}/Ominosity.mp3", "surreptitious": f"{TM}/Surreptitious.mp3",
 "dark_knight": f"{TM}/Dark Knight.mp3", "reign_of_anarchy": f"{TM}/Reign of Anarchy.mp3", "the_haunting": f"{TM}/The Haunting.mp3",
 "syntheticity": f"{TM}/Syntheticity.mp3", "destiny": f"{TM}/Destiny.mp3", "halls_of_despair": f"{TM}/Halls of Despair.mp3", "thugs": f"{TM}/Thugs.mp3",
 "now_or_never": f"{TM}/Now or Never.mp3", "fate": f"{TM}/Fate.mp3", "crossroads": f"{TM}/Crossroads.mp3", "remember": f"{TM}/Remember.mp3",
 "home": f"{TM}/Home.mp3", "from_here": f"{TM}/From Here.mp3", "daybreak": f"{TM}/Daybreak.mp3",
 "northern_lights": f"{S}/ext3/xonotic-music.pk3dir/sound/cdtracks/northern-lights.ogg", "neon": f"{S}/ext3/xonotic-music.pk3dir/sound/cdtracks/neon.ogg",
 "taiko_1": f"{S}/ext3/0ad/binaries/data/mods/public/audio/music/Taiko_1.ogg", "taiko_2": f"{S}/ext3/0ad/binaries/data/mods/public/audio/music/Taiko_2.ogg",
 "calm_before": f"{S}/ext3/0ad/binaries/data/mods/public/audio/music/Calm_Before_the_Storm.ogg",
 "tps_level": f"{TPS}/level/level_music.ogg", "tps_menu": f"{TPS}/menu/menu_intro_music.ogg",
}
for k, src in music.items():
    if not os.path.exists(src): print("missing music", k, src); continue
    conv(src, f"{M}/{k}.ogg", q=4, norm=-18)
    who = ("Tanner Helland, github.com/tannerhelland/free-music, CC BY 4.0" if "/tm/" in src else
           "Xonotic team, xonotic-music, GPLv2+" if "xonotic" in src else
           "Omri Lahav, 0 A.D. (Wildfire Games), CC BY-SA 3.0" if "0ad" in src else
           "Christian Fernando Perucchi, Godot TPS demo, CC BY 3.0")
    credits.append(f"music/{k}.ogg  <-  {os.path.basename(src)}  ·  {who}")

# ---------- sound effects ----------
X = mk(f"{A}/sfx")
sfx = {
 "rifle_in_1": f"{CC}/fire_gun/rifles/automatic_rifle/indoor_gunfire/556_auto_rifle_shot_01.ogg",
 "rifle_in_2": f"{CC}/fire_gun/rifles/automatic_rifle/indoor_gunfire/556_auto_rifle_shot_02.ogg",
 "rifle_in_3": f"{CC}/fire_gun/rifles/automatic_rifle/indoor_gunfire/556_auto_rifle_shot_03.ogg",
 "rifle_out_1": f"{CC}/fire_gun/rifles/automatic_rifle/outdoor_gunfire/556_auto_rifle_shot_01.ogg",
 "rifle_out_2": f"{CC}/fire_gun/rifles/automatic_rifle/outdoor_gunfire/556_auto_rifle_shot_02.ogg",
 "rifle_out_3": f"{CC}/fire_gun/rifles/automatic_rifle/outdoor_gunfire/556_auto_rifle_shot_03.ogg",
 "sniper": f"{CC}/fire_gun/rifles/rifle_1.ogg", "pistol": f"{CC}/fire_gun/handguns/handgun_1.ogg", "lmg": f"{CC}/fire_gun/machineguns/machinegun_1.ogg",
 "brass": f"{CC}/fire_gun/brass_eject.ogg", "brass2": f"{CC}/fire_gun/brass_eject_1.ogg", "empty": f"{CC}/fire_gun/empty.ogg",
 "reload": f"{CC}/reload/default.ogg",
 "boom_1": f"{CC}/explosion/default/explosion_default_1.ogg", "boom_2": f"{CC}/explosion/default/explosion_default_2.ogg",
 "boom_big_1": f"{CC}/explosion/huge/explosion_huge_1.ogg", "boom_big_2": f"{CC}/explosion/huge/explosion_huge_2.ogg", "boom_small": f"{CC}/explosion/small/explosion_small.ogg",
 "rain_heavy": f"{CC}/environment/weather/heavyrain.ogg", "storm": f"{CC}/environment/weather/thunderstorm.ogg", "rain_inside": f"{CC}/environment/weather/indoors_rain.ogg",
 "thunder_near": f"{CC}/environment/weather/thunder_near.ogg", "thunder_far": f"{CC}/environment/weather/thunder_far.ogg", "night": f"{CC}/environment/weather/night/clear_night_1.ogg",
 "snowstorm": f"{CC}/environment/weather/WEATHER_SNOWSTORM.ogg", "alarm": f"{CC}/environment/ambient/alarm.ogg", "indoors": f"{CC}/environment/ambient/indoors.ogg",
 "underground": f"{CC}/environment/ambient/underground.ogg", "siren": f"{CC}/environment/ambient/police_siren.ogg",
 "door_open": f"{CC}/open_door/door_metal/open_door_metal.ogg", "door_close": f"{CC}/close_door/door_metal/close_door_metal.ogg",
 "tps_door": f"{TPS}/door/open_close.wav", "tps_boom": f"{TPS}/enemies/red_robot/audio/explosion.wav", "tps_hit": f"{TPS}/enemies/red_robot/audio/hit.wav",
}
for i in range(1, 5): sfx[f"hurt_{i}"] = f"{CC}/deal_damage/hurt_m/hurt_m_{i}.ogg"
for i in range(1, 9): sfx[f"step_concrete_{i}"] = f"{CC}/plmove/walk_t_concrete_{i}.ogg"
for i in range(1, 6): sfx[f"step_metal_{i}"] = f"{CC}/plmove/walk_metal/walk_metal_{i}.ogg"
for i in range(1, 7): sfx[f"step_gravel_{i}"] = f"{CC}/plmove/walk_t_gravel_{i}.ogg"
for k, src in sfx.items():
    if not os.path.exists(src): print("missing sfx", k, src); continue
    loop = k in ("rain_heavy", "storm", "rain_inside", "night", "snowstorm", "alarm", "indoors", "underground")
    conv(src, f"{X}/{k}.ogg", q=5, mono=not loop and not k.startswith("boom") and not k.startswith("thunder"))
    if "/CC-Sounds/" in src:
        cr = os.path.join(os.path.dirname(src), "credits.md"); line = f"sfx/{k}.ogg  <-  CC-Sounds {os.path.relpath(src, CC)}"
        if os.path.exists(cr):
            for row in open(cr):
                if os.path.basename(src) in row:
                    cells = [c.strip() for c in row.split("|") if c.strip()]
                    if len(cells) >= 3: line += f"  ·  {cells[1]}, {cells[2].replace('*','')}"
                    if len(cells) >= 4 and cells[3].startswith("http"): line += f", {cells[3]}"
                    break
        credits.append(line)
    else:
        credits.append(f"sfx/{k}.ogg  <-  Godot TPS demo {os.path.relpath(src, TPS)}  ·  Juan Linietsky, Fernando Miguel Calabró, CC BY 3.0")
K = f"{S}/ext/Starter-Kit-FPS/sounds"
for k in ("weapon_change", "land", "jump_a"):
    shutil.copy(f"{K}/{k}.ogg", f"{X}/kenney_{k}.ogg"); credits.append(f"sfx/kenney_{k}.ogg  <-  Kenney Starter Kit FPS · MIT / CC0")
open("assets/audio/CREDITS.txt", "w").write("Operation Value Chain · audio credits\n\n" + "\n".join(credits) + "\n")
print(len(credits), "audio files")
