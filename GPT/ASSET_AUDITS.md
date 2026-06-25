# Audits d'assets Roblox

Derniere mise a jour : 25 juin 2026

Ce fichier est le registre Jarvis des packages, modeles et assets importes depuis Creator Store, Toolbox ou 3D Assets avant integration dans le MOBA.

Regle active :

- Un asset decoratif ne doit contenir aucun `Script`, `LocalScript` ou `ModuleScript`.
- Aucun asset importe ne doit etre connecte au gameplay automatiquement.
- Tout asset valide reste d'abord decoratif, ancre et sans collision inutile.
- Destination cible seulement apres validation : `ReplicatedStorage.Assets.Models.*` ou `ReplicatedStorage.Assets.VFX`, en tenant compte de Rojo.

## 25 juin 2026 - Japanese Sakura Stone Toro Lantern

Nom :

- Import initial : `Japanese Sakura Stone Toro Lantern`
- Nom nettoye : `JungleLanternVisual`
- SourceAssetId du modele : `87305112347556`

Usage recommande :

- `Jungle visual` ou petit prop decoratif de jungle.
- Ne pas utiliser comme `Tower visual`, `Nexus visual`, `Minion visual` ou `Champion prop`.
- Lisibilite MOBA : faible de tres loin ; acceptable seulement comme detail d'ambiance autour d'un camp.

Statut :

- Safe apres nettoyage.
- Refuse avant nettoyage, car le modele contenait un script actif et des attributs suspects.

Scripts trouves avant nettoyage :

- `Script` : 1, `Workspace.Japanese Sakura Stone Toro Lantern.Vines.qPerfectionWeld`
- `LocalScript` : 0
- `ModuleScript` : 0
- `RemoteEvent` / `RemoteFunction` : 0
- `require(...)` : 0 dans l'asset
- `loadstring` : 0
- HTTP direct : 0

Risque securite observe :

- Le script `qPerfectionWeld` lisait les attributs de `AutomaticModel`.
- `AutomaticModel` contenait les attributs `MarketplaceService`, `GetProductInfo`, `Players`, `PlayerAdded`, `PromptPurchase` et l'id `123823600358195`.
- Le code branchait dynamiquement `Players.PlayerAdded` puis appelait une methode issue des attributs. Pour un asset decoratif, c'est interdit.

Structure apres nettoyage :

- Modeles descendants : 5
- `Part` : 17
- `MeshPart` : 8
- `UnionOperation` : 0
- `Attachment` : 0
- `PointLight` : 1
- `ParticleEmitter` : 0
- `Sound` : 0
- `Decal` / `Texture` / `SurfaceAppearance` : 0
- `Camera` : 0
- `SpecialMesh` : 0
- Total `BasePart` : 25

Performance :

- 25 pieces, poids acceptable pour un prop unique.
- Toutes les pieces sont `Anchored = true`.
- Toutes les pieces sont `CanCollide = false`, `CanTouch = false`, `CanQuery = false`.
- Toutes les pieces sont `CastShadow = false`.
- La light a ete plafonnee a `Brightness = 2`, `Range = 6`, `Shadows = false`.
- Attention : ne pas dupliquer massivement ce prop sans reevaluer les lights.

Actions faites :

- Sauvegarde locale creee : `backups/GameTest-editable-before-asset-audit-lantern-20260625-125803.rbxlx`.
- Supprime `qPerfectionWeld`.
- Supprime `AutomaticModel`.
- Supprime `ThumbnailCamera`.
- Renomme le modele en `JungleLanternVisual`.
- Nettoie les collisions et shadows des 25 pieces.
- Ajoute dans la session Studio les attributs d'audit : `AuditStatus`, `AuditDate`, `RecommendedStorage`.
- Trace persistante dans ce fichier Markdown, car `game:SavePlace()` est refuse sur cette place locale sans `placeID` valide.
- Ne connecte rien au gameplay.
- Ne deplace pas encore l'asset vers `ReplicatedStorage`, car le projet Rojo ne mappe pas encore `ReplicatedStorage.Assets`.

Destination proposee :

- `ReplicatedStorage.Assets.Models.Jungle`

Verification :

- Studio MCP : `Workspace.JungleLanternVisual` existe, sans script descendant.
- XML local : `xmllint --noout GameTest-editable.rbxlx` reussi.
- Scan local : aucun `qPerfectionWeld`, `AutomaticModel`, `PromptPurchase`, `MarketplaceService` ou `123823600358195` restant dans `GameTest-editable.rbxlx`.
- Build : `rojo build default.project.json --output /tmp/GameTest-audit.rbxlx` reussi.

