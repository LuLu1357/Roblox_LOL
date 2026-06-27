# SUIVI_JARVIS_FUSION_COMPLET.md — Suivi complet du projet Roblox MOBA

**Projet :** Roblox_LOL / GameTest  
**Type :** MOBA Roblox inspiré de League of Legends  
**État :** pré-alpha technique jouable  
**Dernière mise à jour :** 27 juin 2026  
**Objectif du document :** fusionner le document de suivi amélioré avec le rapport d'analyse original, sans supprimer d'information.

---

## Mode de lecture du document

Ce fichier fusionné contient deux blocs principaux :

1. **Partie A — Document de suivi amélioré avec onboarding développeur.**  
   Cette partie sert de document de pilotage opérationnel : contexte complet du projet, architecture, priorités, roadmap, checklists et prochaine tâche active.

2. **Partie B — Rapport d'analyse original complet.**  
   Cette partie conserve intégralement le rapport initial et les mesures/observations détaillées issues de l'analyse automatisée du code source et du DataModel.

Les informations redondantes sont volontairement conservées afin de ne rien perdre. La Partie A reformule et organise les décisions ; la Partie B garde l'historique brut et détaillé.

---

# PARTIE A — DOCUMENT DE SUIVI AMÉLIORÉ AVEC ONBOARDING

# SUIVI_JARVIS.md — Suivi technique du projet Roblox MOBA

**Projet :** Roblox_LOL / GameTest  
**Type :** MOBA Roblox inspiré de League of Legends  
**État :** pré-alpha technique jouable  
**Dernière mise à jour :** 27 juin 2026  
**Objectif du document :** centraliser l'état du projet, les risques techniques, les décisions d'architecture et la prochaine feuille de route.

---

## 0. Rappel complet du projet pour un nouveau développeur

Cette section sert d'onboarding. Un développeur qui arrive sur le projet doit pouvoir comprendre ici ce qu'est le jeu, comment il est organisé, quels systèmes existent déjà, quelles conventions sont utilisées et quelles sont les priorités actuelles.

### 0.1 Vision du projet

`Roblox_LOL` est un projet de jeu Roblox de type **MOBA**, inspiré de la structure générale de League of Legends. L'objectif est de construire une expérience multijoueur avec deux équipes, des lanes, des champions contrôlés par les joueurs, des vagues de sbires, des tours, de la jungle, un shop, de l'expérience, de l'or, des items, des compétences, de la vision et une condition de victoire par destruction du Nexus adverse.

Le projet n'est pas une simple démo isolée. Il possède déjà une architecture serveur/client/shared, une map structurée, une logique de combat serveur, une économie, un système de progression, une UI dynamique et plusieurs systèmes gameplay fondamentaux. L'état actuel doit être considéré comme une **pré-alpha technique jouable** : les briques principales existent, mais la stabilité serveur, la sécurité réseau, l'équilibrage et les performances doivent être consolidés avant d'ajouter massivement du contenu.

### 0.2 Dépôt et outils

- Dépôt GitHub : `LuLu1357/Roblox_LOL`
- Nom projet Rojo / Studio : `GameTest`
- Langage : Luau strict (`--!strict` dans les principaux scripts)
- Moteur : Roblox Studio
- Synchronisation code : Rojo
- Carte et modèles : Roblox Studio, fichier `GameTest-editable.rbxlx`
- Code source : dossier `src`

Le code est synchronisé avec Rojo, mais la carte n'est pas générée uniquement par code. La map statique, les modèles, les parts, les towers, les spawns, les waypoints et les éléments visuels sont principalement gérés dans Roblox Studio. Il ne faut donc pas lancer le serveur sur une Baseplate vide : le serveur attend une scène contenant `Workspace.Map`.

### 0.3 Organisation générale du projet

L'architecture suit une séparation classique Roblox :

```txt
src/
├── server/                 # Logique serveur autoritaire
│   ├── init.server.luau    # Point d'entrée serveur
│   └── services/           # Services gameplay serveur
│
├── client/                 # Contrôleurs client
│   ├── init.client.luau    # Point d'entrée client
│   └── controllers/        # HUD, input, feedback, VFX, shop, scoreboard...
│
└── shared/modules/         # Données et constantes partagées
    ├── SharedConstants.luau
    ├── ChampionData.luau
    ├── AbilityData.luau
    ├── ItemData.luau
    ├── MinionData.luau
    ├── JungleData.luau
    └── VisualConfig.luau
```

Dans Roblox, Rojo mappe ces dossiers vers :

```txt
ReplicatedStorage.Modules      <- src/shared/modules
ServerScriptService.Server     <- src/server
StarterPlayerScripts.Client    <- src/client
Workspace.Map                  <- map statique créée dans Roblox Studio
```

Cette séparation est importante :

- le **serveur** décide du gameplay réel : dégâts, morts, gold, XP, shop, victoire, IA ;
- le **client** affiche l'UI, lit les inputs, joue des effets visuels et envoie des intentions au serveur ;
- les **modules partagés** contiennent les données de configuration consultées par les deux côtés.

### 0.4 Principe d'autorité serveur

