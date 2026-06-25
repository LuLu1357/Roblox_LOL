# Suivi partagé — GPT ↔ Jarvis

Dernière mise à jour : 25 juin 2026

Ce document est la source de vérité opérationnelle du projet `GameTest`. Tout assistant doit le lire avant une modification, vérifier l'état réel des fichiers et de Roblox Studio, puis consigner les changements et les tests réellement effectués.

## Objectif actuel

Construire un prototype MOBA Roblox original, jouable et lisible, inspiré du genre LoL sans en reproduire les contenus protégés.

Périmètre volontairement limité :

- carte 5v5 à trois lanes ;
- déplacement AZERTY `ZQSD` ;
- caméra Roblox standard ;
- auto-attaque et combat validés par le serveur ;
- vagues de sbires, tours, Nexus et jungle simple ;
- aucun sort QWER, boutique, ranked, skin, matchmaking ou nouveau champion pour l'instant.

## Décisions actives

1. Les décisions les plus récentes de Lucas priment sur les anciennes notes.
2. Le client envoie des intentions ; le serveur décide toujours des dégâts, portées et cooldowns.
3. Le code vit dans `src` et reste synchronisé par Rojo.
4. `Workspace.Map` appartient à Roblox Studio et doit rester éditable avec Move, Scale, Rotate, `⌘Z` et `⌘S`.
5. `tools/generate_editable_place.mjs` est uniquement un générateur initial de secours. Ne jamais le relancer sur la carte actuelle sans demande explicite de Lucas et sauvegarde préalable.
6. Aucun asset externe ne doit être importé sans validation.
7. Les ajouts doivent rester petits, testables et utiles au gameplay immédiat.
8. Les audits d'assets externes sont consignés dans `GPT/ASSET_AUDITS.md`.

## Environnement validé

- Projet local : `/Users/lucassimonnet/Dev/RobloxProjects/GameTest`.
- Place de développement : `GameTest-editable.rbxlx`.
- Projet Rojo : `default.project.json`.
- Rojo serveur et plugin Studio : `7.6.1`, protocole compatible.
- Roblox Studio MCP : configuré et fonctionnel pour inspecter la scène, l'Output et les tests Play.
- Dépôt GitHub privé : `https://github.com/LuLu1357/Roblox_LOL`.
- Branche publiée : `main`.
- Première publication : commit `150a59f` (`Initial MOBA blockout prototype`).
- Sauvegardes locales : dossier `backups/`, ignoré par Git.

## Architecture actuelle

### Partagé — `ReplicatedStorage.Modules`

- `SharedConstants.luau` : équipes, lanes, combat, vision, mouvement et noms des RemoteEvents.
- `ChampionData.luau` : statistiques du champion prototype.
- `MinionData.luau` : statistiques et composition des vagues.
- `JungleData.luau` : `SmallWolf`, `BigGolem` et `DragonPrototype`.

### Serveur — `ServerScriptService.Server`

- `Utility.luau` : racines, distances, équipes et santé.
- `UnitFactory.luau` : modèles visuels simples des unités dynamiques.
- `TeamService.luau` : attribution des équipes.
- `ChampionService.luau` : statistiques et apparition du joueur.
- `VisionService.luau` : visibilité prototype par distance.
- `CombatService.luau` : validation serveur des attaques, dégâts, cooldowns et feedback réseau.
- `TowerService.luau` : ciblage et attaque automatiques des tours.
- `MapValidatorService.luau` : validation non bloquante des bâtiments, chemins, spawns, camps et barres de vie.
- `JungleService.luau` : apparition, attaque et respawn des monstres.
- `MinionService.luau` : vagues et déplacement par waypoints.
- `NexusService.luau` : destruction du Nexus et victoire.
- `MatchStateService.luau` : états de partie.
- `RemoteService.luau` : création idempotente des RemoteEvents et validation des intentions client.

`init.server.luau` exige `Workspace.Map`, crée `Workspace.Units` si nécessaire, puis démarre les services. Il ne reconstruit jamais la carte pendant Play.

