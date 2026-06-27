"""
create_blue_melee_visual.py

Script Blender pour générer un premier modèle test Roblox :
BlueMeleeVisual

Utilisation :
1. Ouvre Blender.
2. Va dans l'onglet Scripting.
3. Ouvre ce fichier ou colle son contenu.
4. Clique Run Script.
5. Le modèle est créé dans la scène.
6. Vérifie le résultat, puis exporte en FBX/glTF vers Roblox Studio.

Objectif Roblox :
ServerStorage.Assets.Models.Minions.Blue.Melee.BlueMeleeVisual
"""

import math
import bpy


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_mat(name, color, roughness=0.55, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True

    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic

    return mat


def add_cube(name, location, scale, material=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale

    if material:
        obj.data.materials.append(material)

    if bevel > 0:
        bevel_mod = obj.modifiers.new(name="SoftBevel", type="BEVEL")
        bevel_mod.width = bevel
        bevel_mod.segments = 2
        bevel_mod.affect = "EDGES"
        obj.modifiers.new(name="WeightedNormals", type="WEIGHTED_NORMAL")

    return obj


def add_uv_sphere(name, location, scale, material=None, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        radius=1,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale

    if material:
        obj.data.materials.append(material)

    bpy.ops.object.shade_smooth()
    return obj


def add_cylinder(name, location, radius, depth, material=None, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name

    if material:
        obj.data.materials.append(material)

    return obj


def create_blue_melee_visual():
    clear_scene()

    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    mat_blue = make_mat("MAT_BlueTeam", (0.05, 0.28, 1.0, 1.0), roughness=0.55)
    mat_blue_dark = make_mat("MAT_BlueTeam_Dark", (0.02, 0.08, 0.45, 1.0), roughness=0.65)
    mat_metal = make_mat("MAT_Metal", (0.72, 0.75, 0.78, 1.0), roughness=0.35, metallic=0.25)
    mat_handle = make_mat("MAT_DarkHandle", (0.16, 0.10, 0.06, 1.0), roughness=0.8)
    mat_root = make_mat("MAT_Root_Debug", (1.0, 0.2, 0.2, 0.25), roughness=0.4)

    collection = bpy.data.collections.new("BlueMeleeVisual")
    bpy.context.scene.collection.children.link(collection)

    created = []

    root = add_cube(
        "HumanoidRootPart",
        location=(0, 0, 1.45),
        scale=(0.45, 0.45, 1.45),
        material=mat_root,
        bevel=0.02,
    )
    root.display_type = "WIRE"
    root.hide_render = True
    created.append(root)

    body = add_cube(
        "MeleeMinion_Body",
        location=(0, 0, 1.55),
        scale=(0.62, 0.42, 0.82),
        material=mat_blue,
        bevel=0.15,
    )
    created.append(body)

    chest = add_cube(
        "MeleeMinion_ChestPlate",
        location=(0, -0.43, 1.65),
        scale=(0.42, 0.04, 0.45),
        material=mat_blue_dark,
        bevel=0.06,
    )
    created.append(chest)

    head = add_uv_sphere(
        "MeleeMinion_Head",
        location=(0, 0, 2.58),
        scale=(0.43, 0.43, 0.43),
        material=mat_blue,
    )
    created.append(head)

    helmet = add_cube(
        "MeleeMinion_Helmet",
        location=(0, -0.02, 2.88),
        scale=(0.48, 0.46, 0.16),
        material=mat_blue_dark,
        bevel=0.08,
    )
    created.append(helmet)

    eye_l = add_cube(
        "MeleeMinion_Eye_L",
        location=(-0.15, -0.40, 2.61),
        scale=(0.06, 0.025, 0.045),
        material=mat_metal,
        bevel=0.01,
    )
    eye_r = add_cube(
        "MeleeMinion_Eye_R",
        location=(0.15, -0.40, 2.61),
        scale=(0.06, 0.025, 0.045),
        material=mat_metal,
        bevel=0.01,
    )
    created.extend([eye_l, eye_r])

    leg_l = add_cube(
        "MeleeMinion_Leg_L",
        location=(-0.25, 0, 0.63),
        scale=(0.20, 0.23, 0.58),
        material=mat_blue_dark,
        bevel=0.08,
    )
    leg_r = add_cube(
        "MeleeMinion_Leg_R",
        location=(0.25, 0, 0.63),
        scale=(0.20, 0.23, 0.58),
        material=mat_blue_dark,
        bevel=0.08,
    )
    created.extend([leg_l, leg_r])

    foot_l = add_cube(
        "MeleeMinion_Foot_L",
        location=(-0.25, -0.12, 0.12),
        scale=(0.22, 0.33, 0.10),
        material=mat_blue_dark,
        bevel=0.04,
    )
    foot_r = add_cube(
        "MeleeMinion_Foot_R",
        location=(0.25, -0.12, 0.12),
        scale=(0.22, 0.33, 0.10),
        material=mat_blue_dark,
        bevel=0.04,
    )
    created.extend([foot_l, foot_r])

    arm_l = add_cube(
        "MeleeMinion_Arm_L",
        location=(-0.72, -0.02, 1.62),
        scale=(0.16, 0.20, 0.58),
        material=mat_blue,
        bevel=0.07,
    )
    arm_l.rotation_euler[1] = math.radians(-12)

    arm_r = add_cube(
        "MeleeMinion_Arm_R",
        location=(0.72, -0.02, 1.62),
        scale=(0.16, 0.20, 0.58),
        material=mat_blue,
        bevel=0.07,
    )
    arm_r.rotation_euler[1] = math.radians(12)
    created.extend([arm_l, arm_r])

    sword_handle = add_cylinder(
        "MeleeMinion_Sword_Handle",
        location=(0.92, -0.22, 1.55),
        radius=0.055,
        depth=0.62,
        material=mat_handle,
        vertices=8,
        rotation=(math.radians(35), 0, 0),
    )
    created.append(sword_handle)

    sword_blade = add_cube(
        "MeleeMinion_Sword_Blade",
        location=(1.02, -0.52, 1.96),
        scale=(0.07, 0.035, 0.52),
        material=mat_metal,
        bevel=0.025,
    )
    sword_blade.rotation_euler[0] = math.radians(35)
    created.append(sword_blade)

    sword_guard = add_cube(
        "MeleeMinion_Sword_Guard",
        location=(0.96, -0.33, 1.72),
        scale=(0.22, 0.035, 0.045),
        material=mat_metal,
        bevel=0.015,
    )
    sword_guard.rotation_euler[0] = math.radians(35)
    created.append(sword_guard)

    attack_origin = bpy.data.objects.new("AttackOrigin", None)
    attack_origin.empty_display_type = "SPHERE"
    attack_origin.empty_display_size = 0.12
    attack_origin.location = (1.05, -0.65, 2.05)
    bpy.context.scene.collection.objects.link(attack_origin)
    created.append(attack_origin)

    # Ranger dans collection
    for obj in created:
        for coll in list(obj.users_collection):
            if coll != collection:
                coll.objects.unlink(obj)
        try:
            collection.objects.link(obj)
        except RuntimeError:
            pass

    # Appliquer rotations et scales aux meshes
    bpy.ops.object.select_all(action="DESELECT")
    for obj in created:
        if obj.type == "MESH":
            obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Parent nommé comme le modèle final, origine au monde/sol
    parent = bpy.data.objects.new("BlueMeleeVisual", None)
    parent.empty_display_type = "PLAIN_AXES"
    parent.empty_display_size = 0.4
    parent.location = (0, 0, 0)
    collection.objects.link(parent)

    for obj in created:
        obj.parent = parent

    # Référence sol à ne pas exporter
    mat_floor = make_mat("MAT_Floor_Reference", (0.18, 0.18, 0.18, 1.0), roughness=0.8)
    floor = add_cube(
        "REF_Ground_DoNotExport",
        location=(0, 0, -0.025),
        scale=(2.5, 2.5, 0.02),
        material=mat_floor,
        bevel=0.0,
    )
    floor.hide_render = True

    # Lumière/caméra preview
    bpy.ops.object.light_add(type="AREA", location=(0, -5, 6))
    light = bpy.context.object
    light.name = "Preview_Light"
    light.data.energy = 450
    light.data.size = 5

    bpy.ops.object.camera_add(location=(4, -6, 4), rotation=(math.radians(60), 0, math.radians(36)))
    bpy.context.scene.camera = bpy.context.object

    print("BlueMeleeVisual créé.")
    print("Forward visuel supposé : -Y.")
    print("Avant export Roblox : sélectionne seulement BlueMeleeVisual et ses enfants, pas REF_Ground_DoNotExport.")
    print("Nom Roblox attendu : BlueMeleeVisual.")
    print("Dossier Roblox attendu : ServerStorage.Assets.Models.Minions.Blue.Melee")


create_blue_melee_visual()
