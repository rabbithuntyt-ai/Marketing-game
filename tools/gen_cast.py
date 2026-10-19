# Generate themed MakeHuman characters (CC0 assets) as rigged GLBs for Godot.
# usage: python3 gen.py <out_dir> [id ...]
import sys, os, bpy, addon_utils
addon_utils.enable("bl_ext.user_default.mpfb", default_set=True)
from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.exportservice import ExportService
from bl_ext.user_default.mpfb.services.objectservice import ObjectService
D = os.path.expanduser("~/.config/blender/5.2/extensions/.user/user_default/mpfb/data")

def race(af, asi, ca): return {"african": af, "asian": asi, "caucasian": ca}
# id: macros, skin, hair, eyebrows, clothes
CAST = {
 "director_0": dict(m=dict(gender=0.0, age=0.68, muscle=0.45, weight=0.45, height=0.55, race=race(0, 0, 1)), skin="middleage_caucasian_female", hair="bob02", brow="eyebrow010", clothes=["female_elegantsuit01", "shoes04"]),
 "director_1": dict(m=dict(gender=1.0, age=0.85, muscle=0.5, weight=0.6, height=0.6, race=race(1, 0, 0)), skin="old_african_male", hair="short02", brow="eyebrow001", clothes=["male_elegantsuit01", "shoes04"]),
 "director_2": dict(m=dict(gender=1.0, age=0.7, muscle=0.45, weight=0.62, height=0.5, race=race(0, 0, 1)), skin="middleage_caucasian_male", hair="short03", brow="eyebrow002", clothes=["male_elegantsuit01", "shoes01"]),
 "director_3": dict(m=dict(gender=1.0, age=0.62, muscle=0.55, weight=0.45, height=0.7, race=race(0, 0, 1)), skin="middleage_caucasian_male", hair="short01", brow="eyebrow006", clothes=["male_casualsuit05", "shoes04"]),
 "director_4": dict(m=dict(gender=0.0, age=0.66, muscle=0.5, weight=0.5, height=0.5, race=race(1, 0, 0)), skin="middleage_african_female", hair="ponytail01", brow="eyebrow011", clothes=["female_elegantsuit01", "shoes04"]),
 "voss":       dict(m=dict(gender=1.0, age=0.95, muscle=0.45, weight=0.55, height=0.68, race=race(0, 0, 1)), skin="old_caucasian_male", hair="short01", brow="eyebrow007", clothes=["male_elegantsuit01", "shoes04"]),
 "courier":    dict(m=dict(gender=1.0, age=0.45, muscle=0.6, weight=0.45, height=0.55, race=race(0, 1, 0)), skin="young_asian_male", hair="short04", brow="eyebrow003", clothes=["male_casualsuit05", "shoes06"]),
 "civilian_a": dict(m=dict(gender=0.0, age=0.4, muscle=0.5, weight=0.45, height=0.45, race=race(1, 0, 0)), skin="young_african_female", hair="afro01", brow="eyebrow012", clothes=["female_sportsuit01", "shoes05"]),
 "civilian_b": dict(m=dict(gender=1.0, age=0.9, muscle=0.4, weight=0.6, height=0.45, race=race(0, 0, 1)), skin="old_caucasian_male", hair=None, brow="eyebrow004", clothes=["male_casualsuit03", "shoes01", "fedora01"]),
 "civilian_c": dict(m=dict(gender=1.0, age=0.5, muscle=0.65, weight=0.55, height=0.6, race=race(0, 0, 1)), skin="young_caucasian_male", hair="short02", brow="eyebrow005", clothes=["male_worksuit01", "shoes03"]),
}

def asset(kind, name):
    p = os.path.join(D, kind, name, name + ".mhclo")
    if not os.path.exists(p): raise SystemExit("missing " + p)
    return p