### Client — `StarterPlayerScripts.Client`

- `InputController.luau` : déplacement `ZQSD` relatif au regard.
- `AutoAttackController.luau` : sélection d'une cible et intention d'attaque au clic gauche.
- `CombatFeedbackController.luau` : flash rouge, rayon temporaire et avertissement HUD quand le joueur est touché.
- `FogController.luau` : visibilité prototype.
- `HudController.luau` : équipe, état du match et santé.

La caméra utilise le comportement Roblox standard, sans contrôleur personnalisé ni verrouillage de perspective.

## Blockout actuel de la carte

- Surface jouable : `760 × 760` studs, centrée autour de `(0, 0)`.
- Base Blue : bas-gauche ; Nexus `(-300, 300)` ; spawn joueur `(-325, 325)`.
- Base Red : haut-droite ; Nexus `(300, -300)` ; spawn joueur `(325, -325)`.
- Mid : diagonale directe entre les deux bases.
- Top : longe le côté gauche puis le côté supérieur.
- Bot : longe le côté inférieur puis le côté droit.
- Neuf waypoints par lane et par équipe ; les chemins Red sont les inverses exacts des chemins Blue.
- Vingt-deux tours : Outer, Inner et Inhibitor Tower sur chaque lane, plus deux Nexus Towers par équipe.
- Six inhibiteurs passifs et destructibles : Top, Mid et Bot pour chaque équipe. Aucun super-minion ni respawn d'inhibiteur.
- Jungle : quatre camps symétriques par côté au maximum et un seul objectif neutre, le Dragon en `(70, 70)`.
- Rivière simple en diagonale opposée à Mid.
- Quatre murs périphériques empêchent la sortie de l'arène.
- Aucun `MapBuilder` runtime ni `MapEditor` actif.

## Combat et autorité serveur

- Le clic client transmet uniquement la cible souhaitée.
- Le serveur vérifie le propriétaire du champion, le type des unités, les équipes, la vision, la distance et le cooldown.
- Une attaque acceptée applique les dégâts côté serveur puis diffuse `CombatFeedback` aux clients.
- Une tour cible normalement l'ennemi valide le plus proche.
- Si un champion attaque un champion allié sous une tour, un signal serveur partagé force l'aggro sur l'agresseur pendant 3 secondes, puis la tour revient à la cible valide la plus proche.
- Feedback présent : cible sélectionnée, flash rouge sur la victime, rayon bref entre attaquant et cible, écran rouge et montant des dégâts pour le joueur.
- Des barres de vie `MobaHealthBar` sont attachées aux champions, sbires, monstres, tours, inhibiteurs et Nexus.
- Aucun son externe ou animation complexe n'a été ajouté.

## Tests validés le 24 juin 2026

### Structure et build

- `GameTest-editable.rbxlx` sauvegardé avec le blockout actuel.
- XML de la place valide avec `xmllint`.
- `rojo build default.project.json` réussi.
- Sauvegarde préalable : `backups/GameTest-editable-before-map-v2-buildings-20260624-194238.rbxlx`.
- Carte confirmée dans Studio avec 22 tours, 6 inhibiteurs, 2 Nexus et 9 camps/monstres de jungle.

### Test Play Studio

Output attendu observé sans erreur rouge :

```text
[MOBA] Server started — 3 lanes, jungle, ZQSD client ready
[MOBA] Client started — ZQSD, default Roblox camera, attack and HUD ready
[MOBA] Match started
[MOBA] Wave 1 spawned
[MOBA] Map validation passed — 22 towers, 6 inhibitors, 2 Nexus
[MOBA] Health bar validation passed — 76 units checked
```

