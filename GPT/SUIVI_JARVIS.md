# Rapport d'Analyse du Projet MOBA

*Ce rapport a été généré suite à une analyse automatisée du code source.*

## 1. Architecture Générale

Le projet est bien structuré sur une architecture Client-Serveur-Partagé classique. La séparation des responsabilités est claire :
- **`src/server`** : Contient toute la logique de jeu (services). L'utilisation d'un `init.server.luau` pour charger les services est une bonne pratique.
- **`src/client`** : Gère l'interface utilisateur et les contrôles, avec une structure de contrôleurs (MVC-like).
- **`src/shared`** : Centralise les données et configurations partagées (`MinionData`, `ItemData`, `SharedConstants`), ce qui est excellent pour la maintenance.

La communication est gérée par un `RemoteService` centralisé, qui agit comme un point d'entrée unique pour les RemoteEvents et RemoteFunctions, une pratique robuste qui simplifie la gestion du réseau.

## 2. Points Forts

- **Architecture Solide :** La structure de services sur le serveur est modulaire et facile à comprendre. Chaque service a un rôle bien défini (en théorie).
- **Code Orienté Données :** L'utilisation de `ModuleScript` dans `src/shared` pour définir les caractéristiques des sbires, champions et objets rend le jeu facile à équilibrer et à étendre sans modifier la logique de base.
- **Séparation Client/Serveur :** La distinction entre les tâches du client (affichage, input) et du serveur (logique, autorité) est bien respectée.

## 3. Axes d'Amélioration (Qualité du Code)

- **"God Script" - `AbilityService.luau` :**
  - **Problème :** Le service, et plus particulièrement la fonction `castAbility`, est un énorme bloc de `if/elseif/else` qui gère toutes les compétences du jeu.
  - **Impact :** C'est très difficile à maintenir, à déboguer et à étendre. Ajouter une nouvelle compétence complexifie davantage le script.
  - **Suggestion :** Refactoriser en utilisant un patron de conception "Strategy" ou "Component". Chaque compétence pourrait être son propre `ModuleScript` avec une méthode `Cast`, et `AbilityService` se contenterait de charger et d'exécuter le bon module.

- **Duplication de Code - `ShopService.luau` :**
  - **Problème :** Les fonctions `buyItem`, `sellItem`, et `craftItem` contiennent beaucoup de code dupliqué pour vérifier l'état du joueur, la distance, et pour logger les actions.
  - **Impact :** Rend le code plus verbeux et augmente le risque d'erreurs si une modification n'est pas répercutée partout.
  - **Suggestion :** Extraire cette logique répétitive dans des fonctions d'aide internes au module (ex: `canPlayerInteractWithShop`, `logShopAction`).

## 4. Axes d'Amélioration (Performances)

- **Fuite de Mémoire Critique - `ChampionService.luau` :**
  - **Problème :** Dans la fonction `setupCharacter`, plus d'une dizaine de connexions d'événements (`:GetAttributeChangedSignal(...):Connect(...)`) sont créées pour le débogage. **Ces connexions ne sont jamais déconnectées.**
  - **Impact :** À chaque respawn d'un joueur, de nouvelles connexions sont ajoutées sans que les anciennes soient supprimées. Cela va provoquer une augmentation continue de l'utilisation de la mémoire du serveur, menant inévitablement à des lags et des crashs.
  - **Suggestion :** Stocker toutes les connexions dans une table et les déconnecter dans une fonction de nettoyage (`cleanupCharacter`) qui est appelée à la mort du personnage.

- **Goulot d'Étranglement - `MinionService.luau` :**
  - **Problème :** L'IA des sbires utilise `task.spawn` pour créer un nouveau thread pour chaque sbire (`runMinionAI`).
  - **Impact :** Cette approche ne passe pas à l'échelle. Avec des vagues de 6-7 sbires par lane, pour 3 lanes et 2 équipes, on arrive vite à plus de 40 threads qui tournent en parallèle pour les sbires seuls. Le `task-scheduler` de Roblox va peiner, causant des baisses de framerate serveur.
  - **Suggestion :** Migrer vers un modèle centralisé. Avoir une seule boucle de jeu (par exemple dans le `MinionService` sur un `Heartbeat`) qui itère sur tous les sbires et met à jour leur état. C'est beaucoup plus performant.