def tpose(rig, meshes):
    """Re-rest the rig in a T-pose (arms horizontal) so Godot's humanoid retargeting matches the
    T-pose rest of the soldier/UAL animation sources."""
    from mathutils import Vector, Matrix
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    for o in bpy.context.selected_objects: o.select_set(False)
    bpy.context.view_layer.objects.active = rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    for side, sx in (("l", 1.0), ("r", -1.0)):
        for bn, want in (("upperarm_", Vector((sx, 0.0, 0.0))), ("lowerarm_", Vector((sx, 0.0, 0.0))), ("hand_", Vector((sx, 0.0, 0.0))),
                         ("thigh_", Vector((0.0, 0.0, -1.0))), ("calf_", Vector((0.0, 0.0, -1.0)))):
            pb = rig.pose.bones[bn + side]
            bpy.context.view_layer.update()
            cur = (pb.tail - pb.head).normalized()
            q = cur.rotation_difference(want)
            h = pb.head.copy()
            pb.matrix = Matrix.Translation(h) @ q.to_matrix().to_4x4() @ Matrix.Translation(-h) @ pb.matrix
            bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")
    for m in meshes:
        arm = [md for md in m.modifiers if md.type == "ARMATURE"]
        if not arm: continue
        for o in bpy.context.selected_objects: o.select_set(False)
        bpy.context.view_layer.objects.active = m; m.select_set(True)
        bpy.ops.object.modifier_apply(modifier=arm[0].name)
        md = m.modifiers.new("Armature", "ARMATURE"); md.object = rig
        bpy.ops.object.modifier_move_to_index(modifier=md.name, index=0)
    for o in bpy.context.selected_objects: o.select_set(False)
    bpy.context.view_layer.objects.active = rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")

def build(cid, spec, out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mac = {"gender": 0.5, "age": 0.5, "muscle": 0.5, "weight": 0.5, "proportions": 0.6, "height": 0.5, "cupsize": 0.5, "firmness": 0.5, "race": race(0.33, 0.33, 0.33)}
    mac.update(spec["m"])
    bm = HumanService.create_human(macro_detail_dict=mac)
    HumanService.set_character_skin(os.path.join(D, "skins", spec["skin"], spec["skin"] + ".mhmat"), bm, skin_type="GAMEENGINE")
    HumanService.add_builtin_rig(bm, "game_engine")
    HumanService.add_mhclo_asset(os.path.join(D, "eyes", "low-poly", "low-poly.mhclo"), bm, asset_type="Eyes", subdiv_levels=0)
    HumanService.add_mhclo_asset(asset("eyebrows", spec["brow"]), bm, asset_type="Eyebrows", subdiv_levels=0)
    HumanService.add_mhclo_asset(asset("eyelashes", "eyelashes01"), bm, asset_type="Eyelashes", subdiv_levels=0)
    if spec["hair"]: HumanService.add_mhclo_asset(asset("hair", spec["hair"]), bm, asset_type="Hair", subdiv_levels=0)
    for c in spec["clothes"]: HumanService.add_mhclo_asset(asset("clothes", c), bm, asset_type="Clothes", subdiv_levels=0)
    cp = ExportService.create_character_copy(bm)
    cbm = ObjectService.find_object_of_type_amongst_nearest_relatives(cp, "Basemesh")
    ExportService.bake_modifiers_remove_helpers(cbm, bake_masks=True, bake_subdiv=False, remove_helpers=True, also_proxy=True)
    root = cp.parent if cp.parent else cp
    objs = [root] + list(root.children_recursive)
    for o in objs:
        if o.type == "MESH" and o.data.shape_keys:
            bpy.context.view_layer.objects.active = o
            for oo in bpy.context.selected_objects: oo.select_set(False)
            o.select_set(True)
            bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
    if root.type == "ARMATURE": tpose(root, [o for o in objs if o.type == "MESH"])
    # drop the original (non-export) character
    for o in list(bpy.data.objects):
        if o not in objs: bpy.data.objects.remove(o, do_unlink=True)
    for oo in bpy.context.selected_objects: oo.select_set(False)
    for o in objs: o.select_set(True)
    root.name = "Human_rig_x" if root.type == "ARMATURE" else root.name
    if root.type == "ARMATURE": root.data.name = "Human_rig_x"
    for img in bpy.data.images:
        if img.size[0] == 0: continue
        cap = 1024 if ("skinned" in img.name or "skin" in img.name) else 512
        if img.size[0] > cap or img.size[1] > cap:
            img.scale(min(cap, img.size[0]), min(cap, img.size[1]))
    path = os.path.join(out, cid + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_animations=False, export_skins=True,
                              export_image_format="AUTO", export_apply=False)
    print("WROTE", path, os.path.getsize(path))

out = sys.argv[1]; ids = sys.argv[2:] or list(CAST.keys())
os.makedirs(out, exist_ok=True)
for cid in ids: build(cid, CAST[cid], out)
