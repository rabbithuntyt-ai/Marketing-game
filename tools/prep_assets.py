#!/usr/bin/env python3
"""Copy and convert third-party source assets into the Godot project's assets/ folder.
Run from the repo root:  python3 tools/prep_assets.py <scratchpad>"""
import os, sys, shutil, json, glob, subprocess
from PIL import Image

S = sys.argv[1]
A = "assets"
def mk(p): os.makedirs(p, exist_ok=True); return p

def img(src, dst, size=None, mode=None):
    im = Image.open(src)
    if mode: im = im.convert(mode)
    elif im.mode not in ("RGB", "RGBA"): im = im.convert("RGB")
    if size and max(im.size) > size: im = im.resize((size, size), Image.LANCZOS)
    im.save(dst)

# ---------- 1. TPS structure + prop PBR texture sets ----------
T = f"{S}/tex/tps/level/textures"
sets = {
 "tech": ("structure/tile_tech_panels",)*3, "techc": ("structure/tile_tech_panels_color",)*3, "rivet": ("structure/tile_rivet_panels",)*3,
 "scifloor": ("structure/tile_scifi_floor_panel",)*3, "floor": ("structure/tile_simple_floor",)*3, "steel": ("structure/tile_steel",)*3,
 "gunmetal": ("structure/tile_painted_gun_metal",)*3, "metal": ("structure/tile_default_metal",)*3, "pillar": ("structure/tile_metal_pillars",)*3,
 "grate": ("structure/floor_grate_wholes",)*3, "antislip": ("structure/tile_anti_slip", "structure/tile_anti_slip_metal", "structure/tile_anti_slip_metal"),
 "carbon": ("structure/tile_carbon_fiber",)*3, "glass": ("structure/tile_glass",)*3, "column": ("structure/column",)*3,
 "trim1": ("structure/trim_misc_1",)*3, "trim2": ("structure/trim_misc_2",)*3, "trimlight": ("structure/trim_emission_lights",)*3,
 "cont1": ("props/container1",)*3, "cont2": ("props/container2",)*3, "cont3": ("props/container3",)*3, "cont4": ("props/container4",)*3,
 "cargo": ("props/mid_cargo_box",)*3, "reactor": ("props/reactor_cylinder",)*3,
}
out = mk(f"{A}/tex")
for name, (al, no, orm) in sets.items():
    img(f"{T}/{al}_albedo.png", f"{out}/{name}_albedo.png", 1024)
    img(f"{T}/{no}_normal.png", f"{out}/{name}_normal.png", 1024, "RGB")
    img(f"{T}/{orm}_orm.png", f"{out}/{name}_orm.png", 1024, "RGB")
    for em in ("emission", "emissive"):
        p = f"{T}/{al}_{em}.png"
        if os.path.exists(p): img(p, f"{out}/{name}_emission.png", 1024, "RGB")
print("tps textures", len(sets))

# ---------- 2. TPS props model ----------
mk(f"{A}/props"); shutil.copy(f"{S}/tex/tps/level/geometry/models/props.glb", f"{A}/props/props.glb")

# ---------- 3. effects textures ----------
fx = mk(f"{A}/fx")
R = f"{S}/tex/tps/enemies/red_robot"
for src, dst in [(f"{R}/laser/impact_effect/SmokePuff.png", "smoke.png"), (f"{R}/laser/impact_effect/LightRays.png", "rays.png"),
                 (f"{R}/textures/explosion.png", "explosion.png"), (f"{R}/textures/particle.png", "particle.png"),
                 (f"{R}/parts/sparks_effect/SparkTexture.png", "spark.png"), (f"{S}/tex/tps/effects_shared/BlastTexture.png", "blast.png"),
                 (f"{R}/laser/FireTrailParticle.png", "firetrail.png"), (f"{R}/laser/BarrelSmokeTexture.png", "barrelsmoke.png"),
                 (f"{S}/game/assets/tex/muzzle.png", "muzzle.png"), (f"{T}/structure/light_shafts.png", "light_shafts.png"),
                 (f"{S}/tex/tps/effects_shared/spotlight_projector.png", "projector.png")]:
    if os.path.exists(src): shutil.copy(src, f"{fx}/{dst}")
    else: print("missing fx", src)

# ---------- 4. city kit (CC0) ----------
C = f"{S}/ext/tilakverse-assets/quaternius/downtown-city-megakit"
cd = mk(f"{A}/city"); ct = mk(f"{A}/city/tex")
keep = ["Building_Large_2", "Building_Medium_2_001", "Building_Small_1", "Street_4Lane", "Street_2Lane", "Street_4WayIntersection", "Street_Asphalt_9x9",
        "Sidewalk_Straight_3m", "Sidewalk_Corner_Round_3m", "Prop_ACUnit", "Prop_Bollard", "Prop_Planter_Single", "Prop_ManholeCover", "Prop_Drain",
        "Stairs_Entrance_Concrete", "Entrance_Concrete_2x2", "Roof_4x4", "Floor_4x4", "Metal_Column_Center", "Metal_FullWindow", "Metal_FirstFloor_Window"]
used = set()
for k in keep:
    g = json.load(open(f"{C}/Exports/glTF (Godot)/{k}.gltf"))
    for im in g.get("images", []):
        used.add(im["uri"]); im["uri"] = "tex/" + im["uri"]
    json.dump(g, open(f"{cd}/{k}.gltf", "w"))
    shutil.copy(f"{C}/Exports/glTF (Godot)/{k}.bin", f"{cd}/{k}.bin")
for u in used:
    src = f"{C}/Textures/{u}"
    big = any(x in u for x in ("interior", "Blinds", "Curtains"))
    img(src, f"{ct}/{u}", 512 if big else 1024, "RGBA" if "Normal" not in u and Image.open(src).mode == "RGBA" else "RGB")
print("city models", len(keep), "textures", len(used))

# ---------- 5. animation library licence ----------
shutil.copy(f"{S}/ext/tilakverse-assets/quaternius/universal-animation-library/License.txt", f"{A}/anim/UAL_License.txt")