- **Fuites de Mémoire Côté Client (Potentiel) - `HudController.luau` et autres :**
  - **Problème :** Plusieurs contrôleurs client se connectent à des événements sur le modèle du personnage. Il n'est pas clair si ces connexions sont nettoyées lors du respawn.
  - **Impact :** Similaire à la fuite côté serveur, cela peut dégrader les performances du client au fil de la partie.
  - **Suggestion :** Adopter un système de `Maid` ou de nettoyage manuel pour toutes les connexions d'événements liées à un personnage.

## 5. Recommandations et Prochaines Étapes

1.  **Priorité #1 - Corriger les Fuites de Mémoire :** La fuite dans `ChampionService` est critique. Il faut implémenter un système de déconnexion pour les événements. C'est la tâche la plus urgente car elle garantit la stabilité du serveur.

2.  **Priorité #2 - Refactoriser l'IA des Sbires :** Remplacer le modèle `un-thread-par-sbire` par une boucle de mise à jour centralisée dans `MinionService`. Cela apportera un gain de performance majeur et rendra le jeu scalable.

3.  **Priorité #3 - Refactoriser `AbilityService` :** Commencer à extraire la logique d'une ou deux compétences dans leurs propres modules pour rendre le système plus maintenable à long terme.

---

# Documentation Fonctionnelle du Projet

*Ce rapport décrit le fonctionnement des principaux systèmes de jeu.*

## 1. Cycle de Vie d'une Partie (Match Lifecycle)

Le cycle de vie du jeu est orchestré par le `MatchStateService`.
1.  **Initialisation :** Au démarrage du serveur (`init.server.luau`), tous les services sont initialisés.
2.  **Attente :** Le `MatchStateService` attend que les joueurs se connectent et que les conditions de démarrage soient remplies.
3.  **Démarrage du Match :** La fonction `startMatch` est appelée. Cet état déclenche les logiques de jeu principales. Notamment, le `MinionService` commence sa boucle (`MinionService.start`) pour faire apparaître les vagues de sbires à intervalles réguliers (`SharedConstants.MATCH.MINION_WAVE_INTERVAL`).
4.  **Fin de Match :** Lorsqu'un Nexus est détruit (`NexusService`), il appelle `MatchStateService.endMatch`. Cela met fin à la partie, arrête le spawn des sbires et affiche l'écran de fin de partie.

## 2. Création des Unités (Unit Factory)

La création d'entités dans le jeu suit deux logiques distinctes :

-   **Unités non-joueurs (Sbires, Monstres) :** Celles-ci sont créées par le `UnitFactory`. Ce service utilise le "Factory Pattern" pour instancier un modèle de base, puis lui applique les statistiques et attributs définis dans les modules de `src/shared` (ex: `MinionData`).
-   **Champions (Joueurs) :** La création des champions est gérée par le `ChampionService` et contourne l'UnitFactory. Lorsqu'un joueur choisit un champion, le service prend le `Player.Character` de base de Roblox et le transforme en champion : il lui ajoute toutes les statistiques de jeu (`Health`, `Mana`, `AttackDamage`, etc.) sous forme d'Attributs, le lie aux systèmes de compétences et d'inventaire.

## 3. Intelligence Artificielle des Sbires (Minion AI)

