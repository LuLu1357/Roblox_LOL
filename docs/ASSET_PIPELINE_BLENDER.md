# Asset Pipeline Blender -> Roblox Studio

Ce document prepare l'integration progressive de modeles Blender dans le projet Roblox MOBA. Il ne remplace pas les systemes gameplay actuels : il fixe les conventions pour importer, ranger et brancher les futurs visuels sans casser le spawn, le combat, la selection, les healthbars ou la validation de map.

## Objectifs

- Garder le serveur autoritaire et les hitboxes gameplay separees des meshes visuels.
- Importer les assets Blender dans une structure stable sous `ServerStorage.Assets.Models`.
- Conserver les assets existants comme fallback pendant la migration.
- Permettre a un nouveau modele Blender d'etre ajoute sans deviner son nom, son dossier ou ses attachments.
- Tester chaque asset en Studio avant de l'utiliser dans une vraie partie.

## Audit actuel des assets

Le code Rojo du depot ne contient pas les modeles Studio. Les assets et la map sont dans `GameTest-editable.rbxlx`.

Assets existants detectes dans `ServerStorage.Assets.Models` :

```txt
Assets
└── Models
    ├── Towers
    │   ├── DragonTorchTowerVisual
    │   ├── toaaa
    │   └── jungleLanterVisual
    └── sbires
        ├── candidates
        │   └── candidates_sbire_piggy_MELEE
        ├── cleaned
        │   └── KorbloxMeleeVisual_clean
        ├── melee
        │   ├── PiggyMeleeVisual
        │   ├── RedMelee
        │   └── BlueMelee
        └── ranged
            ├── BlueRANGED
            ├── RedRANGED
            ├── PiggyFlyingMinion_legacy
            └── clean_candidates_empty
```

Map existante detectee dans `Workspace.Map` :

- `Towers` : 22 modeles, dont `BlueTopInnerTower`, `BlueTopOuterTower`, `RedTopOuterTower`, `RedTopInnerTower`, `BlueMidInnerTower`, `BlueMidOuterTower`, `RedMidOuterTower`, `RedMidInnerTower`, `BlueBotInnerTower`, `BlueBotOuterTower`, `RedBotOuterTower`, `RedBotInnerTower`, les towers d'inhibiteur et les towers de Nexus.
- `Nexus` : `BlueNexus`, `RedNexus`.
- `Inhibitors` : `BlueTopInhibitor`, `BlueMidInhibitor`, `BlueBotInhibitor`, `RedTopInhibitor`, `RedMidInhibitor`, `RedBotInhibitor`.
- `JungleCamps` : `BlueGolemTop`, `BlueWolfTop`, `BlueGolemBot`, `BlueWolfBot`, `RedGolemTop`, `RedWolfTop`, `RedGolemBot`, `RedWolfBot`, `Dragon`.

Services et attentes actuelles :

- `UnitFactory` cree les sbires et monstres jungle avec un `HumanoidRootPart` procedurale et un `Accent`. Ces parts portent les Attributes gameplay.
- `MinionVisualService` attache un `VisualModel` aux sbires. Il cherche maintenant d'abord les futurs chemins Blender dans `VisualConfig.AssetModels.Minions`, puis revient aux anciens assets sous `Assets/Models/sbires`.
- `MinionVisualService` accepte un `HumanoidRootPart` ou une `PrimaryPart` sur le modele visuel, clone le modele, supprime les scripts legacy, desactive les collisions du mesh et cree une `TargetHitbox`.
- `MinionAnimationService` existe mais n'est pas branche actuellement. S'il est utilise plus tard, il attendra `VisualModel.Animations.Arms` et `VisualModel.Animations.Attack`.
- `JungleService` utilise encore les monstres proceduraux de `UnitFactory`. Les modeles Blender jungle doivent donc etre prepares, mais leur branchement runtime sera une etape separee.
- `TowerService` deplace les towers placees dans `Workspace.Map.Towers` vers `Workspace.Units` au demarrage. Les towers doivent rester des `Model` avec Attributes gameplay, root/PrimaryPart valide et healthbar compatible.
- `CombatService` cherche `TowerLaserOrigin` dans `tower.VisualModel` pour placer le rayon de tir des towers. Si absent, il utilise la part la plus haute du visuel ou le root.
- `NexusService` deplace les modeles de `Workspace.Map.Nexus` et `Workspace.Map.Inhibitors` vers `Workspace.Units`, attache une healthbar et surveille la vie du Nexus.
- `MapValidatorService` verifie les comptes de towers, inhibitors, nexus, paths, spawns et jungle camps. Ne pas casser ces noms ou ces dossiers.

