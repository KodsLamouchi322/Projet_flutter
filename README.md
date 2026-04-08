# firebase_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Architecture

Ce projet suit le pattern MVC:
- **Models** : lib/models/ - classes de donnees Firestore
- **Views** : lib/views/ - interfaces utilisateur Flutter
- **Controllers** : lib/controllers/ - logique metier
- **Services** : lib/services/ - Firebase, PDF, notifications

## Fonctionnalites principales
- Gestion des emprunts et reservations
- Clubs de lecture avec defis
- Messagerie en temps reel
- Notifications push FCM
- Export PDF des historiques
- Scanner ISBN via camera
