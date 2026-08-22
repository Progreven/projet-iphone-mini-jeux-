JEUX SOIRÉE — APPLICATION IPHONE NATIVE
========================================

Le dossier contient le projet iOS SwiftUI Imposteur.xcodeproj. Le nom technique du projet et du scheme reste « Imposteur » pour rester compatible avec ton workflow GitHub actuel, mais l'application installée s'affiche maintenant sous le nom « Jeux Soirée ».

MISE À JOUR DE TON REPO GITHUB EXISTANT (WINDOWS)
-------------------------------------------------
1. Garde ton dossier .github/workflows à la RACINE du dépôt, exactement comme il fonctionne actuellement.
2. Remplace uniquement le dossier Imposteur-iPhone de ton dépôt par le dossier Imposteur-iPhone fourni ici.
3. Commit / push les nouveaux fichiers.
4. GitHub : Actions > Build Imposteur IPA > Run workflow.
5. Attends le build vert.
6. Télécharge l'artefact « Imposteur-IPA ».
7. Décompresse-le pour obtenir Imposteur-unsigned.ipa.
8. Installe-le avec Sideloadly comme pour la version précédente.

Le Bundle ID reste com.julien.imposteur : l'installation est prévue pour remplacer la version précédente plutôt que créer une deuxième app distincte. Les données UserDefaults de l'ancien jeu Imposteur gardent leurs mêmes clés.

ARCHITECTURE
------------
App/        : accueil général et navigation entre mini-jeux.
Imposteur/  : code de la V1.4 conservé tel quel (hors icône générale de l'asset catalog).
HeadsUp/    : nouveau mini-jeu, logique, mouvements, bibliothèques et vues.
Scripts/    : tests / données d'audit.

HEADS UP — BIBLIOTHÈQUES
------------------------
- 100 Célébrités.
- 100 personnages Films & Séries.
- 100 personnages Dessins animés & Anime.
- 100 personnages Jeux vidéo.
- 100 Animaux / insectes / créatures mythologiques connues.
- « Tous les thèmes » est construit automatiquement à partir de ces cinq listes.

Chaque bibliothèque principale peut être modifiée depuis l'iPhone et importée/exportée en JSON.

V2.1 — MOUVEMENTS HEADS UP
--------------------------
La détection d'inclinaison a été recalibrée autour de la position réelle du téléphone au début de chaque manche. L'orientation de l'interface est verrouillée uniquement pendant l'écran de jeu Heads Up, puis libérée automatiquement en quittant la manche.