## Convention cible

Nouvelle convention a utiliser pour les imports Blender :

```txt
ServerStorage
└── Assets
    └── Models
        ├── Minions
        │   ├── Blue
        │   │   ├── Melee
        │   │   │   └── BlueMeleeVisual
        │   │   ├── Ranged
        │   │   │   └── BlueRangedVisual
        │   │   └── Siege
        │   │       └── BlueSiegeVisual
        │   └── Red
        │       ├── Melee
        │       │   └── RedMeleeVisual
        │       ├── Ranged
        │       │   └── RedRangedVisual
        │       └── Siege
        │           └── RedSiegeVisual
        ├── Jungle
        │   ├── Dragon
        │   │   └── Dragon
        │   ├── Golem
        │   │   └── Golem
        │   ├── Wolf
        │   │   └── Wolf
        │   └── SmallMonster
        │       └── SmallMonster
        ├── Structures
        │   ├── Towers
        │   │   ├── BlueTowerVisual
        │   │   └── RedTowerVisual
        │   ├── Inhibitors
        │   │   ├── BlueInhibitorVisual
        │   │   └── RedInhibitorVisual
        │   └── Nexus
        │       ├── BlueNexusVisual
        │       └── RedNexusVisual
        └── Props
            ├── Jungle
            ├── Base
            └── Shop
```

Les anciens dossiers restent valides pendant la migration :

```txt
Assets/Models/sbires
Assets/Models/Towers
```

## Configuration visuelle

Les chemins cibles sont centralises dans `src/shared/modules/VisualConfig.luau`.

Pour les sbires, `MinionVisualService` lit :

```lua
VisualConfig.AssetModels.Minions.Blue.Melee = {
    Path = "Assets/Models/Minions/Blue/Melee",
    ModelName = "BlueMeleeVisual",
}
```

Le chemin est relatif a `ServerStorage`. Tant que `ServerStorage.Assets.Models.Minions` n'existe pas, le service garde silencieusement le comportement actuel. Une fois ce dossier cree, si `ServerStorage.Assets.Models.Minions.Blue.Melee.BlueMeleeVisual` est absent ou invalide, le service affiche un warning clair et tente les assets legacy.

Les chemins jungle, structures et props sont documentes dans la meme table pour preparer les futurs branchements. Ils ne changent pas encore le gameplay.

## Workflow Blender -> Roblox Studio

1. Modeliser dans Blender avec une silhouette lisible de loin.
2. Placer l'origine au sol et au centre logique du modele pour les unites, au centre de la base pour les structures.
3. Orienter le modele pour que son avant corresponde au forward attendu en Studio. Apres import, un modele de sbire doit regarder dans sa direction de deplacement quand le root est tourne avec `CFrame.lookAt`.
4. Appliquer les transforms dans Blender avant export : scale, rotation, location.
5. Exporter en FBX ou glTF selon le resultat le plus propre dans Roblox Studio.
6. Importer dans Roblox Studio avec l'Asset Manager ou le 3D Importer.
7. Ranger le modele dans le dossier cible sous `ServerStorage.Assets.Models`.
8. Ajouter ou verifier la root part et les attachments attendus.
9. Desactiver les collisions des meshes visuels.
10. Tester en Play Solo avec `Workspace.Units` et les systems de combat.

## Regles generales

### Root, pivot et orientation