Decision Jarvis :

- Asset autorise uniquement comme decor de jungle nettoye.
- Ne pas l'utiliser comme objectif de gameplay.
- Avant integration propre dans `ReplicatedStorage.Assets.Models.Jungle`, ajouter ou confirmer une strategie Rojo pour les assets Studio-owned afin d'eviter que Rojo supprime les instances inconnues.

## 25 juin 2026 - DragonTorchTowerVisual

Nom :

- Import initial : `Model`
- ID : `239822675`
- Nom nettoye : `DragonTorchTowerVisual`

Statut :

- Safe apres nettoyage.
- Test place uniquement sur `BlueTopOuterTower` et `RedTopOuterTower`.

Actions faites :

- Sauvegarde locale creee : `backups/GameTest-editable-before-dragon-torch-tower-test-20260625-131931.rbxlx`.
- Modele range dans `ServerStorage.Assets.Models.Towers.DragonTorchTowerVisual`.
- Aucun `Script`, `LocalScript`, `ModuleScript`, `require(...)` ou `loadstring` detecte apres nettoyage.
- 95 `BasePart` nettoyees : `Anchored = true`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, `CastShadow = false`.
- `PointLight` limitee a `Brightness = 2`, `Range = 8`.
- Clones decoratifs `VisualModel` ajoutes seulement sous `Workspace.Map.Towers.BlueTopOuterTower` et `Workspace.Map.Towers.RedTopOuterTower`.
- Attributs gameplay des tours verifies inchanges : `Team`, `UnitType`, `Health`, `MaxHealth`, `AttackDamage`, `AttackRange`.

Decision Jarvis :

- Bon candidat visuel pour test, mais encore un peu lourd pour generalisation immediate sur 22 tours.
- Evaluer visuellement ces 2 tours avant de dupliquer partout ou chercher une version plus legere.

## 25 juin 2026 - Generalisation DragonTorchTowerVisual

Statut :

- Applique aux 22 tours existantes de `Workspace.Map.Towers`.
- Les tours gameplay restent les modeles existants ; `VisualModel` reste decoratif.

Actions faites :

- Sauvegarde locale creee : `backups/GameTest-editable-before-all-tower-visuals-laser-origin-20260625-134649.rbxlx`.
- Offset relatif repris depuis `BlueTopOuterTower.VisualModel`.
- `VisualModel` remplace proprement l'ancien enfant du meme nom sur chaque tour.
- 22 `TowerLaserOrigin` crees dans les visuels, proches de la flamme/lumiere.
- Anciennes parts directes des tours rendues invisibles : 66 parts, `CanQuery = true`, sans collision/touch/shadow.
- `CombatService` et `CombatFeedbackController` utilisent une origine visuelle optionnelle pour le rayon de tour, sans changer les degats, range, cooldown ou ciblage.

Verification :

- Edit : 22 tours, 22 `VisualModel`, 22 `TowerLaserOrigin`, 0 ancienne part visible, max light `Brightness = 2`, max `Range = 8`.
- Play : map validation OK, health bar validation OK, 22 tours runtime avec healthbars.
- Tir de test : `BlueTopOuterTower` envoie une origine exactement sur `TowerLaserOrigin` (`distance = 0`) et non sur le centre logique invisible.

Decision Jarvis :

- Generalisation acceptee pour prototype.
- Surveiller la performance mobile plus tard, car chaque tour ajoute environ 95 `BasePart`.

## 25 juin 2026 - Hitbox et flamme des tours

Statut :

- Correction appliquee aux 22 tours avec `VisualModel`.
- Gameplay de tour conserve : attributs de degats, range, cooldown, team et health non modifies.

Actions faites :

- Sauvegarde locale creee : `backups/GameTest-editable-before-tower-hitbox-flame-20260625-135734.rbxlx`.
- 22 `TowerHitbox` invisibles creees directement sous les tours : `Size = 7,14,7`, `CanCollide = true`, `CanQuery = true`.
- `VisualModel` conserve decoratif : 2090 `BasePart` visuelles sans collision/touch/query/shadow.
- 22 anciennes parts directes hors `VisualModel` et hors `TowerHitbox` restent invisibles et non-collidables.
- 22 flammes agrandies : `Fire.Size >= 7`, `Fire.Heat >= 9`.
- 22 `PointLight` augmentees : `Brightness = 3.5`, `Range = 12`, couleur equipe.

Verification :

