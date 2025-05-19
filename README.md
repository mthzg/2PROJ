# 2PROJ

#### étapes

1- création de la Tilemap en 3 noeuds (Ground, Water, Rocks)
2- Gestion des mouvement de la caméra
3- Création d'un HUD pour sélection de batiments:
    #todo fix le hud en fullscreen (mauvaise position)
4- gestion dynamique de la taille d'un batiment
5- Placement des batiments
    #todo ajouter tous les batiments du jeu


#not done

6- Création d'une interface de visualisation de stock avec des incrementer et decrementer qui prennent (x: int value)
    
7- création des citoyens    
    -incréement de population_max à chaque maison placé
    -besoins d'une maison : 
        small_house: 0 needs
        medium_house: wood, berries
        etc...
    -si une besoin à besoin d'une ressource on envoi un citoyen vers la source de tel besoin
    -si aucun besoin envoi d'un citoyen vers batiment en construction

    -un citoyen à barre de soif, faim, fatigue (soif si eau pas débloqué, fatigue si lit débloqué)
    chaque ressource sera consommé dans la maison
    pour 5min passé en décrémente de 1 tous les besoins


