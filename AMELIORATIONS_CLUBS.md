# Améliorations des Clubs de Lecture

## Nouvelles fonctionnalités implémentées

### 1. Lectures Communes Organisées 📚

Les clubs peuvent maintenant organiser des lectures communes avec:
- **Sélection d'un livre** à lire ensemble
- **Calendrier de lecture** avec dates de début et fin
- **Suivi de progression** individuelle (pourcentage de lecture)
- **Discussions par chapitre** avec dates planifiées
- **Liste des participants** actifs

#### Modèle: `LectureCommune`
- Statuts: `planifiee`, `en_cours`, `terminee`
- Progression par membre (0-100%)
- Nombre de chapitres et planning des discussions

#### Méthodes du contrôleur:
- `streamLecturesCommunes(clubId)` - Stream des lectures
- `creerLectureCommune(...)` - Créer une nouvelle lecture
- `rejoindreLectureCommune(lectureId, membreId)` - Rejoindre
- `mettreAJourProgression(lectureId, membreId, pourcentage)` - MAJ progression

---

### 2. Système de Vote pour Livres 🗳️

Les membres peuvent proposer et voter pour le prochain livre:
- **Proposition de livres** par n'importe quel membre
- **Vote démocratique** (un vote par membre)
- **Classement automatique** par nombre de votes
- **Évite les doublons** (un livre ne peut être proposé qu'une fois)

#### Modèle: `VoteLivre`
- Livre proposé avec infos complètes
- Liste des votants
- Compteur de votes

#### Méthodes du contrôleur:
- `streamVotesLivres(clubId)` - Stream des votes en cours
- `proposerLivrePourVote(...)` - Proposer un livre
- `voterPourLivre(voteId, membreId)` - Voter
- `retirerVote(voteId, membreId)` - Retirer son vote

---

### 3. Défis de Lecture Mensuels 🏆

Gamification avec des défis collectifs:
- **Types de défis**:
  - Nombre de livres (ex: lire 3 livres ce mois)
  - Genre spécifique (ex: 2 romans policiers)
  - Nombre de pages (ex: 500 pages)
  - Auteur spécifique

- **Suivi de progression** individuelle
- **Classement des participants**
- **Dates de début et fin**
- **Pourcentage d'accomplissement**

#### Modèle: `DefiLecture`
- Type de défi et objectif chiffré
- Progression par membre
- Statut (en cours, terminé, à venir)

#### Méthodes du contrôleur:
- `streamDefisLecture(clubId)` - Stream des défis
- `creerDefiLecture(...)` - Créer un défi
- `rejoindreDefi(defiId, membreId)` - Participer
- `mettreAJourProgressionDefi(defiId, membreId, progression)` - MAJ

---

### 4. Bibliothèque Partagée du Club 📖

Collection de livres recommandés par le club:
- **Ajout de livres** par les membres
- **Tags personnalisés**: `recommandé`, `coup_de_coeur`, `à_lire`
- **Note moyenne du club**
- **Commentaire collectif** éditable
- **Historique** avec qui a ajouté le livre

#### Modèle: `LivreClub`
- Informations du livre
- Note et nombre de notations
- Tags multiples
- Commentaire partagé

#### Méthodes du contrôleur:
- `streamBibliothequeClub(clubId)` - Stream de la bibliothèque
- `ajouterLivreBibliotheque(...)` - Ajouter un livre
- `ajouterTagLivre(livreClubId, tag)` - Ajouter un tag
- `mettreAJourCommentaireClub(livreClubId, commentaire)` - MAJ commentaire

---

## Structure Firestore

```
clubs_lecture/
  {clubId}/
    - nom, description, membres...

lectures_communes/
  {lectureId}/
    - clubId, livreId, dateDebut, dateFin
    - participantsIds[], progressionParMembre{}
    - statut, nbChapitres

votes_livres/
  {voteId}/
    - clubId, livreId, proposePar
    - votantsIds[], nbVotes

defis_lecture/
  {defiId}/
    - clubId, titre, type, objectif
    - participantsIds[], progressionParMembre{}
    - dateDebut, dateFin

livres_club/
  {livreClubId}/
    - clubId, livreId, ajoutePar
    - noteClub, tags[], commentaireClub
```

---

## Prochaines étapes d'intégration UI

### 1. Modifier `club_detail_view.dart`
Ajouter des onglets:
- Discussion (existant)
- Lectures communes
- Votes
- Défis
- Bibliothèque

### 2. Créer les widgets:
- `LectureCommuneCard` - Afficher une lecture avec progression
- `VoteLivreCard` - Carte de vote avec bouton
- `DefiLectureCard` - Défi avec barre de progression
- `LivreClubCard` - Livre de la bibliothèque avec tags

### 3. Ajouter les actions:
- Boutons FAB pour créer lecture/défi/vote
- Formulaires de création
- Mise à jour de progression
- Gestion des votes

---

## Avantages

✅ **Engagement accru** - Les membres ont plus de raisons de revenir
✅ **Gamification** - Défis et progression motivent la lecture
✅ **Démocratie** - Choix collectifs via votes
✅ **Organisation** - Lectures structurées avec calendrier
✅ **Mémoire collective** - Bibliothèque partagée du club
✅ **Évolutif** - Facile d'ajouter d'autres types de défis/activités

---

## Exemples d'utilisation

### Créer une lecture commune
```dart
await clubController.creerLectureCommune(
  clubId: club.id,
  livreId: livre.id,
  livreTitre: livre.titre,
  livreAuteur: livre.auteur,
  dateDebut: DateTime.now(),
  dateFin: DateTime.now().add(Duration(days: 30)),
  nbChapitres: 20,
);
```

### Proposer un livre pour vote
```dart
await clubController.proposerLivrePourVote(
  clubId: club.id,
  livreId: livre.id,
  livreTitre: livre.titre,
  livreAuteur: livre.auteur,
  proposePar: userId,
  proposeParNom: userName,
);
```

### Créer un défi
```dart
await clubController.creerDefiLecture(
  clubId: club.id,
  titre: "Défi Mars 2024",
  description: "Lire 3 romans policiers",
  type: "genre",
  objectif: 3,
  genreCible: "Policier",
  dateDebut: DateTime(2024, 3, 1),
  dateFin: DateTime(2024, 3, 31),
);
```