Le projet doit rester serveur-autoritaire. Le client ne doit jamais décider seul :

- des dégâts infligés ;
- du gold ou de l'XP gagnés ;
- de l'achat réel d'un item ;
- de la mort d'une unité ;
- de la validité d'une attaque ou d'une compétence ;
- du résultat d'un dash ou d'une action importante.

Le client envoie une demande via un RemoteEvent. Le serveur vérifie ensuite la validité : joueur, champion, ownership, cooldown, distance, vision, équipe, état vivant/mort, gold, inventaire, recette, etc. Ce principe existe déjà dans plusieurs services, mais il doit être renforcé avec un rate limiter global dans `RemoteService`.

### 0.5 Services serveur principaux

#### `init.server.luau`

Point d'entrée serveur. Il charge tous les services, vérifie que `Workspace.Map` existe, crée `Workspace.Units` si nécessaire, puis démarre les systèmes dans un ordre déterminé.

#### `RemoteService`

Porte d'entrée réseau. Il crée et centralise les RemoteEvents : attaques, abilities, shop, recall, champion select, scoreboard, debug, feedback combat, vision, etc. Les clients ne doivent pas appeler directement les services serveur : ils passent par ces remotes.

À améliorer : ajouter un rate limiter par joueur et par remote pour limiter le spam.

#### `ChampionService`

Transforme le `Player.Character` Roblox en champion MOBA. Il applique les Attributes de gameplay : `UnitType`, `OwnerUserId`, `Team`, `ChampionId`, `MaxHealth`, `Health`, `AttackDamage`, `AttackRange`, `AttackCooldown`, `MoveSpeed`, `InventoryCount`, etc.

Il gère aussi la sélection de champion et le respawn.

Point critique actuel : plusieurs connexions `GetAttributeChangedSignal` sont créées pour logger les stats, mais elles ne sont pas encore nettoyées explicitement. C'est la priorité technique numéro 1.

#### `CombatService`

Service central du combat. Il vérifie les auto-attacks, applique les dégâts, émet le feedback de combat, déclenche les listeners de dégâts et gère la mort des unités.

Il doit rester le passage central de tous les dégâts. Les abilities, towers, minions et monstres doivent appeler `CombatService.applyDamage` plutôt que modifier la vie directement.

#### `AbilityService`

Gère les compétences des champions. Il reçoit une demande du client, vérifie le slot, le champion, le cooldown, le type de spell, la cible ou la position souris, puis applique l'effet.

Types déjà présents : self heal, damage target, ranged damage, dash damage, AoE, AoE à la souris, dash forward, bonus temporaire de vie, execute, heal allié/self, team heal.

Point à améliorer : le service est fonctionnel mais monolithique. À terme, chaque type d'ability ou chaque champion devrait avoir son propre module handler.

#### `MinionService`

Gère les vagues de sbires. Il récupère les spawns, les lanes, les waypoints, crée les minions via `UnitFactory`, leur attache un visuel via `MinionVisualService`, puis lance leur IA.

Point critique actuel : chaque sbire a sa propre coroutine `task.spawn` avec une boucle d'update. Ce modèle fonctionne en petit test, mais ne scale pas bien. Il faut le remplacer par une boucle centralisée qui met à jour tous les sbires actifs.

#### `ShopService`

Gère achat, vente et craft d'items. Il vérifie que le champion existe, qu'il est vivant, qu'il est dans sa zone shop, qu'il a assez d'or, que l'item existe, que l'inventaire a de la place, et que les contraintes unique/recipe sont respectées.

Point à améliorer : factoriser les vérifications communes entre `buyItem`, `sellItem` et `craftItem`.

#### `EconomyProgressionService`

Gère gold, XP, niveaux, récompenses de kill et application de la progression aux champions. Il est appelé notamment lors des morts confirmées par `CombatService`.

#### `TowerService`

Gère les tours : ciblage, priorité, attaque et interaction avec les unités ennemies.

#### `JungleService`

Gère les camps jungle : monstres, aggro, leash, respawn et récompenses associées.

#### `VisionService`

Gère la vision par équipe et le fog of war côté client. Les informations de vision doivent être utilisées pour éviter qu'un joueur puisse attaquer une cible invisible.

#### `RecallService`

Gère le recall : canalisation, annulation au mouvement ou au dégât, retour base.

#### `MatchStateService`

Gère l'état de la partie : attente, partie en cours, fin de match. Il doit devenir le point central pour empêcher certains systèmes de tourner hors match.

#### `NexusService`

Gère la destruction des Nexus et la condition de victoire.

#### `MapValidatorService`

Vérifie la structure de la map : tours, inhibiteurs, Nexus, spawns, paths, waypoints, camps jungle. Aujourd'hui il log surtout des warnings. À terme, il devrait pouvoir empêcher le démarrage d'une partie si la map est invalide.

### 0.6 Données partagées

Les données de gameplay sont centralisées dans `ReplicatedStorage.Modules`.

