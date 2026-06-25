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
