# Suivi partagé — GPT ↔ Jarvis

Dernière mise à jour : 24 juin 2026

Ce fichier est la source de vérité opérationnelle du projet. Tout assistant intervenant sur `GameTest` doit le lire avant de modifier le code, puis actualiser l'état réel et les tests.

## Priorité

1. Décisions les plus récentes de Lucas.
2. État réel des fichiers et résultats des tests Studio.
3. Ce suivi partagé.
4. Propositions techniques non encore intégrées.

## Vision active

- MOBA Roblox original inspiré du genre LoL.
- Objectif actif : architecture 5v5, trois lanes et jungle.
- Grande carte pensée pour évoluer vers le fog of war et le mobile.
- Contrôles AZERTY `ZQSD`.
- Pas de sorts QWER pour le moment : déplacement, caméra et auto-attaque d'abord.
- L'ancien prototype solo à une voie est abandonné et son code a été retiré.

## Principes techniques

- Le client envoie des intentions ; le serveur décide des dégâts, portées et cooldowns.
- Luau strict pour les nouveaux scripts lorsque possible.
- VS Code et Rojo sont les sources du code synchronisé.
- Aucun asset externe ou modèle gratuit non vérifié.
- Les systèmes doivent rester modulaires et testables séparément.

## Environnement

- Projet : `/Users/lucassimonnet/Dev/RobloxProjects/GameTest`.
- Rojo serveur et plugin Studio : `7.6.1`.
- Synchronisation VS Code → Rojo → Roblox Studio validée.
- Place de développement actuel : `/Users/lucassimonnet/Dev/RobloxProjects/GameTest/GameTest-editable.rbxlx`.
- Build Rojo réussi le 24 juin 2026 après la réinitialisation.
- Tous les fichiers `src/**/*.luau` ont été parsés et formatés avec StyLua sans erreur.

## Architecture réellement implémentée

### Partagé — `ReplicatedStorage.Modules`

- `SharedConstants.luau`
- `ChampionData.luau`
- `MinionData.luau`
- `JungleData.luau`

### Serveur — `ServerScriptService.Server`

- `services/Utility.luau`
- `services/UnitFactory.luau`
- `services/TeamService.luau`
- `services/ChampionService.luau`
- `services/VisionService.luau`
- `services/CombatService.luau`
- `services/TowerService.luau`
- `services/JungleService.luau`
- `services/MinionService.luau`
- `services/NexusService.luau`
- `services/MatchStateService.luau`
- `services/RemoteService.luau`

Le script `init.server.luau` vérifie la présence de `Workspace.Map` et démarre les services sans reconstruire la carte.

### Carte — Roblox Studio

- `GameTest-editable.rbxlx` contient la carte statique d'environ 1200 × 900 studs.
- La carte contient Top, Mid, Bot, les chemins Blue/Red, la rivière, six tours, deux Nexus, les spawns et cinq camps de jungle.
- `Workspace.Map` appartient à Studio : Move, Scale, Rotate, Terrain Editor, `⌘Z` et sauvegarde native.
- Rojo est explicitement configuré pour préserver les instances inconnues de Workspace et Lighting.
- `tools/generate_editable_place.mjs` est uniquement un générateur initial de secours ; il ne doit pas écraser une carte modifiée sans sauvegarde.

### Client — `StarterPlayerScripts.Client`

- `InputController.luau` : déplacement ZQSD relatif au regard.
- Caméra : système Roblox standard dans sa configuration par défaut, sans contrôleur personnalisé ni verrouillage de perspective.
- `AutoAttackController.luau` : sélection et demande d'attaque au clic gauche.
- `FogController.luau` : visibilité prototype par distance.
- `HudController.luau` : équipe, état de partie et barre de vie.
- `CombatFeedbackController.luau` : flash de dégâts, rayon d'auto-attaque et avertissement rouge quand le joueur est touché.

Le script `init.client.luau` démarre tous les contrôleurs.

## Fonctionnalités présentes dans le prototype

- Attribution équilibrée Blue/Red jusqu'à cinq joueurs par équipe prévue par les constantes.
- Caractéristiques de champion appliquées côté serveur.
- Dégâts, portée, équipe, vision et cooldown validés côté serveur.
- Vagues Blue et Red sur les trois lanes.
- Trois types de sbires générés par code.
- Tours qui ciblent automatiquement les ennemis.
- Nexus avec détection de victoire.
- Camps de jungle et respawn prototype.
- RemoteEvents créés automatiquement.
- Carte statique éditable dans Studio ; seules les unités dynamiques sont générées pendant Play.

