
# City Builder - Godot 4.4

Ce jeu de gestion/simulation a été réalisé avec **Godot 4.4**. Le joueur doit développer une civilisation en gérant ses ressources, ses citoyens, et son urbanisme pour construire une ville prospère.

---

## Objectifs du jeu

-  **Développer votre civilisation**  
-  **Produire le plus de ressources possible** (bois, eau, baies, etc.)  
-  **Étendre et optimiser votre ville** grâce à une gestion stratégique des bâtiments et des citoyens

---

## Fonctionnement

1. **Placement du Great Fire**  
   Le jeu commence par la construction obligatoire d’un *Great Fire*. Celui-ci est le cœur de la civilisation.

2. **Maisons gratuites**  
   Une fois le *Great Fire* placé, vous débloquez la possibilité de construire jusqu'à **5 maisons gratuitement**.

3. **Déblocage des ateliers**  
   Après avoir construit les maisons, vous débloquez les bâtiments de production (Wood Cutter, Berry Picker, Water Workers Hut...).

4. **Gestion des travailleurs**  
   Dans l'onglet **Work Tab**, vous pouvez définir combien de citoyens doivent travailler sur chaque type de ressource.

5. **Contrôle du temps**  
   Le temps peut être accéléré à l’aide des **flèches situées en haut à droite** de l’écran.

---

## Cycle de vie du jeu

- **Échelle de temps**  
  - `1 seconde réelle = 1 minute en jeu`

- **Apparition des citoyens**  
  - Un nouveau citoyen apparaît **toutes les 30 minutes en jeu**, à condition qu’il y ait de la place dans une maison.

- **Durée de vie des citoyens**  
  - Un citoyen vit **5 heures en jeu**.

- **Cycle de travail et repos**  
  - Après **19 heures de travail**, un citoyen rentre à la maison pour **se reposer et se nourrir**.  
  - Si des ressources comme **l’eau ou les baies** sont disponibles, sa durée de vie est prolongée.

- **Fin de vie et remplacement**  
  - Lorsqu’un citoyen meurt, il est automatiquement retiré de son lieu de travail.  
  - S’il y a d'autres citoyens disponibles, un nouveau prend sa place.

---

## Dépendances

- Ce jeu a été développé sur **Godot Engine 4.4**.
- Toutes les scènes, scripts, et assets sont gérés directement depuis le projet Godot.

---