- Les unites doivent avoir une origine au sol, centre du modele.
- Les structures doivent avoir un pivot au centre de la base.
- Le root logique doit etre stable et facile a selectionner : `HumanoidRootPart` recommande, `PrimaryPart` accepte pour les visuels de minions.
- La rotation du root doit suffire a orienter correctement le modele. Eviter les rotations cachees dans des sous-modeles.
- Ne pas corriger une orientation par script si elle peut etre corrigee dans Blender ou Studio.

### Mesh visuel et hitbox logique

- Le mesh visuel ne decide pas du gameplay.
- Le gameplay utilise le root, les Attributes, les hitboxes simples et `Utility.getRoot`.
- Les meshes importes doivent avoir `CanCollide=false`, `CanTouch=false`, `CanQuery=false` sauf exception documentee.
- Les collisions doivent etre des parts simples separees : box, cylinder ou wedge simple.
- Les hitboxes de selection/targeting doivent etre simples, invisibles et nommees explicitement.

### Scripts et objets importes

- Aucun script legacy dans les modeles importes.
- Aucun `Script`, `LocalScript`, `ModuleScript`, vieux ZombieAI, Tool script ou son de test dans les visuels runtime.
- Les sons doivent etre ajoutes plus tard via un systeme audio propre, pas caches dans un mesh.
- Les animations doivent etre dans un dossier `Animations` si elles sont necessaires.

### CanCollide

- Minion mesh : `CanCollide=false`.
- Jungle monster mesh : `CanCollide=false`.
- Tower mesh : `CanCollide=false` si la collision est portee par une hitbox simple.
- Nexus/inhibitor mesh : `CanCollide=false` si une hitbox simple existe.
- Props decoratifs : `CanCollide=false` par defaut, sauf props de map qui bloquent vraiment le joueur.

### Attachments recommandes

- Tower : `TowerLaserOrigin`, obligatoire pour les tirs propres.
- Minion : `AttackOrigin` optionnel pour futur projectile/rayon.
- Jungle monster : `AttackOrigin` optionnel, `MouthOrigin` optionnel pour dragon.
- Nexus/Inhibitor : `VFXOrigin` optionnel pour destruction ou etat endommage.
- Healthbar : pas obligatoire. Le code attache actuellement la healthbar au root.

### Budgets triangles indicatifs

Ces budgets sont des objectifs de depart, a ajuster apres profiling Studio :

| Type | Budget conseille |
|---|---:|
| Minion melee/ranged | 1 500 a 3 000 triangles |
| Minion siege | 3 000 a 5 000 triangles |
| Petit monstre jungle | 2 000 a 5 000 triangles |
| Golem / wolf majeur | 4 000 a 8 000 triangles |
| Dragon | 10 000 a 15 000 triangles |
| Tower | 5 000 a 10 000 triangles |
| Inhibitor / Nexus | 6 000 a 12 000 triangles |
| Prop map simple | 500 a 3 000 triangles |

Pour mobile, privilegier des silhouettes fortes, des textures propres, peu de pieces separees et peu de materiaux.

## Regles par categorie

### Minion / monstre jungle

- Origine au sol, centre du modele.
- Mesh visuel `CanCollide=false`.
- Hitbox/root logique separe.
- Forward coherent avec le deplacement.
- Silhouette lisible de loin.
- Pas de scripts legacy dans les modeles importes.
- `HumanoidRootPart` invisible recommande dans le modele visuel.
- `PrimaryPart` doit pointer vers le root.
- Animations minimales conseillees : `Idle`, `Walk`, `Attack`, `Death` si disponible.

### Tower

- Modele optimise, peu de pieces separees.
- Base claire et lisible.
- Collision simple separee du mesh.
- Attachment `TowerLaserOrigin` place au point de tir.
- Root/PrimaryPart au centre de la base.
- Modele compatible healthbar, selection et Attributes gameplay.

### Nexus / inhibitor

- Pivot au centre de la base.
- Version Blue/Red identifiable au premier coup d'oeil.
- Prevoir plus tard un etat endommage ou detruit.
- Modele compatible healthbar/selection.
- Collision simple.
- Root/PrimaryPart stable.