- `SharedConstants` : constantes globales, remotes, équipes, lanes, combat, vision, recall, debug.
- `ChampionData` : champions disponibles, stats de base, rôle, portée, cooldown, vitesse.
- `AbilityData` : liste des sorts par champion.
- `ItemData` : items, coûts, stats, recettes, groupes uniques.
- `MinionData` : types de sbires et composition des vagues.
- `JungleData` : camps jungle, stats, respawns.
- `VisualConfig` : paramètres visuels partagés.

Un nouveau développeur doit éviter de coder des valeurs gameplay en dur dans les services. Les stats et paramètres doivent autant que possible rester dans ces modules.

### 0.7 Map et DataModel attendu

La map doit être présente dans `Workspace.Map`. Elle contient au minimum :

```txt
Workspace.Map
├── Paths
│   ├── Blue
│   │   ├── Top
│   │   ├── Mid
│   │   └── Bot
│   └── Red
│       ├── Top
│       ├── Mid
│       └── Bot
│
├── PlayerSpawns
│   ├── Blue
│   └── Red
│
├── MinionSpawns
│   ├── Blue/Top, Mid, Bot
│   └── Red/Top, Mid, Bot
│
├── Towers
├── Inhibitors
├── Nexus
├── JungleCamps
└── ShopZones
```

Le projet actuel prévoit une map MOBA avec 3 lanes : Top, Mid, Bot. Les sbires suivent des waypoints par équipe et par lane. Les shops sont des zones de parts associées à chaque équipe.

Le dossier `Workspace.Units` contient les unités runtime : champions, sbires, monstres, towers ou autres entités interactives selon les systèmes.

### 0.8 Boucle de gameplay attendue

1. Le serveur démarre.
2. `init.server.luau` vérifie la map et crée `Workspace.Units`.
3. Les services démarrent.
4. Les joueurs rejoignent et reçoivent une équipe.
5. Le joueur choisit un champion.
6. `ChampionService` configure son character en champion MOBA.
7. Le match démarre.
8. Les vagues de sbires apparaissent sur les 3 lanes.
9. Les champions peuvent attaquer, lancer des abilities, farmer, acheter des items, faire la jungle, recall.
10. Les towers, inhibitors et Nexus structurent la progression.
11. La destruction du Nexus adverse termine la partie.

### 0.9 Systèmes déjà présents

Le projet possède déjà :

- sélection de champion ;
- stats champion par Attributes ;
- auto-attacks serveur ;
- plusieurs types d'abilities ;
- vagues de minions ;
- IA minion basique ;
- towers ;
- jungle ;
- shop avec achat, vente, craft et recettes ;
- gold, XP et niveaux ;
- recall ;
- vision / fog ;
- Nexus et inhibitors ;
- scoreboard ;
- dummies d'entraînement ;
- UI dynamique ;
- VFX d'abilities et feedback combat.

Ce qui manque ou reste faible :

- sound design quasi absent ;
- équilibrage réel des champions/items ;
- rate limiting réseau ;
- nettoyage strict des connexions ;
- IA minions scalable ;
- tests runtime longs ;
- documentation développeur formalisée ;
- pipeline de validation avant publication.

### 0.10 Priorité actuelle du projet

La priorité actuelle n'est pas d'ajouter un nouveau champion ni une nouvelle grosse mécanique. La priorité est de rendre la base robuste.

Ordre de travail recommandé :

1. Corriger `ChampionService` pour nettoyer toutes les connexions liées aux personnages.
2. Désactiver ou whitelister les RemoteEvents de debug, surtout le debug gold.
3. Ajouter un rate limiter dans `RemoteService`.
4. Refactoriser `MinionService` pour remplacer une coroutine par sbire par une boucle centralisée.
5. Rééquilibrer les stats de champions, notamment le Tank actuellement beaucoup trop haut.
6. Refactoriser progressivement `AbilityService` en handlers/modules.
7. Ajouter une checklist de test de partie complète.
8. Ajouter le sound design minimal.

### 0.11 Règles à respecter pour les prochains développements

- Toujours valider côté serveur.
- Ne jamais faire confiance aux données envoyées par le client.
- Garder `CombatService` comme point central des dégâts.
- Garder les stats dans les modules partagés, pas dispersées dans les services.
- Nettoyer toutes les connexions liées à un personnage ou à une unité temporaire.
- Éviter les boucles infinies par unité quand une boucle centralisée suffit.
- Protéger tous les RemoteEvents sensibles contre le spam.
- Ne pas publier avec les flags debug ouverts.
- Tester les changements après plusieurs respawns, pas seulement sur un spawn propre.
- Documenter toute décision d'architecture dans ce fichier.

### 0.12 Définition d'une version pré-alpha stable

Le projet pourra être considéré comme pré-alpha stable quand :

- une partie peut tourner 10 à 15 minutes sans fuite évidente ;
- les respawns répétés ne dupliquent pas les logs ou callbacks ;
- un joueur non autorisé ne peut pas utiliser les remotes debug ;
- le spam de RemoteEvents est limité ;
- les minions restent performants après plusieurs vagues ;
- les towers, jungle, shop, recall, vision et Nexus fonctionnent ensemble ;
- le Tank et les autres champions ont des stats testables ;
- l'UI reste lisible et fonctionnelle sur plusieurs résolutions ;
- les actions importantes ont au moins un feedback visuel ou audio minimal.