L'IA des sbires est contenue entièrement dans `MinionService`.
1.  **Déplacement :** Les sbires ne font pas de pathfinding dynamique. Ils suivent une série de `Waypoints` (des `Parts` invisibles) prédéfinis pour chaque lane. La fonction `moveToward` les déplace d'un point au suivant.
2.  **Ciblage :** Dans sa boucle principale (`runMinionAI`), un sbire recherche des cibles via `findNearestEnemy`. Il scanne toutes les unités dans `Workspace.Units` dans un rayon défini (`TARGET_SEARCH_RANGE`).
3.  **Logique de Décision :**
    - S'il n'a pas de cible, il avance vers le prochain waypoint.
    - S'il trouve une cible, il la poursuit.
    - Si la cible est à portée d'attaque, il arrête de bouger et appelle `CombatService.tryAutoAttack`.
    - Si sa cible meurt ou sort de portée (`TARGET_DROP_RANGE`), il recherche une nouvelle cible. S'il n'en trouve pas, il reprend son chemin vers les waypoints.

## 4. Système de Combat (Combat & Abilities)

Le combat est géré par deux services principaux :

-   **`CombatService` :** C'est le service central pour tous les dégâts.
    - `tryAutoAttack` gère les attaques de base, en vérifiant la portée et le cooldown.
    - `applyDamage` est la fonction clé. Elle reçoit une source, une cible et un montant de dégâts. Elle calcule les dégâts finaux (en prenant en compte les résistances futures), réduit la vie de la cible, et si la vie tombe à zéro, elle appelle `handleDeath`.
    - `handleDeath` est responsable de lancer le processus de mort, qui inclut l'appel à `EconomyProgressionService` pour donner de l'or/XP.
-   **`AbilityService` :** Gère la logique complexe des compétences.
    - La fonction `castAbility` est appelée par le client via `RemoteService`.
    - Elle contient la logique unique de chaque compétence (dégâts de zone, projectiles, buffs/debuffs).
    - Pour les compétences qui infligent des dégâts, elle appelle à son tour `CombatService.applyDamage`, assurant que tous les dégâts passent par le même système centralisé.

## 5. Économie et Progression

La progression du joueur est gérée par `EconomyProgressionService`.
-   **Récompenses :** Lorsque `CombatService` confirme une mort (`handleDeath`), il notifie `EconomyProgressionService`.
-   **Attribution d'Or/XP :** La fonction `awardKillRewards` attribue de l'or et de l'expérience au joueur qui a fait le kill (et potentiellement aux alliés proches).
-   **Montée de Niveau :** Le service vérifie si l'XP accumulée dépasse le seuil pour le niveau suivant (`tryLevelUp`) et, si c'est le cas, augmente le niveau du joueur et améliore ses statistiques de base.

Le `ShopService` gère l'autre aspect de la progression : les objets.
-   `buyItem` vérifie si le joueur a assez d'or et se trouve près de la boutique.
-   `applyItemStats` modifie directement les attributs du champion pour lui ajouter les statistiques de l'objet. L'inventaire et les stats totales sont donc toujours synchronisés.

## 6. Communication Client-Serveur et UI

-   **`RemoteService` :** C'est la seule porte d'entrée et de sortie pour la communication réseau. Toutes les actions du client (lancer une compétence, acheter un objet, se déplacer) passent par un `RemoteEvent` ou `RemoteFunction` unique géré par ce service. Le `RemoteService` valide la requête et la redirige vers le service serveur approprié. C'est une architecture sécurisée et organisée.
-   **`HudController` (et autres contrôleurs client) :** Le client affiche les informations de jeu de deux manières :
    1.  **En écoutant les attributs :** L'UI (`HudController`) se "lie" directement aux attributs du modèle du champion (ex: `Health`, `MaxHealth`, `Mana`). Comme ces attributs sont répliqués automatiquement par Roblox, l'UI se met à jour en temps réel sans code réseau manuel.
    2.  **En écoutant des événements serveur :** Pour des événements ponctuels (ex: "Vous avez reçu de l'or"), le serveur utilise `RemoteService` pour envoyer un événement au client concerné, qui met alors à jour l'UI.

---