- Top, Mid et Bot avancent sur leurs trajectoires respectives.
- Les vagues opposées se rencontrent à environ 6 studs sur chaque lane.
- Top et Bot restent symétriques et longent les côtés de la carte.
- Les 22 tours sont présentes et les tours attaquent normalement la cible ennemie valide la plus proche.
- Test d'aggro spéciale réussi : l'agresseur champion a reçu 150 dégâts tandis qu'un minion ennemi plus proche est resté à 1000/1000.
- Après 3 secondes, la priorité spéciale expire et la tour revient au minion le plus proche.
- Les 6 inhibiteurs sont présents, ont une barre de vie et acceptent les dégâts validés serveur (`3500 → 3499` au test).
- Les identifiants de jungle sont valides et les neuf monstres apparaissent sans warning.
- Les offsets de formation `-4`, `0`, `4` sont présents ; melee devant et ranged derrière.
- Écart maximal des sbires à leur corridor : environ 8,4 studs ; ils ne traversent pas la jungle.
- Test de dégâts joueur : santé `650 → 625`, rayon présent et HUD `-25` visible.
- `CombatFeedbackGui`, `SelectedTarget` et le RemoteEvent `CombatFeedback` sont présents.

## Limites connues

- Le pathfinding est une succession simple de waypoints, sans évitement sophistiqué.
- Les offsets réduisent l'agglutination en déplacement, mais les minions peuvent encore se rapprocher pendant un combat.
- La vision reste un prototype client et n'est pas un fog of war sécurisé.
- Pas encore de respawn complet du champion, gold, XP ou sélection de champion.
- Pas de test multijoueur réel à dix joueurs ni de contrôle mobile.
- Les proportions et la vitesse doivent encore être évaluées manuellement en conditions de jeu prolongées.

## Prochaines actions recommandées

1. Faire une session manuelle de cinq minutes et noter uniquement les problèmes de distance, vitesse et lisibilité.
2. Ajuster les positions de tours et camps dans Studio si le ressenti le justifie, sans reconstruire la carte.
3. Vérifier visuellement que les 22 tours restent lisibles autour des bases sur plusieurs résolutions.
4. Décider plus tard si la destruction des objectifs doit être séquentielle ; ne pas ajouter ce système sans demande de Lucas.
5. Conserver gold, XP, sorts et super-minions hors périmètre pour l'instant.

## Règle de transmission

Après chaque changement important, consigner : date, décision, fichiers ou objets Studio modifiés, tests réellement exécutés, erreurs restantes et prochaine action. Ne jamais déclarer une fonction terminée uniquement parce qu'elle existe dans le code.

## Journal consolidé

### 25 juin 2026 - Jarvis