- Edit : 22 tours, 22 hitboxes solides, 22 flammes, 22 lights, 0 visual part collidable.
- Play : map validation OK, health bar validation OK, 22 hitboxes runtime solides, 22 healthbars, minions endommages et tour attaquant encore.
- Laser : tir de `BlueTopOuterTower` avec origine a distance `0` de `TowerLaserOrigin`.

Decision Jarvis :

- Collision corrigee pour le prototype.
- A surveiller plus tard : interaction fine joueur/tour et ressenti de largeur de hitbox en session manuelle.

## 25 juin 2026 - Audit leger modeles sbires animes

Emplacement analyse :

- `ServerStorage.Assets.Models.sbires`

Statut global :

- Aucun modele n'est safe tel quel pour integration gameplay.
- Tous les candidats contenant du code doivent rester hors gameplay jusqu'au nettoyage.

Resultat court :

- Modele sans nom : a nettoyer, 8 parts, 6 scripts/localscripts, 9 animations, 9 sons.
- `Drooling Zombie` : a nettoyer/refuser tel quel, 7 parts, scripts + modules IA avec `require`, 10 animations.
- `Pixy` : refuse tel quel, 37 parts dont 30 `MeshPart`, 15 scripts/localscripts, `qPerfectionWeld`, IA, respawn, jumpscare/kill scripts, 80 animations, 18 sons.
- `The Goldhunter Warlord (245) Health: 91852 of 91852` : refuse, 15 scripts/localscripts, scripts `Teleport`, `Badge`, `Deadly`, attaques speciales, 9 animations.
- `Ud'zal` : a nettoyer, 16 parts dont 14 `MeshPart`, 3 scripts/localscripts, 27 animations, 3 particules, 9 sons.

Actions recommandees :

- Supprimer tous les `Script`, `LocalScript` et `ModuleScript` avant toute utilisation.
- Garder seulement le rig visuel, `Humanoid`/`Animator` et les `Animation` utiles si l'animation est voulue.
- Desactiver collisions/touch/query sur les parts visuelles avant integration.
- Eviter `Pixy` et `The Goldhunter Warlord` comme sbires de lane ; chercher ou nettoyer un modele plus leger.

## 25 juin 2026 - Nettoyage Drooling Zombie vers MeleeMinionVisual

Source :

- `ServerStorage.Assets.Models.sbires.Drooling Zombie`
- Copie propre : `ServerStorage.Assets.Models.Minions.MeleeMinionVisual`

Backup :

- `backups/GameTest-editable-before-clean-drooling-zombie-minion-20260625-145533.rbxlx`

Actions faites :

- Copie source dupliquee sans integration gameplay.
- Tous les scripts de la copie supprimes : 3 `Script`, 0 `LocalScript`, 6 `ModuleScript`.
- 0 `RemoteEvent` et 0 `RemoteFunction` trouves dans la copie.
- 1 `Sound` supprime.
- IA zombie, modules `ROBLOX_*`, script `Animate` et comportements source retires de la copie.
- 3 animations utiles conservees dans `Animations` : `IdleAnimation`, `WalkAnimation`, `AttackAnimation`.
- `Humanoid`, `Animator` et `HumanoidRootPart` presents ; `HumanoidRootPart` defini comme `PrimaryPart`.
- 7 `BasePart` ajustees : `Anchored = false`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, `Massless = true`.

Verification :

- Copie finale : 0 `Script`, 0 `LocalScript`, 0 `ModuleScript`, 0 remote, 0 son, 3 animations, 7 parts.
- `Animator:LoadAnimation` reussi sur `IdleAnimation`, `WalkAnimation` et `AttackAnimation`.
- Aucun service gameplay ni vague de minions modifie.

Decision Jarvis :

- Candidat propre utilisable pour un futur test visuel de sbire melee.
- Ne pas brancher aux vagues avant un test visuel d'echelle, orientation, vitesse d'animation et lisibilite de loin.

Integration runtime du 25 juin 2026 :

- `MeleeMinionVisual` est clone en `VisualModel` sur les sbires de lane par `MinionService`.
- Le clone runtime utilise `AnimationController + Animator`, afin d'eviter que le `Humanoid` du visuel reactive les collisions.
- `WalkAnimation` joue pendant le deplacement, `IdleAnimation` a l'arret et `AttackAnimation` lors d'une attaque acceptee par `CombatService.tryAutoAttack`.
- Test Play : 143 minions observes avec visuel, 0 script dans les `VisualModel`, 0 collision/touch/query sur les parts visuelles.
