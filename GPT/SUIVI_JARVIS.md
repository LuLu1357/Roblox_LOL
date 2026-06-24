# Suivi partagé — GPT ↔ Jarvis

Dernière mise à jour : 24 juin 2026

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
- Douze tours : deux par lane et par équipe, décalées du centre de la trajectoire pour conserver une lecture claire.
- Jungle : quatre camps symétriques par côté au maximum et un seul objectif neutre, le Dragon en `(70, 70)`.
- Rivière simple en diagonale opposée à Mid.
- Quatre murs périphériques empêchent la sortie de l'arène.
- Aucun `MapBuilder` runtime ni `MapEditor` actif.

## Combat et autorité serveur

- Le clic client transmet uniquement la cible souhaitée.
- Le serveur vérifie le propriétaire du champion, le type des unités, les équipes, la vision, la distance et le cooldown.
- Une attaque acceptée applique les dégâts côté serveur puis diffuse `CombatFeedback` aux clients.
- Feedback présent : cible sélectionnée, flash rouge sur la victime, rayon bref entre attaquant et cible, écran rouge et montant des dégâts pour le joueur.
- Aucun son externe ou animation complexe n'a été ajouté.

## Tests validés le 24 juin 2026

### Structure et build

- `GameTest-editable.rbxlx` sauvegardé avec le blockout actuel.
- XML de la place valide avec `xmllint`.
- `rojo build default.project.json` réussi.
- Carte confirmée dans Studio avec 12 tours, 2 Nexus et 9 camps/monstres de jungle.

### Test Play Studio

Output attendu observé sans erreur rouge :

```text
[MOBA] Server started — 3 lanes, jungle, ZQSD client ready
[MOBA] Client started — ZQSD, default Roblox camera, attack and HUD ready
[MOBA] Match started
[MOBA] Wave 1 spawned
```

- Top, Mid et Bot avancent sur leurs trajectoires respectives.
- Les vagues opposées se rencontrent à environ 6 studs sur chaque lane.
- Top et Bot restent symétriques et longent les côtés de la carte.
- Les 12 tours ont attaqué une cible ennemie de test.
- Les identifiants de jungle sont valides et les neuf monstres apparaissent sans warning.
- Test de dégâts joueur : santé `650 → 625`, rayon présent et HUD `-25` visible.
- `CombatFeedbackGui`, `SelectedTarget` et le RemoteEvent `CombatFeedback` sont présents.

## Limites connues

- Le pathfinding est une succession simple de waypoints, sans évitement sophistiqué.
- Les minions peuvent s'agglutiner pendant les combats.
- La tour cible actuellement l'ennemi valide le plus proche, sans priorité avancée.
- La vision reste un prototype client et n'est pas un fog of war sécurisé.
- Pas encore de barres de vie au-dessus des unités.
- Pas encore de respawn complet du champion, gold, XP ou sélection de champion.
- Pas de test multijoueur réel à dix joueurs ni de contrôle mobile.
- Les proportions et la vitesse doivent encore être évaluées manuellement en conditions de jeu prolongées.

## Prochaines actions recommandées

1. Faire une session manuelle de cinq minutes et noter uniquement les problèmes de distance, vitesse et lisibilité.
2. Ajuster les positions de tours et camps dans Studio si le ressenti le justifie, sans reconstruire la carte.
3. Ajouter des barres de vie simples au-dessus des unités.
4. Corriger l'agglutination des sbires sans introduire un pathfinding complexe.
5. Ajouter gold et XP seulement après validation durable du combat de base.

## Règle de transmission

Après chaque changement important, consigner : date, décision, fichiers ou objets Studio modifiés, tests réellement exécutés, erreurs restantes et prochaine action. Ne jamais déclarer une fonction terminée uniquement parce qu'elle existe dans le code.

## Journal consolidé

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