- Nouvel audit d'asset externe effectue sur `Japanese Sakura Stone Toro Lantern`, importe dans `Workspace`.
- Risque confirme dans Studio : `Workspace.Japanese Sakura Stone Toro Lantern.Vines.qPerfectionWeld` utilisait les attributs de `AutomaticModel`, dont `MarketplaceService`, `GetProductInfo`, `Players`, `PlayerAdded`, `PromptPurchase` et `123823600358195`.
- Sauvegarde locale creee avant nettoyage : `backups/GameTest-editable-before-asset-audit-lantern-20260625-125803.rbxlx`.
- Asset nettoye en decor uniquement : suppression de `qPerfectionWeld`, `AutomaticModel` et `ThumbnailCamera`; renommage en `JungleLanternVisual`.
- Les 25 `BasePart` de l'asset sont `Anchored = true`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false` et `CastShadow = false`.
- La `PointLight` de l'asset a ete limitee a `Brightness = 2`, `Range = 6`, `Shadows = false`.
- Aucun gameplay serveur, RemoteEvent, RemoteFunction ou connexion de gameplay n'a ete modifie.
- Rapport complet ajoute dans `GPT/ASSET_AUDITS.md`.
- Verifications reussies : inspection Studio MCP, `xmllint --noout GameTest-editable.rbxlx`, scan local des signatures suspectes et `rojo build default.project.json --output /tmp/GameTest-audit.rbxlx`.
- Test visuel de tour ajoute sans toucher au gameplay : `DragonTorchTowerVisual` nettoye depuis l'asset `239822675`, range dans `ServerStorage.Assets.Models.Towers`, puis clone en `VisualModel` uniquement sur `BlueTopOuterTower` et `RedTopOuterTower`.
- Sauvegarde locale avant ce test : `backups/GameTest-editable-before-dragon-torch-tower-test-20260625-131931.rbxlx`.
- Verification ciblee : 95 `BasePart`, 0 script, collisions/touch/query/shadow desactivees, `PointLight` limitee a `Brightness = 2` et `Range = 8`; attributs gameplay des deux tours inchanges.
- Generalisation controlee du visuel de tour : backup `backups/GameTest-editable-before-all-tower-visuals-laser-origin-20260625-134649.rbxlx`, puis `VisualModel` applique aux 22 tours de `Workspace.Map.Towers` en conservant l'offset relatif du test `BlueTopOuterTower`.
- Les 66 anciennes parts directes de tours sont invisibles et conservees comme hitbox/logique avec `CanQuery = true`; aucun attribut gameplay de tour n'a ete modifie.
- `TowerLaserOrigin` cree dans les 22 `VisualModel`; `CombatService` envoie cette origine visuelle optionnelle au client, et `CombatFeedbackController` l'utilise pour faire partir le rayon de la flamme avec fallback ancien.
- Test Play reussi : `Map validation passed`, `Health bar validation passed`, 22 tours runtime avec `VisualModel`, 22 barres de vie, anciennes parts invisibles, tour attaquant encore. Verification client : tir de `BlueTopOuterTower` avec origine a distance `0` de `TowerLaserOrigin` et environ `17.5` studs du `HumanoidRootPart`.
- Collision physique des tours corrigee sans changer le gameplay : backup `backups/GameTest-editable-before-tower-hitbox-flame-20260625-135734.rbxlx`, creation de 22 `TowerHitbox` invisibles `CanCollide = true`, `CanQuery = true`, et conservation des 22 `VisualModel` decoratifs sans collision.
- Flammes de tours renforcees : 22 `Fire` ajustes a `Size >= 7`, `Heat >= 9`, et 22 `PointLight` ajustes a `Brightness = 3.5`, `Range = 12`, couleur equipe. Test Play OK : healthbars visibles, tours attaquent, minions continuent a se battre, laser a distance `0` de `TowerLaserOrigin`, pas d'erreur console observee.
- Propagation manuelle depuis `BlueMidOuterTower` : backup `backups/GameTest-editable-before-propagate-tower-hitbox2-20260625-142348.rbxlx`, puis `TowerHit2box` ajoute aux 21 autres tours et `TowerHitbox` de base aligne sur les 22 tours.
- Dimensions/offsets verifies en Edit : `TowerHitbox` = `4, 14, 4` avec offset relatif Y `0.1471118927001953`; `TowerHit2box` = `10.99995231628418, 2.1499102115631104, 8.50000286102295` avec offset relatif Y `-6.77504825592041`.
- Verification ciblee : 22 tours, 22 `TowerHitbox`, 22 `TowerHit2box`, 0 ecart de taille/position/proprietes, 0 part de `VisualModel` collidable. Aucun attribut gameplay ou service serveur modifie.
- Nettoyage d'un candidat sbire : backup `backups/GameTest-editable-before-clean-drooling-zombie-minion-20260625-145533.rbxlx`, copie `Drooling Zombie` creee en `ServerStorage.Assets.Models.Minions.MeleeMinionVisual`, sans integration aux vagues.
- La copie `MeleeMinionVisual` contient 7 parts, `Humanoid`, `Animator`, `HumanoidRootPart` et 3 animations propres (`IdleAnimation`, `WalkAnimation`, `AttackAnimation`), avec 0 script, 0 module, 0 remote et 0 son. `Animator:LoadAnimation` reussi sur les 3 animations.
- Branchement runtime du visuel anime sur les sbires de lane dans `src/server/services/MinionService.luau` : helper `attachMinionVisual`, clone `ServerStorage.Assets.Models.Minions.MeleeMinionVisual` en `VisualModel`, weld au root gameplay, ancien visuel sphere/accent masque.
- Animation minions ajoutee sans changement de gameplay : `WalkAnimation` boucle pendant les deplacements, `IdleAnimation` a l'arret, `AttackAnimation` declenchee seulement quand `CombatService.tryAutoAttack` accepte l'attaque. Degats, vitesse, vie, ciblage et pathfinding inchanges.
- Test Studio Play : `rojo build` OK, 143 minions runtime observes avec `VisualModel`, 0 script dans les visuels, 0 part visuelle collidable/touch/query/anchored, 0 ancien visuel visible, healthbars presentes, walk et attack tracks en lecture, minions endommages et morts observes, aucune erreur console liee au visuel.
- Reset complet des visuels de sbires a la demande de Lucas : backup `backups/GameTest-editable-before-reset-minion-visuals-20260625-160428.rbxlx`, suppression des modeles de test `MeleeMinionVisual`, `RangedMinionVisual`, `Drooling Zombie`, `Pixy`, `The Goldhunter Warlord`, `Ud'zal`, `badAss sbire` et du modele sans nom dans `ServerStorage.Assets.Models.sbires`.
- `src/server/services/MinionService.luau` revenu au fonctionnement simple : plus de clone `VisualModel`, plus de reference `ServerStorage.Assets.Models.Minions`, plus de `Animator`, plus de `WalkAnimation`/`IdleAnimation`/`AttackAnimation`, plus de logs `[MOBA][MINION_VISUAL]`.
- Verification Studio/Edit et fichier local : dossiers `ServerStorage.Assets.Models.Minions` et `ServerStorage.Assets.Models.sbires` conserves vides ; seuls les 22 `VisualModel` de tours restent presents avec 22 `TowerHitbox`.
- Test Play apres reset : 36 sbires spawn initial, 36 healthbars, 36 sbires en mouvement, 0 `VisualModel` minion ; duel force BlueMelee/RedMelee confirme les attaques ; `BlueTopOuterTower` tue un `RedRanged` et garde `VisualModel` + `TowerHitbox`; console sans erreur.