### Props

- Ranger par biome ou usage : `Props/Jungle`, `Props/Base`, `Props/Shop`.
- Prefabs decoratifs sans script.
- Collision seulement si le prop bloque reellement la navigation.
- Garder les props gameplay critiques separes des props purement decoratifs.

## Checklist d'import Roblox Studio

- Le modele est dans le bon dossier `ServerStorage.Assets.Models...`.
- Le nom Roblox correspond exactement a la convention.
- Le pivot est correct.
- Le root existe et `PrimaryPart` est defini.
- Le mesh visuel ne collisionne pas.
- Les hitboxes simples existent si necessaire.
- Les attachments attendus sont presents.
- Aucun script legacy n'est dans le modele.
- Les materiaux/textures sont visibles en Play Solo.
- Le modele reste lisible avec la camera MOBA.
- La healthbar ne flotte pas trop haut ou trop bas.
- Le modele ne bloque pas le pathing sauf si c'est voulu.

## Checklist de test en jeu

- Lancer Rojo et ouvrir `GameTest-editable.rbxlx`.
- Importer le modele dans Studio.
- Placer le modele dans le dossier cible.
- Lancer Play Solo.
- Verifier que la console ne contient pas d'erreur critique.
- Verifier que `Workspace.Units` recoit bien les unites runtime.
- Verifier le spawn, le deplacement et la mort de l'unite ou de la structure.
- Verifier la healthbar.
- Verifier le combat : attaque, degats, feedback visuel.
- Verifier les performances avec plusieurs vagues ou plusieurs structures visibles.

## Checklists par asset

### Minions

| Asset | Nom Roblox attendu | Emplacement conseille | Pivot | Root / hitbox | Collision | Animations minimales | Attachments | Test en jeu |
|---|---|---|---|---|---|---|---|---|
| Blue melee | `BlueMeleeVisual` | `Assets/Models/Minions/Blue/Melee` | Sol centre | `HumanoidRootPart` ou `PrimaryPart`; `TargetHitbox` creee runtime | Mesh off | Idle, Walk, Attack | `AttackOrigin` optionnel | Spawn vague Blue, avance lane, attaque ennemi |
| Red melee | `RedMeleeVisual` | `Assets/Models/Minions/Red/Melee` | Sol centre | `HumanoidRootPart` ou `PrimaryPart`; `TargetHitbox` creee runtime | Mesh off | Idle, Walk, Attack | `AttackOrigin` optionnel | Spawn vague Red, avance lane, attaque ennemi |
| Blue ranged | `BlueRangedVisual` | `Assets/Models/Minions/Blue/Ranged` | Sol centre | `HumanoidRootPart` ou `PrimaryPart`; hitbox lisible | Mesh off | Idle, Walk, Attack | `AttackOrigin` conseille | Tire a distance, reste lisible |
| Red ranged | `RedRangedVisual` | `Assets/Models/Minions/Red/Ranged` | Sol centre | `HumanoidRootPart` ou `PrimaryPart`; hitbox lisible | Mesh off | Idle, Walk, Attack | `AttackOrigin` conseille | Tire a distance, reste lisible |
| Blue siege | `BlueSiegeVisual` | `Assets/Models/Minions/Blue/Siege` | Sol centre | `HumanoidRootPart` ou `PrimaryPart`; hitbox plus large | Mesh off | Idle, Walk, Attack | `AttackOrigin` conseille | Spawn vague siege, range correcte |
| Red siege | `RedSiegeVisual` | `Assets/Models/Minions/Red/Siege` | Sol centre | `HumanoidRootPart` ou `PrimaryPart`; hitbox plus large | Mesh off | Idle, Walk, Attack | `AttackOrigin` conseille | Spawn vague siege, range correcte |

### Jungle

