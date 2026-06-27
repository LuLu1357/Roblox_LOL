"""
create_blue_melee_visual_v2.py

Génère dans Blender un sbire melee bleu V2 plus stylisé pour Roblox :
BlueMeleeVisual

Style :
- silhouette plus compacte / trapue
- casque et épaulières
- grosse massue/épée courte mieux lisible
- root HumanoidRootPart
- AttackOrigin
- forward visuel supposé : -Y
- origine globale au sol (0,0,0)

Destination Roblox :
ServerStorage.Assets.Models.Minions.Blue.Melee.BlueMeleeVisual

Utilisation :
1. Ouvre Blender.
2. Onglet Scripting.
3. Open -> ce fichier.
4. Run Script.
5. Vérifie en Material Preview : Z puis 2.
6. Avant export, sélectionne BlueMeleeVisual et ses enfants uniquement.
"""

import math
import bpy


# ------------------------------------------------------------
# Nettoyage / matériaux
# ------------------------------------------------------------

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_mat(name, color, roughness=0.6, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
    return mat


def assign(obj, mat):
    obj.data.materials.append(mat)


# ------------------------------------------------------------
# Helpers création
# ------------------------------------------------------------

def cube(name, loc, scale, mat=None, bevel=0.0, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    if mat:
        assign(obj, mat)
    if bevel > 0:
        b = obj.modifiers.new("SoftBevel", "BEVEL")
        b.width = bevel
        b.segments = 2
        b.affect = "EDGES"
        obj.modifiers.new("WeightedNormals", "WEIGHTED_NORMAL")
    return obj


def sphere(name, loc, scale, mat=None, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        radius=1,
        location=loc,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    if mat:
        assign(obj, mat)
    bpy.ops.object.shade_smooth()
    return obj


def cyl(name, loc, radius, depth, mat=None, vertices=8, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=loc,
        rotation=rot,
    )
    obj = bpy.context.object
    obj.name = name
    if mat:
        assign(obj, mat)
    return obj


def cone(name, loc, radius1, radius2, depth, mat=None, vertices=12, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=loc,
        rotation=rot,
    )
    obj = bpy.context.object
    obj.name = name
    if mat:
        assign(obj, mat)
    return obj


def empty(name, loc, display="SPHERE", size=0.15):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = display
    obj.empty_display_size = size
    obj.location = loc
    bpy.context.scene.collection.objects.link(obj)
    return obj


# ------------------------------------------------------------
# Modèle
# ------------------------------------------------------------

def create_model():
    clear_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    # Matériaux visibles en Material Preview
    mat_blue = make_mat("MAT_BlueTeam_Armor", (0.02, 0.20, 0.95, 1.0), 0.55)
    mat_blue_dark = make_mat("MAT_DarkBlue_Undersuit", (0.01, 0.04, 0.25, 1.0), 0.75)
    mat_steel = make_mat("MAT_SoftSteel", (0.66, 0.70, 0.75, 1.0), 0.35, 0.2)
    mat_edge = make_mat("MAT_BrightBlue_Edge", (0.15, 0.55, 1.0, 1.0), 0.45)
    mat_handle = make_mat("MAT_Weapon_Handle", (0.14, 0.08, 0.04, 1.0), 0.8)
    mat_eye = make_mat("MAT_GlowEye", (0.3, 0.9, 1.0, 1.0), 0.3)
    mat_root = make_mat("MAT_Root_Debug", (1.0, 0.1, 0.1, 0.25), 0.5)

    collection = bpy.data.collections.new("BlueMeleeVisual")
    bpy.context.scene.collection.children.link(collection)

    parts = []

    # Root, compact, à rendre invisible dans Roblox
    root = cube("HumanoidRootPart", (0, 0, 1.25), (0.55, 0.55, 1.25), mat_root, 0.02)
    root.display_type = "WIRE"
    root.hide_render = True
    parts.append(root)

    # Corps trapu
    body = cube("MeleeMinion_Body", (0, 0, 1.28), (0.78, 0.52, 0.62), mat_blue, 0.18)
    parts.append(body)

    belly = cube("MeleeMinion_DarkBelly", (0, -0.535, 1.25), (0.48, 0.04, 0.40), mat_blue_dark, 0.06)
    parts.append(belly)

    # Tête plus basse et stylisée
    head = sphere("MeleeMinion_Head", (0, -0.02, 2.05), (0.52, 0.48, 0.42), mat_blue, 16, 8)
    parts.append(head)

    # Casque : bande + crête
    visor = cube("MeleeMinion_Visor", (0, -0.46, 2.05), (0.38, 0.055, 0.105), mat_blue_dark, 0.025)
    parts.append(visor)

    eye_l = cube("MeleeMinion_Eye_L", (-0.13, -0.505, 2.055), (0.055, 0.018, 0.035), mat_eye, 0.006)
    eye_r = cube("MeleeMinion_Eye_R", (0.13, -0.505, 2.055), (0.055, 0.018, 0.035), mat_eye, 0.006)
    parts.extend([eye_l, eye_r])

    crest = cube("MeleeMinion_Helmet_Crest", (0, -0.03, 2.45), (0.12, 0.34, 0.10), mat_edge, 0.04)
    parts.append(crest)

    # Épaulières larges
    shoulder_l = cube("MeleeMinion_Shoulder_L", (-0.78, -0.02, 1.55), (0.25, 0.34, 0.22), mat_edge, 0.10, rot=(0, math.radians(-8), 0))
    shoulder_r = cube("MeleeMinion_Shoulder_R", (0.78, -0.02, 1.55), (0.25, 0.34, 0.22), mat_edge, 0.10, rot=(0, math.radians(8), 0))
    parts.extend([shoulder_l, shoulder_r])

    # Bras courts et puissants
    arm_l = cube("MeleeMinion_Arm_L", (-0.94, -0.08, 1.16), (0.18, 0.22, 0.48), mat_blue_dark, 0.08, rot=(0, math.radians(-14), 0))
    arm_r = cube("MeleeMinion_Arm_R", (0.94, -0.08, 1.16), (0.18, 0.22, 0.48), mat_blue_dark, 0.08, rot=(0, math.radians(14), 0))
    parts.extend([arm_l, arm_r])

    hand_l = sphere("MeleeMinion_Hand_L", (-1.03, -0.18, 0.82), (0.15, 0.14, 0.13), mat_blue, 12, 6)
    hand_r = sphere("MeleeMinion_Hand_R", (1.03, -0.18, 0.82), (0.15, 0.14, 0.13), mat_blue, 12, 6)
    parts.extend([hand_l, hand_r])

    # Jambes courtes et pieds larges
    leg_l = cube("MeleeMinion_Leg_L", (-0.30, 0.00, 0.55), (0.23, 0.25, 0.46), mat_blue_dark, 0.08)
    leg_r = cube("MeleeMinion_Leg_R", (0.30, 0.00, 0.55), (0.23, 0.25, 0.46), mat_blue_dark, 0.08)
    foot_l = cube("MeleeMinion_Foot_L", (-0.31, -0.17, 0.12), (0.30, 0.40, 0.12), mat_blue, 0.05)
    foot_r = cube("MeleeMinion_Foot_R", (0.31, -0.17, 0.12), (0.30, 0.40, 0.12), mat_blue, 0.05)
    parts.extend([leg_l, leg_r, foot_l, foot_r])

    # Arme : massue/épée courte beaucoup plus lisible, côté droit, forward -Y
    handle = cyl(
        "MeleeMinion_Club_Handle",
        (0.98, -0.35, 1.05),
        0.06,
        0.85,
        mat_handle,
        8,
        rot=(math.radians(58), 0, math.radians(8)),
    )
    parts.append(handle)

    club_head = cube(
        "MeleeMinion_Club_Head",
        (1.08, -0.78, 1.45),
        (0.18, 0.18, 0.38),
        mat_steel,
        0.06,
        rot=(math.radians(58), 0, math.radians(8)),
    )
    parts.append(club_head)

    spike_1 = cone(
        "MeleeMinion_Club_Spike_1",
        (1.08, -0.98, 1.58),
        0.06,
        0.0,
        0.20,
        mat_steel,
        8,
        rot=(math.radians(90), 0, 0),
    )
    parts.append(spike_1)

    # AttackOrigin devant l'arme
    attack = empty("AttackOrigin", (1.08, -1.03, 1.50), "SPHERE", 0.13)
    parts.append(attack)

    # Petit bouclier sur le bras gauche pour silhouette
    shield = cube("MeleeMinion_Shield_L", (-1.05, -0.38, 1.12), (0.10, 0.12, 0.42), mat_steel, 0.05, rot=(0, math.radians(-8), 0))
    parts.append(shield)

    # Ranger pièces dans collection
    for obj in parts:
        for coll in list(obj.users_collection):
            if coll != collection:
                coll.objects.unlink(obj)
        try:
            collection.objects.link(obj)
        except RuntimeError:
            pass

    # Appliquer rotation/scale sur les meshes, pour export propre
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        if obj.type == "MESH":
            obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Parent final nommé comme l'asset Roblox
    parent = bpy.data.objects.new("BlueMeleeVisual", None)
    parent.empty_display_type = "PLAIN_AXES"
    parent.empty_display_size = 0.45
    parent.location = (0, 0, 0)
    collection.objects.link(parent)

    for obj in parts:
        obj.parent = parent

    # Référence sol non export
    mat_floor = make_mat("MAT_Floor_Reference", (0.18, 0.18, 0.18, 1.0), 0.8)
    floor = cube("REF_Ground_DoNotExport", (0, 0, -0.025), (2.7, 2.7, 0.02), mat_floor, 0.0)
    floor.hide_render = True

    # Référence taille joueur Roblox simplifiée non export
    ref = cube("REF_PlayerHeight_DoNotExport", (1.65, 0, 2.5), (0.35, 0.35, 2.5), None, 0.0)
    ref.display_type = "WIRE"
    ref.hide_render = True

    # Lumière et caméra
    bpy.ops.object.light_add(type="AREA", location=(0, -5, 5))
    light = bpy.context.object
    light.name = "Preview_Light"
    light.data.energy = 500
    light.data.size = 5

    bpy.ops.object.camera_add(location=(3.8, -5.5, 3.2), rotation=(math.radians(62), 0, math.radians(35)))
    cam = bpy.context.object
    bpy.context.scene.camera = cam

    print("BlueMeleeVisual V2 créé.")
    print("Voir les couleurs : appuie sur Z puis 2.")
    print("Forward visuel supposé : -Y, côté yeux/arme.")
    print("Ne pas exporter REF_Ground_DoNotExport, REF_PlayerHeight_DoNotExport, Preview_Light, Camera.")
    print("Destination Roblox : ServerStorage.Assets.Models.Minions.Blue.Melee.BlueMeleeVisual")


create_model()