### 24 juin 2026 — Jarvis

- Ancien prototype solo abandonné et remplacé par l'architecture MOBA 5v5 du starter pack GPT.
- Caméra personnalisée et verrouillage première personne retirés à la demande de Lucas ; caméra Roblox standard conservée.
- Workflow converti vers une carte statique détenue par Studio et du code détenu par Rojo.
- Incompatibilité Rojo corrigée en alignant serveur et plugin sur `7.6.1`.
- Mauvaise place Studio diagnostiquée : l'absence de `Workspace.Map` interrompait le serveur avant la création de `Remotes`.
- Attentes client sécurisées avec délais et warnings explicites.
- Sauvegarde locale créée avant le nouveau blockout et exclue de Git.
- Map reconstruite en blockout `760 × 760`, avec Top/Bot périphériques, Mid diagonale, 12 tours, jungle symétrique et neuf waypoints par chemin.
- Feedback de combat minimal ajouté sans réduire l'autorité serveur.
- Tests Play instrumentés réussis sur les trois lanes, les tours, la jungle et le feedback joueur.
- Place sauvegardée, build Rojo validé et projet publié dans le dépôt GitHub privé `LuLu1357/Roblox_LOL` sur `main`.
- Information obsolète corrigée : les barres de vie existaient déjà dans Studio mais n'étaient pas reflétées dans les anciens fichiers locaux ; elles sont désormais consolidées dans `Utility`, `UnitFactory`, `ChampionService`, `TowerService` et `NexusService`.
- Map V2 conservée sans reconstruction : Top/Bot périphériques, Mid diagonale et jungle inchangées car déjà conformes.
- Structure étendue à 22 tours, 6 inhibiteurs et 2 Nexus ; place sauvegardée après une copie de sécurité locale.
- Validateur de map ajouté et validé sans warning.
- Aggro de tour champion contre champion corrigée avec un signal serveur partagé ; priorité 3 secondes et fallback sur la cible la plus proche testés.
- Formation des sbires légèrement espacée avec trois offsets latéraux, sans pathfinding complexe.