## 1. Résumé exécutif

Le projet dispose déjà d'une base solide : architecture Rojo claire, séparation serveur/client/shared, systèmes MOBA principaux présents, map structurée, shop, combat, abilities, minions, jungle, towers, vision, recall, nexus et UI dynamique.

La priorité n'est plus d'ajouter beaucoup de fonctionnalités. La priorité actuelle est de rendre le jeu **stable, sécurisé et testable sur une vraie partie de plusieurs minutes**.

### Priorités immédiates

| Priorité | Sujet | Pourquoi c'est important | Statut |
|---|---|---|---|
| P0 | Nettoyage des connexions dans `ChampionService` | Risque de fuite mémoire au respawn/changement de champion | À faire |
| P0 | Désactiver/debug-gater `ALLOW_DEBUG_GOLD` | Évite l'exploitation du RemoteEvent de debug | À faire |
| P1 | Rate limit dans `RemoteService` | Protège le serveur contre le spam client | À faire |
| P1 | Refactor IA des sbires | Une coroutine par sbire ne scale pas | À faire |
| P2 | Rééquilibrage des champions | Le Tank à 10 000 HP casse les tests gameplay | À faire |
| P2 | Refactor progressif d'`AbilityService` | Évite le fichier monolithique impossible à maintenir | À planifier |

---

## 2. Architecture actuelle

### 2.1 Organisation générale

Le projet suit une architecture Roblox propre :

```txt
ReplicatedStorage
└── Modules                  # Données partagées : champions, items, minions, constantes

ServerScriptService
└── Server                   # Services serveur autoritaires
    ├── init.server.luau
    └── services/

StarterPlayer
└── StarterPlayerScripts
    └── Client               # Contrôleurs client : HUD, input, VFX, shop, scoreboard

Workspace
└── Map                      # Carte statique créée/modifiée dans Roblox Studio
```

Le projet utilise Rojo pour synchroniser le code, mais la map reste gérée visuellement dans Roblox Studio via `GameTest-editable.rbxlx`.

### 2.2 Points forts

- Séparation claire entre logique serveur, affichage client et données partagées.
- `RemoteService` centralise les RemoteEvents.
- `CombatService` centralise les dégâts et les morts.
- Les données de gameplay sont modifiables via des ModuleScripts.
- La map possède déjà les éléments d'un MOBA : lanes, towers, inhibitors, nexus, jungle camps, shops.
- L'UI est générée dynamiquement côté client, ce qui évite une dépendance forte à `StarterGui`.

### 2.3 Point faible principal

Le projet est déjà assez complet, mais plusieurs systèmes ont été développés en mode prototype/debug. Avant d'ajouter plus de contenu, il faut nettoyer la stabilité serveur, la sécurité réseau et les performances.

---

## 3. État fonctionnel du jeu

### 3.1 Systèmes déjà présents

| Système | Présent | Commentaire |
|---|---:|---|
| Sélection de champion | Oui | Via `ChampionService` et RemoteEvent dédié |
| Stats champion | Oui | Stockées en Attributes sur le modèle du champion |
| Auto-attaques | Oui | Validées côté serveur dans `CombatService` |
| Abilities | Oui | Plusieurs types déjà supportés dans `AbilityService` |
| Minions | Oui | Spawn par vague, lanes, ciblage, attaque |
| Towers | Oui | IA de ciblage et attaque |
| Jungle | Oui | Camps, monstres, respawn |
| Shop | Oui | Achat, vente, craft, recettes, stats |
| Gold / XP / level | Oui | Via `EconomyProgressionService` |
| Recall | Oui | Canalisation et annulation au dégât/mouvement |
| Vision / fog | Oui | Vision par équipe et RemoteEvents client |
| Nexus / Inhibitors | Oui | Conditions de victoire |
| Scoreboard | Oui | Payload généré serveur |
| Training dummies | Oui | Fonctionnalité debug |
| Audio | Très faible | Sound design quasiment absent |

### 3.2 Boucle de partie attendue

1. Le serveur démarre et charge les services.
2. `MapValidatorService` vérifie la structure de `Workspace.Map`.
3. Les joueurs reçoivent une équipe et choisissent un champion.
4. `ChampionService` transforme le `Player.Character` en champion MOBA.
5. `MatchStateService` lance la partie.
6. `MinionService` génère les vagues.
7. Combat, shop, jungle, towers et progression tournent en parallèle.
8. La destruction d'un Nexus déclenche la fin de partie.

---

## 4. Audit technique priorisé

## P0 — Stabilité serveur

### 4.1 `ChampionService` : connexions non nettoyées

**Constat :** `setupCharacter` connecte plusieurs `GetAttributeChangedSignal(...):Connect(...)` pour logger les changements de stats. Ces connexions ne sont pas stockées et ne sont pas explicitement déconnectées.

