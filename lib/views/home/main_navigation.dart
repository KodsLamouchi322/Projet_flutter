import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/message_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../home/home_view.dart';
import '../catalogue/catalogue_view.dart';
import '../emprunts/emprunts_view.dart';
import '../community/community_view.dart';
import '../profil/profil_view.dart';
import '../admin/admin_dashboard_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pagesUser = const [
    HomeView(), CatalogueView(), EmpruntsView(), CommunityView(), ProfilView(),
  ];
  final List<Widget> _pagesAdmin = const [
    HomeView(), CatalogueView(), AdminDashboardView(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final membre = auth.membre;

    if (membre != null && !membre.estActif && !membre.estAdmin) {
      return _SuspendedScreen(onLogout: auth.deconnecter);
    }

    final estAdmin = auth.estAdmin;
    final pages = estAdmin ? _pagesAdmin : _pagesUser;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: estAdmin
          ? _AdminNav(current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i))
          : _UserNav(
              current: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
    );
  }
}

// ─── Nav utilisateur ──────────────────────────────────────────────────────────
class _UserNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _UserNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final msgCtrl = context.watch<MessageController>();
    final items = [
      _NavData(Icons.home_rounded, Icons.home_rounded, 'Accueil'),
      _NavData(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Bibliothèque'),
      _NavData(Icons.bookmark_outline, Icons.bookmark_rounded, 'Mes livres'),
      _NavData(Icons.groups_outlined, Icons.groups_rounded, 'Communauté',
          badge: msgCtrl.totalNonLus),
      _NavData(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: items.asMap().entries.map((e) {
              final isCommunity = e.key == 3;
              return _FloatingNavTile(
                data: e.value,
                index: e.key,
                current: current,
                onTap: onTap,
                communityStyle: isCommunity,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Nav admin ────────────────────────────────────────────────────────────────
class _AdminNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _AdminNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _NavData(Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      _NavData(Icons.menu_book_outlined, Icons.menu_book_rounded, l10n.navCatalog),
      _NavData(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded, l10n.navAdmin),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: items.asMap().entries.map((e) {
              return _FloatingNavTile(
                data: e.value,
                index: e.key,
                current: current,
                onTap: onTap,
                communityStyle: false,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Tuile nav ────────────────────────────────────────────────────────────────
class _NavData {
  final IconData icon, activeIcon;
  final String label;
  final int badge;
  const _NavData(this.icon, this.activeIcon, this.label, {this.badge = 0});
}

class _NavTile extends StatelessWidget {
  final _NavData data;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavTile({required this.data, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    selected ? data.activeIcon : data.icon,
                    size: 22,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
                if (data.badge > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                      child: Text(
                        data.badge > 99 ? '99+' : '${data.badge}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
              child: Text(data.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavTile extends StatelessWidget {
  final _NavData data;
  final int index, current;
  final bool communityStyle;
  final ValueChanged<int> onTap;

  const _FloatingNavTile({
    required this.data,
    required this.index,
    required this.current,
    required this.onTap,
    required this.communityStyle,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: selected
                  ? (communityStyle ? AppColors.gradientAccent : AppColors.gradientPrimary)
                  : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? data.activeIcon : data.icon,
                      size: 22,
                      color: selected ? Colors.white : inactiveColor,
                    ),
                    if (data.badge > 0)
                      Positioned(
                        top: -8,
                        right: -12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientAccent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            data.badge > 99 ? '99+' : '${data.badge}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white : inactiveColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Compte suspendu ──────────────────────────────────────────────────────────
class _SuspendedScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const _SuspendedScreen({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.block_rounded, size: 40, color: AppColors.error),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.accountSuspended,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(l10n.accountSuspendedMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.6)),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: Text(l10n.logout, style: const TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