## Test Play validé dans Roblox Studio

Le test Play du blockout du 24 juin 2026 a confirmé l'absence d'erreurs rouges et la présence de :

```text
[MOBA] Server started — 3 lanes, jungle, ZQSD client ready
[MOBA] Client started — ZQSD, default Roblox camera, attack and HUD ready
[MOBA] Match started
[MOBA] Wave 1 spawned
```

Les trois lanes convergent, les 12 tours attaquent, les neuf monstres de jungle apparaissent et le feedback de dégâts client fonctionne. Un test manuel du ressenti de déplacement reste utile.

## Non terminé

- animations complexes d'attaque ;
- barres de vie au-dessus des unités ;
- récompenses gold/XP ;
- respawn du champion ;
- vraie sélection de champion ;
- lobby et dix joueurs réels ;
- fog of war sécurisé ;
- compétences, objets, boutique et mini-map ;
- optimisation pour une carte de 2500 × 2500 studs ;
- contrôles mobiles.

## Prochaines actions

1. Effectuer le test Play et corriger toute erreur d'exécution.
2. Vérifier les proportions et chemins des trois lanes.
3. Tester une attaque à courte portée sur un sbire ou monstre.
4. Ajouter des barres de vie au-dessus des unités.
5. Ajouter gold et XP après validation du combat.

## Règle de transmission

Après chaque changement important, consigner : date, décision, fichiers modifiés, tests réellement effectués, erreurs ouvertes et prochaine action. Ne jamais déclarer une fonction terminée uniquement parce qu'elle figure dans le starter pack.

## Journal

### 24 juin 2026 — Jarvis

- Lecture complète du starter pack GPT.
- Ancienne arène solo supprimée à la demande de Lucas.
- Périmètre remplacé par le starter pack 5v5 à trois lanes.
- Architecture partagée, services serveur, génération de carte et contrôleurs client créés.
- Parsing StyLua et build Rojo réussis ; test Play Studio encore requis.
- Contrôles AZERTY corrigés selon les positions physiques QWERTY utilisées par Roblox.
- Contrôles de déplacement Roblox par défaut désactivés pour éviter le conflit AWSD/ZQSD.
- Caméra personnalisée supprimée ; caméra Roblox standard verrouillée en première personne.
- Décision suivante de Lucas : verrouillage première personne retiré et paramètres de caméra rétablis comme dans un projet neuf.
- Conversion vers le workflow Rojo partiellement géré : `MapBuilder` runtime retiré et place statique éditable créé.
- Carte désormais détenue par Studio ; Rojo ne gère que le code et préserve `Workspace.Map`.
- Diagnostic du test Play : Studio exécutait la place publiée au lieu de `GameTest-editable.rbxlx`, donc `Workspace.Map` manquait et le serveur ne créait pas `ReplicatedStorage.Remotes`.
- Attentes client sécurisées avec un délai et un avertissement explicite dans `AutoAttackController` et `HudController` ; place éditable reconstruite avec Rojo 7.6.1.
- Sauvegarde de sécurité créée avant blockout : `backups/GameTest-editable-before-blockout-20260624-174009.rbxlx`.
- Nouveau blockout Studio centré sur une arène 760 × 760 : Blue en bas-gauche, Red en haut-droite, Mid en diagonale, Top le long des bords gauche/haut et Bot le long des bords bas/droit.
- Neuf waypoints inversés par équipe et par lane ; rencontres mesurées à environ 6 studs sur Top, Mid et Bot.
- Douze tours positionnées, deux par lane et par équipe ; les 12 ont infligé des dégâts pendant le test automatisé Play.
- Jungle simplifiée à quatre camps symétriques par côté et un Dragon ; identifiants `SmallWolf`, `BigGolem` et `DragonPrototype` validés sans warning.
- Feedback de combat ajouté sans modifier l'autorité serveur : flash rouge, cible sélectionnée, rayon temporaire et HUD `-25` lors du test de dégâts joueur.
- Point encore ouvert : macOS refuse l'automatisation de `⌘S`. Lucas doit enregistrer manuellement la place Studio avant de la fermer ; le fichier disque n'inclut pas encore ce blockout tant que cette sauvegarde n'est pas faite.
