import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../catalogue/catalogue_view.dart';
import '../emprunts/emprunts_view.dart';
import '../profil/profil_view.dart';
import 'home_view.dart';

/// Navigation principale avec BottomNavigationBar (conforme au cahier des charges)
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    CatalogueView(),
    EmpruntsView(),
    ProfilView(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Catalogue',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Mes emprunts',
          ),
          BottomNavigationBarItem(
            icon: auth.estAdmin
                ? const Icon(Icons.admin_panel_settings_outlined)
                : const Icon(Icons.person_outline),
            activeIcon: auth.estAdmin
                ? const Icon(Icons.admin_panel_settings)
                : const Icon(Icons.person),
            label: auth.estAdmin ? 'Admin' : 'Profil',
          ),
        ],
      ),
    );
  }
}