15:25:20.497  RAPPORT COMPLET D'ANALYSE DU PROJET ROBLOX
Projet analyse : jeu MOBA type League of Legends
Mode d'analyse : Edit + tentative runtime
Note : SceneAnalysisService n'est pas active dans cette session, donc les mesures runtime avancees de triangles/draw calls/memoire VM/audio chargee n'ont pas pu etre recuperees. Le rapport ci-dessous combine l'exploration complete du DataModel et une analyse statique detaillee.

1) VUE D'ENSEMBLE
Le projet est un MOBA complet avec une architecture serveur/client bien separee. On retrouve les composants essentiels du genre :
- 3 lanes : Top, Mid, Bot
- 2 equipes : Blue et Red
- Towers, inhibitors et nexus pour chaque equipe
- Camps de jungle : Dragon, Golems, Wolves/Loups
- Zones de shop
- Systemes de champions, minions, combat, gold, XP, shop, recall, vision, nexus et etats de match

Le projet est deja structure comme un vrai framework de jeu : les donnees sont dans ReplicatedStorage, la logique serveur dans ServerScriptService, les controllers client dans StarterPlayerScripts, et les assets/modeles dans ServerStorage.

2) COMPOSITION GLOBALE DU DATA MODEL
Services principaux analyses : Workspace, ReplicatedStorage, ServerScriptService, ServerStorage, StarterGui, StarterPlayer, Lighting, SoundService, Teams, TextChatService, ReplicatedFirst, StarterPack.

Nombre total approximatif d'instances scannees : 7 437
Repartition par service :
- Workspace : 4 064 descendants
- ServerStorage : 3 294 descendants
- ServerScriptService : 23 descendants
- StarterPlayer : 18 descendants
- Lighting : 14 descendants
- ReplicatedStorage : 8 descendants
- TextChatService : 4 descendants
- StarterGui : 0 descendant
- SoundService : 0 descendant
- StarterPack : 0 descendant
- ReplicatedFirst : 0 descendant
- Teams : 0 descendant

Classes les plus presentes :
- Part : 3 023
- Decal : 1 042
- Snap : 998
- WedgePart : 644
- ManualWeld : 506
- Weld : 348
- Model : 155
- Attachment : 92
- CornerWedgePart : 69
- Motor6D : 54
- Folder : 52
- PointLight : 50
- ModuleScript : 48
- CharacterMesh : 45
- WeldConstraint : 44
- Animation : 32
- Fire : 24
- Script : 20
- MeshPart : 13
- Humanoid : 9

3) WORKSPACE / MAP
Workspace contient principalement :
- Map : 4 055 descendants
- Environment : 4 descendants
- Terrain : present mais sans descendants scannes
- Units : dossier vide en edition, probablement rempli dynamiquement pendant la partie
- Camera

La map contient une structure MOBA claire :
- Lanes Top/Mid/Bot
- Bases Blue/Red
- Towers par lane et par equipe
- Inhibitors Blue/Red
- Nexus Blue/Red
- Camps de jungle
- Zones shop
- Elements environnementaux

Points importants :
- Les towers sont tres detaillees : la plupart des towers dans Workspace ont environ 177 descendants chacune.
- Les VisualModel de towers ont environ 170 descendants chacun.
- Le dossier Units est vide en edit mode, ce qui indique que les unites sont probablement creees par scripts pendant le runtime.
- La map utilise beaucoup de Parts, WedgeParts, Decals, Welds et Snap joints.

4) SERVERSTORAGE / ASSETS
ServerStorage contient 3 294 descendants, principalement des modeles de tours et de sbires.

Assets importants detectes :
- Assets.Models.Towers.toaaa : modele tres volumineux, environ 2 556 descendants
- Assets.Models.Towers.DragonTorchTowerVisual : environ 169 descendants
- Assets.Models.Towers.jungleLanterVisual
- Assets.Models.sbires.melee.PiggyMeleeVisual
- Assets.Models.sbires.melee.RedMelee
- Assets.Models.sbires.melee.BlueMelee
- Assets.Models.sbires.ranged.BlueRANGED
- Assets.Models.sbires.ranged.RedRANGED
- Assets.Models.sbires.cleaned.KorbloxMeleeVisual_clean
- Assets.Models.sbires.candidates avec plusieurs modeles candidats/legacy

