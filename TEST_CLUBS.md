# Guide de test - Fonctionnalités Clubs

## Prérequis
1. Application redémarrée avec les dernières modifications
2. Utilisateur connecté
3. Au moins un livre dans le catalogue

## Test 1 : Créer un club

### Étapes
1. Ouvrir l'onglet "Clubs" ou "Communauté"
2. Cliquer sur le bouton pour créer un club
3. Remplir le formulaire :
   - Nom du club : "Test Club"
   - Description : "Club de test"
   - Livre : Choisir un livre du catalogue
4. Cliquer sur "Créer"

### Résultat attendu
- ✅ Le modal se ferme
- ✅ Un SnackBar vert apparaît : "Club créé avec succès !"
- ✅ Le nouveau club apparaît dans la liste
- ✅ Le club affiche "1 membre" (le créateur)
- ✅ Pas de page d'erreur rouge

### Logs console attendus
```
🔵 Création du club "Test Club"...
✅ Club "Test Club" créé avec succès
🔵 Chargement des clubs publics...
✅ 1 clubs chargés
   - Test Club: 1 membres (uid_du_createur)
```

## Test 2 : Rejoindre un club

### Étapes
1. Se connecter avec un AUTRE utilisateur
2. Aller dans l'onglet "Clubs"
3. Cliquer sur le club créé précédemment
4. Cliquer sur "Rejoindre" dans l'AppBar

### Résultat attendu
- ✅ Un SnackBar vert apparaît
- ✅ Le bouton change de "Rejoindre" à "Quitter"
- ✅ Le badge "Membre" apparaît
- ✅ Dans l'onglet "À propos", le nombre de membres passe à 2
- ✅ L'onglet "Discussion" devient accessible

### Logs console attendus
```
🔵 Tentative de rejoindre le club xxx par membre yyy
✅ Membre yyy ajouté au club xxx
🔵 Chargement des clubs publics...
✅ 1 clubs chargés
   - Test Club: 2 membres (uid1, uid2)
```

## Test 3 : Envoyer un message

### Étapes
1. Dans le club rejoint, aller dans l'onglet "Discussion"
2. Taper un message : "Bonjour tout le monde !"
3. Cliquer sur le bouton d'envoi

### Résultat attendu
- ✅ Le message apparaît immédiatement
- ✅ Le champ de texte se vide
- ✅ Le message affiche le nom de l'expéditeur

## Test 4 : Quitter un club

### Étapes
1. Dans un club dont vous êtes membre (mais pas créateur)
2. Cliquer sur "Quitter" dans l'AppBar

### Résultat attendu
- ✅ Le bouton change de "Quitter" à "Rejoindre"
- ✅ Le badge "Membre" disparaît
- ✅ L'onglet "Discussion" affiche le message "Rejoignez pour discuter"
- ✅ Le nombre de membres diminue de 1

## Test 5 : Créateur ne peut pas quitter

### Étapes
1. Se connecter avec le créateur du club
2. Ouvrir le club
3. Vérifier le bouton dans l'AppBar

### Résultat attendu
- ✅ Le bouton affiche "Créateur" (grisé, non cliquable)
- ✅ Dans l'onglet "À propos", un badge "Vous êtes l'organisateur" est affiché

## Erreurs possibles et solutions

### Erreur : "Club introuvable"
- Vérifier que le club existe dans Firestore
- Vérifier les règles Firestore (allow read: if true)

### Erreur : "Erreur lors de l'adhésion"
- Vérifier que l'utilisateur est connecté
- Vérifier les règles Firestore (allow update: if isAuth())
- Vérifier les logs console pour plus de détails

### Erreur : Page rouge "_dependents.isEmpty"
- Cette erreur devrait être corrigée maintenant
- Si elle persiste, vérifier que le code de `creer_club_flow.dart` est à jour

### Erreur : "Index not found"
- Attendre quelques minutes que l'index se construise
- Vérifier avec : `firebase firestore:indexes`
- Le code devrait faire un fallback avec tri local

## Nettoyage après tests

Pour supprimer les clubs de test :
1. Aller dans la console Firebase
2. Firestore Database > clubs_lecture
3. Supprimer les documents de test

Ou utiliser le panneau admin de l'application si disponible.
