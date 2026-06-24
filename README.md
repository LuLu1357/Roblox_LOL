# GameTest

## Ouvrir le projet

La carte est gérée visuellement par Roblox Studio. Le code est synchronisé par Rojo.

1. Ouvrir `GameTest-editable.rbxlx` dans Roblox Studio.
2. Rester en mode Edit pour modifier `Workspace > Map` avec Move, Scale, Rotate et Terrain Editor.
3. Connecter le plugin Rojo au projet `default.project.json` pour synchroniser les scripts.
4. Enregistrer le place avec `⌘S` après les modifications visuelles.

Le blockout actuel utilise une arène de 760 × 760 studs : Top longe les côtés gauche et supérieur, Mid traverse la diagonale, et Bot longe les côtés inférieur et droit.

Sur Mac, `⌘Z` annule les modifications Studio et `⌘⇧Z` les rétablit.

Ne pas utiliser un Baseplate vide pour lancer le jeu : le serveur attend une carte statique nommée `Workspace.Map`.

## Responsabilités

- Roblox Studio / `GameTest-editable.rbxlx` : carte, terrain, Parts et modèles.
- Rojo / `src` : scripts Luau et configuration technique.
- `tools/generate_editable_place.mjs` : générateur initial de secours ; ne pas le relancer après des modifications manuelles sans sauvegarde.