**Risque :** au fil des respawns ou changements de champion, le serveur peut accumuler des connexions et des closures inutiles. Cela peut produire une hausse mémoire, plus de logs, et des comportements difficiles à diagnostiquer.

**Décision :** ajouter un nettoyage explicite des connexions liées à chaque personnage.

**Plan d'action :**

```lua
local characterConnections: { [Model]: { RBXScriptConnection } } = {}

local function cleanupCharacter(character: Model)
    local connections = characterConnections[character]
    if connections then
        for _, connection in connections do
            connection:Disconnect()
        end
        characterConnections[character] = nil
    end
end

local function trackCharacterConnection(character: Model, connection: RBXScriptConnection)
    characterConnections[character] = characterConnections[character] or {}
    table.insert(characterConnections[character], connection)
end
```

Puis, dans `setupCharacter` :

```lua
cleanupCharacter(character)

trackCharacterConnection(character, character.Destroying:Connect(function()
    cleanupCharacter(character)
end))
```

Et pour les logs d'attributs :

```lua
trackCharacterConnection(character,
    character:GetAttributeChangedSignal(attributeName):Connect(function()
        -- log debug
    end)
)
```

**Critère d'acceptation :** après 20 respawns/changements de champion, il ne doit pas y avoir d'augmentation anormale du nombre de callbacks ni de logs dupliqués.

---

### 4.2 Debug gold exposé

**Constat :** `SharedConstants.DEBUG.ALLOW_DEBUG_GOLD = true` et `DEBUG_GOLD_AMOUNT = 10000`.

**Risque :** si le jeu est testé avec d'autres joueurs, n'importe quel client pouvant déclencher le RemoteEvent de debug peut recevoir de l'or.

**Décision :** désactiver par défaut ou limiter à une whitelist d'UserIds.

**Option minimale :**

```lua
SharedConstants.DEBUG = {
    GAME_SPEED = 1,
    SPAWN_BLUE_MINIONS = true,
    SPAWN_RED_MINIONS = true,
    ALLOW_DEBUG_GOLD = false,
    DEBUG_GOLD_AMOUNT = 10000,
    ALLOW_TRAINING_DUMMIES = false,
}
```

**Option recommandée :**

```lua
SharedConstants.DEBUG = {
    ALLOW_DEBUG_GOLD = true,
    ALLOW_TRAINING_DUMMIES = true,
    ALLOWED_DEBUG_USER_IDS = {
        [123456789] = true,
    },
}
```

Puis dans `RemoteService` :

```lua
local function canUseDebug(player: Player): boolean
    local debugConfig = SharedConstants.DEBUG
    return typeof(debugConfig) == "table"
        and typeof(debugConfig.ALLOWED_DEBUG_USER_IDS) == "table"
        and debugConfig.ALLOWED_DEBUG_USER_IDS[player.UserId] == true
end
```

**Critère d'acceptation :** un joueur non autorisé ne peut pas obtenir d'or ni spawn/clear des dummies.

---

## P1 — Sécurité réseau

### 4.3 Ajouter un rate limiter dans `RemoteService`

**Constat :** les RemoteEvents sont centralisés, mais il n'y a pas encore de limitation générique par joueur/RemoteEvent.

**Risque :** un client peut spammer les events. Même si les services refusent l'action, le serveur doit traiter les appels.

**Décision :** ajouter un rate limiter simple dans `RemoteService`.

**Exemple :**

```lua
local lastRemoteCall: { [string]: number } = {}

local function canCall(player: Player, remoteName: string, minInterval: number): boolean
    local key = tostring(player.UserId) .. ":" .. remoteName
    local now = os.clock()
    local last = lastRemoteCall[key] or 0

    if now - last < minInterval then
        return false
    end

    lastRemoteCall[key] = now
    return true
end

Players.PlayerRemoving:Connect(function(player)
    local prefix = tostring(player.UserId) .. ":"
    for key in pairs(lastRemoteCall) do
        if string.sub(key, 1, #prefix) == prefix then
            lastRemoteCall[key] = nil
        end
    end
end)
```

**Intervalles conseillés :**

| RemoteEvent | Intervalle minimal |
|---|---:|
| `AbilityRequest` | 0.05–0.10 s |
| `AutoAttackRequest` | 0.05–0.10 s |
| `ScoreboardRequest` | 0.25–0.50 s |
| `ShopBuyRequest` | 0.10–0.20 s |
| `ShopSellRequest` | 0.10–0.20 s |
| `ShopCraftRequest` | 0.10–0.20 s |
| Debug remotes | 0.50–1.00 s |

**Critère d'acceptation :** un spam RemoteEvent ne doit pas faire monter significativement le temps serveur.

---

## P1 — Performance gameplay

### 3.4 `MinionService` : remplacer une coroutine par sbire

**Constat :** chaque sbire lance sa propre boucle via `task.spawn`. La boucle tourne avec un intervalle très court.

**Risque :** le nombre de coroutines augmente avec les vagues. Cela peut devenir un goulot d'étranglement serveur.

**Décision :** passer à une boucle centralisée.

**Architecture cible :**