Observation :
Les modeles detailles de minions existent dans ServerStorage, mais l'analyse de l'architecture indique que le systeme actuel cree aussi des visuels proceduraux simples. Il serait utile de verifier si les modeles detailles sont effectivement utilises par MinionVisualService ou s'ils restent en reserve.

5) ARCHITECTURE SERVEUR
Script principal :
- ServerScriptService.Server
- Role probable : initialisation globale des services serveur
- Taille : 50 lignes

Dossier serveur :
- ServerScriptService.Server.services
- Contient les principaux ModuleScripts serveur

Services serveur detectes :
- AbilityService : 766 lignes
  Role : gestion des abilities des champions. C'est le plus gros module serveur. Il gere plusieurs types d'abilities : melee damage, ranged damage, AoE, dash, heal, execute, etc.

- ShopService : 526 lignes
  Role : achat/vente d'items, inventaire, recettes et logique de boutique.

- MinionService : 394 lignes
  Role : spawn des vagues, IA de deplacement, logique de combat des minions.

- MinionVisualService : 386 lignes
  Role : attachement/creation des visuels de minions.

- RemoteService : 323 lignes
  Role : creation/gestion des RemoteEvents et point d'entree client-serveur.

- CombatService : 267 lignes
  Role : combat general, auto-attacks, degats, morts, aggro.

- ChampionService : 225 lignes
  Role : champions joueurs, selection, spawn, progression.

- EconomyProgressionService : 211 lignes
  Role : gold, XP, niveaux, recompenses.

- TrainingDummyService : 204 lignes
  Role : dummies d'entrainement/debug.

- RecallService : 175 lignes
  Role : recall de 6 secondes, annulation au degat.

- MapValidatorService : 169 lignes
  Role : validation de la structure de map.

- TowerService : 167 lignes
  Role : IA des tours, priorites de cible.

- JungleService : 159 lignes
  Role : camps jungle, monstres, aggro, leash, respawn.

- MinionAnimationService : 150 lignes
  Role : animation des minions.

- Utility : 139 lignes
  Role : fonctions utilitaires, distance, health, healthbar, team, etc.

- UnitFactory : 108 lignes
  Role : creation procedurale d'unites/minions/monstres.

- VisionService : 96 lignes
  Role : vision par equipe, brouillard/revelation des ennemis.

- MatchStateService : 57 lignes
  Role : etats WaitingForPlayers, InGame, Ended.

- NexusService : 56 lignes
  Role : nexus, inhibitors, conditions de victoire.

- TeamService : 35 lignes
  Role : gestion equipes. Le module existe bien dans ServerScriptService.Server.services.

6) DONNEES PARTAGEES / REPLICATEDSTORAGE
ReplicatedStorage contient un dossier Modules avec les donnees centrales du jeu.

Modules detectes :
- AbilityData : 321 lignes
  Contient les donnees des abilities. 5 champions x 4 abilities = 20 abilities environ.

- ChampionData : 92 lignes
  Contient 5 champions : Tank, Assassin, Mage, Marksman, Support.

- SharedConstants : 89 lignes
  Constantes globales : equipes, lanes, combat, vision, recall, debug, mouvement.

- ItemData : 78 lignes
  Contient 6 items avec systeme de recettes : LongSword, RubyCrystal, Boots, B.F. Sword, GiantBelt, SwiftBoots.

- VisualConfig : 75 lignes
  Configuration visuelle.

- MinionData : 45 lignes
  Types de minions : Melee, Ranged, Siege. Vagues de 6 minions + siege toutes les 3 waves.

- JungleData : 40 lignes
  Donnees des camps jungle.

Remotes :
- Aucun RemoteEvent visible en edit mode dans ReplicatedStorage.
- L'architecture indique que les remotes sont probablement crees dynamiquement par RemoteService au runtime.
- Le sous-agent a identifie environ 16 RemoteEvents crees dynamiquement.