| Asset | Nom Roblox attendu | Emplacement conseille | Pivot | Root / hitbox | Collision | Animations minimales | Attachments | Test en jeu |
|---|---|---|---|---|---|---|---|---|
| Dragon | `Dragon` | `Assets/Models/Jungle/Dragon` | Sol centre ou centre de base du corps | `HumanoidRootPart`, hitbox simple | Mesh off | Idle, Attack, Death | `AttackOrigin`, `MouthOrigin` optionnel | Camp Dragon spawn, aggro, leash, mort, respawn |
| Golem | `Golem` | `Assets/Models/Jungle/Golem` | Sol centre | `HumanoidRootPart`, hitbox simple | Mesh off | Idle, Attack, Death | `AttackOrigin` optionnel | Camp Golem spawn, attaque champion, donne reward |
| Wolf | `Wolf` | `Assets/Models/Jungle/Wolf` | Sol centre | `HumanoidRootPart`, hitbox simple | Mesh off | Idle, Run, Attack, Death | `AttackOrigin` optionnel | Camp Wolf spawn, aggro/leash propre |
| Small monster | `SmallMonster` | `Assets/Models/Jungle/SmallMonster` | Sol centre | `HumanoidRootPart`, hitbox simple | Mesh off | Idle, Attack, Death | Optionnel | Spawn comme add de camp plus tard |

### Structures

| Asset | Nom Roblox attendu | Emplacement conseille | Pivot | Root / hitbox | Collision | Animations minimales | Attachments | Test en jeu |
|---|---|---|---|---|---|---|---|---|
| Blue tower | `BlueTowerVisual` | `Assets/Models/Structures/Towers` | Centre base | Root/PrimaryPart dans le modele de tower map | Hitbox simple | Optionnel | `TowerLaserOrigin` obligatoire | Tower attaque minion ennemi, rayon part du bon point |
| Red tower | `RedTowerVisual` | `Assets/Models/Structures/Towers` | Centre base | Root/PrimaryPart dans le modele de tower map | Hitbox simple | Optionnel | `TowerLaserOrigin` obligatoire | Tower attaque minion ennemi, rayon part du bon point |
| Blue inhibitor | `BlueInhibitorVisual` | `Assets/Models/Structures/Inhibitors` | Centre base | Root/PrimaryPart stable | Hitbox simple | Etat detruit plus tard | `VFXOrigin` optionnel | Healthbar visible, peut mourir |
| Red inhibitor | `RedInhibitorVisual` | `Assets/Models/Structures/Inhibitors` | Centre base | Root/PrimaryPart stable | Hitbox simple | Etat detruit plus tard | `VFXOrigin` optionnel | Healthbar visible, peut mourir |
| Blue nexus | `BlueNexusVisual` | `Assets/Models/Structures/Nexus` | Centre base | Root/PrimaryPart stable | Hitbox simple | Etat detruit plus tard | `VFXOrigin` optionnel | Healthbar visible, fin de partie Red si detruit |
| Red nexus | `RedNexusVisual` | `Assets/Models/Structures/Nexus` | Centre base | Root/PrimaryPart stable | Hitbox simple | Etat detruit plus tard | `VFXOrigin` optionnel | Healthbar visible, fin de partie Blue si detruit |

## Premier asset test : BlueMeleeVisual

1. Dans Blender, creer le sbire melee Blue avec origine au sol, centre du modele.
2. Exporter en FBX ou glTF apres avoir applique scale/rotation/location.
3. Dans Roblox Studio, importer le modele.
4. Creer ou verifier ce dossier :

```txt
ServerStorage.Assets.Models.Minions.Blue.Melee
```

5. Nommer le modele importe exactement `BlueMeleeVisual`.
6. Ajouter une part root invisible nommee `HumanoidRootPart` si l'import n'en fournit pas.
7. Definir `BlueMeleeVisual.PrimaryPart = HumanoidRootPart`.
8. Mettre les meshes visuels en `CanCollide=false`, `CanTouch=false`, `CanQuery=false`.
9. Supprimer tout script ou son de test.
10. Lancer Play Solo et faire spawn une vague Blue.

Une fois le dossier `Assets/Models/Minions` cree, si le modele est absent ou invalide, `MinionVisualService` doit afficher un warning clair et utiliser les anciens visuels de `Assets/Models/sbires`.