```lua
local RunService = game:GetService("RunService")

local activeMinions: { [Model]: table } = {}
local accumulator = 0
local UPDATE_INTERVAL = 0.10

RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < UPDATE_INTERVAL then
        return
    end

    local step = accumulator
    accumulator = 0

    for minion, state in pairs(activeMinions) do
        if not minion.Parent or not Utility.isAlive(minion) then
            activeMinions[minion] = nil
            if minion.Parent then
                minion:SetAttribute("MinionState", "Dead")
                task.delay(2, function()
                    if minion.Parent then
                        minion:Destroy()
                    end
                end)
            end
        else
            updateMinionAI(minion, state, step)
        end
    end
end)
```

**À conserver du système actuel :**

- les waypoints par team/lane ;
- la logique `findNearestEnemy` ;
- la logique d'attaque via `CombatService.tryAutoAttack` ;
- les Attributes `MinionState`, `AggroTarget`, `AttackTick`.

**Critère d'acceptation :** 10 minutes de partie avec plusieurs vagues ne doivent pas dégrader progressivement le serveur.

---

## P2 — Maintenabilité

### 3.5 `AbilityService` : découpage en handlers

**Constat :** `castAbility` contient beaucoup de branches conditionnelles. C'est acceptable pour 5 champions, mais pas pour une vraie montée en contenu.

**Décision :** garder `AbilityService` comme routeur et déplacer la logique par type d'ability.

**Structure cible :**

```txt
src/server/services/abilities/
├── SelfHeal.luau
├── TargetDamage.luau
├── LineDamage.luau
├── AoEDamage.luau
├── DashForward.luau
├── ExecuteDamage.luau
├── TemporaryMaxHealth.luau
├── AllyOrSelfHeal.luau
└── TeamHeal.luau
```

**Contexte passé au handler :**

```lua
local context = {
    Player = player,
    Champion = champion,
    Spell = spell,
    Slot = slot,
    OptionalTarget = optionalTarget,
    OptionalMousePosition = optionalMousePosition,
    Services = {
        CombatService = CombatService,
        Utility = Utility,
    },
}
```

**Critère d'acceptation :** ajouter un nouveau type d'ability ne doit plus nécessiter de modifier une énorme fonction centrale.

---

### 3.6 `ShopService` : réduire la duplication

**Constat :** `buyItem`, `sellItem` et `craftItem` répètent les mêmes validations.

**Décision :** introduire une fonction commune.

```lua
local function getValidShopChampion(player: Player): (Model?, string?)
    local champion = ChampionService.getChampionFromPlayer(player)
    if not champion then
        return nil, "Champion not found"
    end

    if champion:GetAttribute("Dead") == true then
        return nil, "Champion is dead"
    end

    if not canUseShop(player, champion) then
        return nil, "Not in shop zone"
    end

    return champion, nil
end
```

**Critère d'acceptation :** les trois fonctions shop partagent la même validation de base.

---

## P2 — Équilibrage gameplay

### 3.7 ChampionData : revoir les valeurs debug

**Constat :** le Tank a une valeur de vie très supérieure aux autres champions. Cela fausse les tests de combat, tower damage, minion damage et abilities.

**Décision :** distinguer stats de debug et stats de gameplay.

**Proposition initiale :**

| Champion | HP cible | AD cible | Rôle |
|---|---:|---:|---|
| Tank | 750–900 | 40–55 | frontline |
| Assassin | 500–600 | 65–80 | burst |
| Mage | 480–580 | 35–50 | spells |
| Marksman | 480–560 | 55–70 | DPS range |
| Support | 550–700 | 30–45 | utility/heal |

**Critère d'acceptation :** un duel ou une phase de lane doit produire des résultats exploitables sans valeurs debug extrêmes.

---

## 4. Documentation fonctionnelle consolidée

### 4.1 Création des unités

Deux logiques coexistent :

- **Champions joueurs :** transformés depuis `Player.Character` par `ChampionService`.
- **Unités non-joueurs :** créées via `UnitFactory` puis attachées à `Workspace.Units`.

Cette distinction est correcte. Il faut seulement s'assurer que les deux familles utilisent les mêmes conventions d'Attributes :

```txt
UnitType
Team
Health
MaxHealth
AttackDamage
AttackRange
AttackCooldown
MoveSpeed
Dead
```

### 4.2 Combat

Le serveur doit rester autoritaire.

Règles à conserver :

- le client demande une action ;
- le serveur valide ;
- le serveur applique les dégâts ;
- le serveur déclenche les feedbacks visuels ;
- le client n'invente jamais de dégâts, d'or ou d'XP.

### 4.3 Shop

Le shop fonctionne comme système de progression par items. Les stats d'items sont appliquées directement sur les Attributes du champion.

À surveiller :

- synchronisation `Health` / `Humanoid.Health` ;
- recalcul propre de `InventoryCount` ;
- items uniques ;
- crafts avec composants multiples ;
- vente après craft.

### 4.4 Vision

Le système de vision est essentiel pour un MOBA. Il faut vérifier que toutes les actions joueur liées à une cible ennemie respectent la vision :