7) ARCHITECTURE CLIENT
LocalScript principal :
- StarterPlayer.StarterPlayerScripts.Client
- 20 lignes
- Role probable : initialisation des controllers client

Controllers client detectes :
- HudController : 420 lignes
  Role : interface principale joueur.

- VisualController : 201 lignes
  Role : gestion des elements visuels client.

- InputController : 165 lignes
  Role : entrees clavier/souris. Mention ZQSD + souris.

- CombatFeedbackController : 153 lignes
  Role : feedback visuel combat.

- AbilityVFXController : 222 lignes
  Role : effets visuels des abilities.

- AutoAttackController : 81 lignes
  Role : auto-attacks cote client.

- FogController : 63 lignes
  Role : brouillard de guerre / fog of war.

Sous-controllers HUD :
- ShopController : 615 lignes
  Role : interface boutique, gros module client.

- SpellBarController : 445 lignes
  Role : barre de sorts.

- ScoreboardController : 272 lignes
  Role : tableau des scores.

- ChampionSelectPanelController : 151 lignes
  Role : selection de champion.

- TrainingPanelController : 147 lignes
  Role : panel entrainement/debug.

- StatsInventoryController : 118 lignes
  Role : stats et inventaire.

Observation importante :
- StarterGui est vide.
- L'UI est donc probablement creee dynamiquement par les controllers client, ce qui est coherent avec HudController, ShopController, SpellBarController, etc.

8) LIGHTING / AMBIANCE
Lighting contient 14 descendants, dont :
- Sky : mountains_chain_best1
- Atmosphere
- BloomEffect
- ColorCorrectionEffect
- ColorGradingEffect
- SunRaysEffect

Le projet utilise deja une direction artistique avec effets de post-processing. Cela donne une ambiance plus travaillee, mais ces effets peuvent avoir un cout sur les appareils faibles. Sans SceneAnalysisService actif, les draw calls/post-process exacts n'ont pas pu etre mesures.

9) AUDIO
SoundService est vide.
Un seul Sound detecte dans les assets :
- ServerStorage.Assets.Models.sbires.candidates.candidat_sbire_1.RAWR
- SoundId : asset 12222242

Conclusion audio :
- Le jeu n'a quasiment pas de sound design actuellement.
- Opportunites : musiques d'ambiance, sons UI, sons d'abilities, hit feedback, mort de minions, tower shots, achat boutique, recall, victoire/defaite.

10) ANIMATIONS
32 Animation instances detectees, principalement dans les modeles de sbires de ServerStorage.
Animations recurrentes :
- Idle1 / Idle2
- Walk / Run
- Attack
- Arms
- Climb / Fall / Jump / ToolNone pour certains candidats

Assets d'animation detectes plusieurs fois :
- 125749145 : Walk/Run
- 125750544 : Idle1
- 125750618 : Idle2
- 180416148 : Attack
- 183294396 : Arms
- 190149431 : Attack Piggy/minion

Observation :
Les animations sont surtout attachees aux modeles stockes. Il faut verifier pendant le runtime si les minions proceduraux utilisent vraiment ces animations ou non.

11) PHYSIQUE / PARTS
Statistiques physiques :
- BaseParts : 3 765
- Parts simples : 3 023
- MeshParts : 13
- Parts ancrees : 3 630
- Parts non ancrees : 135
- Parts collidables : 1 330
- Parts transparentes partielles : 82
- Constraints/Joints : environ 1 906 au total, dont beaucoup de Snap, Weld, ManualWeld, Motor6D, WeldConstraint

Analyse :
- La majorite des elements de map sont ancrees, ce qui est bon pour une map statique.
- Beaucoup de Snap/Weld/ManualWeld viennent probablement des modeles de towers et minions importes.
- Les 1 042 Decals peuvent contribuer a des draw calls supplementaires selon leur usage et leur visibilite.
- Les towers sont tres detaillees et repetees 20+ fois, ce qui peut devenir le principal cout visuel.