- auto-attaque ;
- certains sorts ciblés ;
- scoreboard ou UI ne doivent pas révéler d'informations critiques non voulues.

### 4.5 UI

L'UI est dynamique côté client. C'est flexible, mais cela impose une discipline stricte :

- cleanup des connexions au respawn ;
- compatibilité plusieurs résolutions ;
- feedback clair sur cooldowns, gold, XP, mort, recall, dégâts ;
- pas de Frames dupliquées après respawn.

---

## 5. Audit DataModel / scène Roblox

### 5.1 Résumé scène

Le projet contient une map déjà avancée :

- 3 lanes : Top, Mid, Bot ;
- 2 équipes : Blue et Red ;
- towers, inhibitors, nexus ;
- jungle camps ;
- shop zones ;
- assets de sbires et tours dans `ServerStorage`.

### 5.2 Points performance visuelle à surveiller

| Élément | Risque | Action |
|---|---|---|
| Towers très détaillées | Beaucoup de descendants répétés | Réduire ou convertir certains détails en MeshPart optimisé |
| Decals nombreux | Coût rendu/draw calls | Auditer les decals visibles et utiles |
| PointLights nombreux | Coût GPU sur machines faibles | Tester avec Lighting simplifié |
| Assets legacy/candidates | Maintenance confuse | Archiver ou supprimer ce qui n'est pas utilisé |
| Scripts legacy dans assets | Risque si clonés en runtime | Nettoyer les modèles avant usage |

### 5.3 Mesure manquante

Le rapport initial indique que les mesures runtime avancées n'ont pas pu être récupérées. Il faut donc faire un test Studio avec :

- MicroProfiler ;
- Script Performance ;
- Memory ;
- Network receive/send ;
- stats serveur avec plusieurs vagues de sbires.

---

## 6. Roadmap opérationnelle

## Sprint 1 — Stabilisation serveur

**Objectif :** obtenir une partie de test stable sans fuite évidente.

- [ ] Implémenter `cleanupCharacter` dans `ChampionService`.
- [ ] Désactiver ou whitelist les debug remotes.
- [ ] Ajouter rate limiter dans `RemoteService`.
- [ ] Ajouter cleanup PlayerRemoving pour cooldowns/rate limits/debug state.
- [ ] Vérifier que `MapValidatorService` peut bloquer le démarrage si la map est invalide.

**Résultat attendu :** test local 10 minutes sans explosion de logs ni comportements fantômes.

---

## Sprint 2 — Minions scalable

**Objectif :** remplacer les boucles individuelles par une IA centralisée.

- [ ] Créer `activeMinions`.
- [ ] Créer `updateMinionAI(minion, state, dt)`.
- [ ] Remplacer `runMinionAI` par enregistrement dans `activeMinions`.
- [ ] Tester 10 minutes de vagues.
- [ ] Vérifier destruction propre des minions morts.

**Résultat attendu :** le nombre de sbires peut augmenter sans multiplier les threads.

---

## Sprint 3 — Gameplay testable

**Objectif :** obtenir une boucle de partie équilibrable.

- [ ] Ramener les stats Tank à une plage normale.
- [ ] Vérifier dégâts minions/towers/champions.
- [ ] Vérifier gold/XP par kill et last hit.
- [ ] Tester achat, vente, craft.
- [ ] Tester recall sous dégâts et mouvement.
- [ ] Tester destruction tower → inhibitor → nexus.

**Résultat attendu :** une partie solo/dev permet d'observer le rythme réel du jeu.

---

## Sprint 4 — Refactor maintenabilité

**Objectif :** préparer l'ajout de nouveaux champions.

- [ ] Créer dossier `services/abilities`.
- [ ] Extraire `SelfHeal`.
- [ ] Extraire `TargetDamage`.
- [ ] Extraire `AoEDamage`.
- [ ] Extraire `DashForward`.
- [ ] Garder `AbilityService` comme routeur.

**Résultat attendu :** ajouter une nouvelle ability ne nécessite plus d'alourdir `castAbility`.

---

## Sprint 5 — UX, audio et polish

**Objectif :** rendre le jeu compréhensible et agréable.

- [ ] Ajouter son achat boutique.
- [ ] Ajouter son ability cast.
- [ ] Ajouter hit feedback sonore.
- [ ] Ajouter son tower shot.
- [ ] Ajouter son mort de minion.
- [ ] Ajouter son recall.
- [ ] Ajouter victoire/défaite.
- [ ] Tester UI en plusieurs résolutions.

**Résultat attendu :** le joueur comprend ce qui se passe sans lire la console.

---

## 7. Checklist anti-exploit

Avant test public, vérifier :

- [ ] Le client ne peut pas donner d'or directement.
- [ ] Le client ne peut pas donner d'XP directement.
- [ ] Le client ne peut pas infliger des dégâts directement.
- [ ] Les achats vérifient gold, item, slot, shop zone côté serveur.
- [ ] Les abilities vérifient cooldown, slot, cible, range, équipe et état vivant.
- [ ] Les auto-attaques vérifient owner, range, cooldown, vision et équipe.
- [ ] Les debug remotes sont désactivés ou whitelistés.
- [ ] Les RemoteEvents critiques sont rate-limited.
- [ ] Les dashes ne permettent pas de sortir de la map ou traverser des zones interdites.