12) UI
- StarterGui : vide
- UI statique detectee : 0 element GUI
- Controllers UI presents et nombreux cote client

Conclusion UI :
L'interface est vraisemblablement entierement generee par scripts. C'est flexible et centralise, mais il faut surveiller :
- creation/destruction propre des Frames
- nettoyage des connections d'evenements
- compatibilite mobile/resolution
- taille des scripts UI, notamment ShopController et SpellBarController

13) RESEAU / REMOTES
Aucun RemoteEvent visible en edition, mais RemoteService est present et semble responsable de leur creation runtime.
C'est une bonne approche si :
- les noms sont centralises
- les events sont crees une seule fois
- chaque requete client est validee cote serveur

Points a verifier dans RemoteService/ShopService/AbilityService :
- validation anti-exploit des achats
- validation de distance/cooldown pour abilities
- validation de target pour auto-attacks
- verification team/enemy avant degats
- protection contre spam de RemoteEvents

14) GAMEPLAY SYSTEMS
Le projet couvre deja beaucoup de systemes d'un MOBA :
- Selection champion
- Stats champion
- Abilities multiples
- Auto-attacks
- Degats et mort
- Minions avec vagues
- Towers avec IA cible
- Jungle camps
- Gold et XP
- Niveaux jusqu'a 18
- Shop avec items et recipes
- Recall
- Vision/fog
- Nexus/inhibitors
- Etats de match
- Dummies d'entrainement

C'est un ensemble coherent et ambitieux. L'architecture est plutot propre : donnees, logique serveur et controllers client sont separes.

15) POINTS D'ATTENTION FONCTIONNELS
- Tank a 10 000 HP selon l'analyse des donnees, alors que les autres champions tournent autour de valeurs beaucoup plus basses. Cela peut etre volontaire pour debug, mais a verifier pour l'equilibrage.
- SharedConstants.DEBUG.ALLOW_DEBUG_GOLD = true : a desactiver avant publication ou test public.
- SPRINT_DISABLED_FOR_NOW = true : sprint desactive temporairement.
- Units vide en edition : normal si spawn runtime, mais attention a bien nettoyer les unites mortes.
- StarterGui vide : normal si UI dynamique, mais verifier l'adaptativite mobile.
- SoundService vide : le jeu manque probablement de feedback audio.
- Remotes dynamiques : verifier que tous les appels client sont valides cote serveur.
- Beaucoup de decals et pieces sur les towers : potentiel cout de rendu.
- Assets candidats/legacy dans ServerStorage : possible nettoyage a envisager si non utilises.

16) PERFORMANCE / OPTIMISATION
Mesures avancees indisponibles : SceneAnalysisService n'est pas active, donc impossible d'obtenir dans cette session :
- triangles visibles
- draw calls par pass
- memoire VM par script
- memoire audio chargee
- memoire animation chargee
- instances non parentees runtime

Analyse statique :
- 7 437 instances scannees : taille raisonnable pour un projet de ce type.
- Workspace a 4 064 descendants : scene assez dense mais pas extreme.
- ServerStorage a 3 294 descendants : beaucoup d'assets stockes, surtout towers/minions.
- Les towers repetent un modele d'environ 177 descendants chacune, ce qui est probablement le plus gros contributeur visuel.
- 1 042 Decals : a surveiller, car les decals peuvent ajouter du cout de rendu.
- 50 PointLights + effets Lighting : ambiance riche, mais peut impacter les appareils bas de gamme.
- Peu de MeshParts : beaucoup de construction par Parts/Wedges, ce qui peut augmenter le nombre d'instances et joints.

Suggestions performance :
- Auditer les towers : reduire le nombre de pieces, fusionner certains elements, remplacer des details repetes par MeshParts optimises si necessaire.
- Limiter les Decals visibles ou convertir certains traitements de surface en MaterialVariants.
- Verifier si tous les PointLights sont necessaires.
- Nettoyer les assets candidats/legacy inutilises dans ServerStorage pour alleger la maintenance.
- Ajouter un test runtime avec SceneAnalysisService active pour mesurer draw calls/triangles reels.

17) QUALITE DU CODE / ARCHITECTURE
Points positifs :
- Architecture modulaire claire.
- Separation serveur/client propre.
- Donnees centralisees dans ReplicatedStorage.Modules.
- Services serveur specialises.
- Controllers client specialises.
- Usage probable de RemoteService centralise.
- Strict mode Luau indique par l'analyse precedente.
- Usage d'Attributes pour les donnees d'unites.
- Usage de task.spawn et os.clock pour les boucles/timers.

Points a surveiller :
- AbilityService est tres gros : 766 lignes. Il pourrait devenir difficile a maintenir si le nombre de champions augmente. Eventuellement separer par type d'ability ou par champion.
- ShopController et SpellBarController sont aussi volumineux. L'UI dynamique peut devenir complexe ; il faut bien structurer la creation/nettoyage des elements.
- Les scripts dans les modeles candidats ServerStorage contiennent des anciens systemes Roblox/ZombieAI/Pathfinding. S'ils ne sont pas utilises, ils peuvent etre archives ou retires.
- Certains scripts d'assets legacy pourraient s'executer si les modeles sont clones sans nettoyage.

18) SECURITE / ANTI-EXPLOIT
Pour un MOBA, le serveur doit etre autoritaire. Les points critiques a verifier :
- Le client ne doit jamais decider seul des degats.
- Le client ne doit pas pouvoir donner du gold/XP directement.
- Les achats doivent verifier gold, item existant, slots, recipes cote serveur.
- Les abilities doivent verifier cooldown, mana/ressource si present, distance, cible, team, et etat du champion.
- Les auto-attacks doivent verifier range et cooldown cote serveur.
- Les mouvements importants/dash doivent etre controles ou valides cote serveur.
- Les RemoteEvents doivent etre debounces/rate-limited contre le spam.

19) PRIORITES RECOMMANDEES
Priorite 1 : Securiser le gameplay serveur
- Verifier toutes les validations dans RemoteService, AbilityService, ShopService, CombatService.
- Desactiver DEBUG_GOLD avant publication.

Priorite 2 : Equilibrage gameplay
- Revoir les stats de champions, surtout Tank a 10 000 HP.
- Tester les degats, ranges, cooldowns, gold/XP et rythme des minions.

Priorite 3 : UX/UI
- Tester l'UI sur plusieurs resolutions.
- Ajouter feedback clair : cooldowns, degats, gold gagne, niveau, mort, recall, shop.

Priorite 4 : Audio
- Ajouter sons essentiels : clic UI, ability cast, hit, tower shot, minion death, recall, shop, victoire/defaite.

Priorite 5 : Performance visuelle
- Mesurer draw calls/triangles quand SceneAnalysisService sera disponible.
- Optimiser towers/decals/lights si necessaire.
- Nettoyer les assets candidats/legacy inutilises dans ServerStorage pour alleger la maintenance.

Priorite 6 : Nettoyage assets
- Identifier les modeles candidats/legacy non utilises.
- Eviter que des scripts legacy soient clones dans Workspace par erreur.

20) CONCLUSION
Le projet est deja avance et possede une base solide pour un MOBA Roblox. L'architecture est claire, modulaire et separe correctement serveur, client et donnees partagees. Les systemes gameplay principaux sont presents : champions, abilities, minions, towers, jungle, shop, progression, vision et nexus.

Les plus grosses opportunites d'amelioration sont :
- securisation anti-exploit des RemoteEvents
- equilibrage des champions et des stats
- ajout d'un vrai sound design
- verification de l'UI dynamique sur tous les formats
- optimisation potentielle des towers, decals et lights
- nettoyage des assets/scripts legacy dans ServerStorage

Globalement, c'est un projet ambitieux, bien organise, et deja proche d'une structure de jeu live. La prochaine etape ideale serait un audit cible des scripts critiques : RemoteService, AbilityService, CombatService, ShopService et ChampionService.