---

## 8. Checklist de test manuel

### Test champion

- [ ] Spawn correct Blue.
- [ ] Spawn correct Red.
- [ ] Changement champion sans duplication de stats.
- [ ] Respawn sans duplication de logs.
- [ ] HealthBar présente.
- [ ] Attributes cohérents.

### Test combat

- [ ] Auto-attaque ennemi en range.
- [ ] Auto-attaque refusée hors range.
- [ ] Auto-attaque refusée sur allié.
- [ ] Mort déclenchée correctement.
- [ ] Gold/XP donnés au bon joueur.

### Test abilities

- [ ] Slot invalide refusé.
- [ ] Cooldown appliqué.
- [ ] Cible invalide refusée.
- [ ] Sort directionnel fonctionne.
- [ ] AoE applique les dégâts aux bonnes cibles.
- [ ] Heal ne dépasse pas MaxHealth.

### Test minions

- [ ] Spawn Blue/Red sur les 3 lanes.
- [ ] Suivi waypoint correct.
- [ ] Aggro sur ennemi proche.
- [ ] Reprise de chemin après mort/perte de cible.
- [ ] Destruction propre après mort.

### Test shop

- [ ] Achat en zone shop.
- [ ] Achat refusé hors zone shop.
- [ ] Vente rembourse correctement.
- [ ] Craft consomme les composants.
- [ ] Unique item respecté.
- [ ] InventoryCount correct.

### Test fin de partie

- [ ] Tower peut mourir.
- [ ] Inhibitor peut mourir.
- [ ] Nexus peut mourir.
- [ ] `MatchStateService.endMatch` appelé.
- [ ] Les minions arrêtent de spawn.
- [ ] UI de fin affichée.

---

## 9. Dette technique connue

| Dette | Gravité | Action |
|---|---:|---|
| Connexions non nettoyées côté serveur | Haute | Sprint 1 |
| Une coroutine par sbire | Haute | Sprint 2 |
| Debug gold activé | Haute | Sprint 1 |
| Pas de rate limit RemoteEvents | Haute | Sprint 1 |
| `AbilityService` monolithique | Moyenne | Sprint 4 |
| `ShopService` répétitif | Moyenne | Sprint 4 |
| UI dynamique à tester au respawn | Moyenne | Sprint 5 |
| Sound design absent | Moyenne | Sprint 5 |
| Assets legacy/candidates | Basse à moyenne | Nettoyage assets |
| Towers/decals potentiellement lourds | Moyenne | Profiling Studio |

---

## 10. Décisions d'architecture

### Décision 1 — Le serveur reste autoritaire

Le client demande, le serveur décide. Toutes les actions critiques doivent être validées côté serveur.

### Décision 2 — Les Attributes restent la source principale de stats runtime

Les champions et unités utilisent des Attributes pour exposer Health, MaxHealth, Team, UnitType, stats et inventaire. C'est compatible avec la réplication Roblox et l'UI dynamique.

### Décision 3 — Le contenu gameplay doit rester data-driven

Champions, items, minions, jungle et abilities doivent rester configurables dans `src/shared/modules` autant que possible.

### Décision 4 — Les systèmes debug doivent être isolés

Les outils debug sont utiles, mais ils ne doivent jamais être accessibles à tous les joueurs.

---

## 11. Prochaine tâche active recommandée

### Tâche : corriger `ChampionService` cleanup

**Pourquoi :** c'est le risque stabilité le plus direct.

**Fichiers concernés :**

```txt
src/server/services/ChampionService.luau
```

**Étapes :**

1. Ajouter une table `characterConnections`.
2. Ajouter `cleanupCharacter(character)`.
3. Ajouter `trackCharacterConnection(character, connection)`.
4. Remplacer les `:Connect(...)` directs par `trackCharacterConnection(...)`.
5. Connecter `character.Destroying`.
6. Tester respawn/changement champion 20 fois.

**Critère fini :** aucun log dupliqué après plusieurs respawns, aucune connexion debug persistante inutile.

---

## 12. Notes pour la suite

Ne pas ajouter de nouveau champion tant que les points P0/P1 ne sont pas corrigés. Le projet est déjà assez riche : maintenant il faut solidifier le socle.

Ordre recommandé :

```txt
ChampionService cleanup
→ Debug/RemoteService sécurité
→ MinionService centralisé
→ Équilibrage Tank/stats
→ AbilityService refactor
→ UX/audio/polish
```

---

## 13. Journal de suivi

| Date | Modification | Statut |
|---|---|---|
| 27/06/2026 | Restructuration du suivi en document de pilotage | Fait |
| 27/06/2026 | Priorisation P0/P1/P2 ajoutée | Fait |
| 27/06/2026 | Checklists de test ajoutées | Fait |
| 27/06/2026 | Roadmap par sprint ajoutée | Fait |



---

# PARTIE B — RAPPORT D'ANALYSE ORIGINAL COMPLET CONSERVÉ

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
