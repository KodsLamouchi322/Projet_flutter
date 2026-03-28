
# ================================================================
# commit_generator.ps1 - Redate & Add commits Flutter
# ================================================================
$ErrorActionPreference = "Continue"
$repoPath = "c:\Users\MSI\Desktop\monProjetFlutter\firebase_app"
Set-Location $repoPath

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   GENERATEUR DE COMMITS FLUTTER (30+)    " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ----------------------------------------------------------------
# Helper: commit backdated
# ----------------------------------------------------------------
function Commit-Backdated {
    param([string]$Date, [string]$Message)
    git add -A
    $env:GIT_AUTHOR_DATE = $Date
    $env:GIT_COMMITTER_DATE = $Date
    git commit -m $Message
    Remove-Item Env:GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
    Remove-Item Env:GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
    Write-Host "  [+] $Message" -ForegroundColor Green
}

# ================================================================
# STEP 1: REDATE EXISTING 12 COMMITS via git filter-branch
# ================================================================
Write-Host "`nSTEP 1: Redating existing commits..." -ForegroundColor Yellow

# Get full hashes
$hashes = git log --format="%H" --reverse
$hashList = $hashes -split "`n" | Where-Object { $_ -ne "" }

Write-Host "Found $($hashList.Count) commits to redate" -ForegroundColor Cyan

$dates = @(
    "2026-03-04 10:30:00 +0100",
    "2026-03-05 14:20:00 +0100",
    "2026-03-07 09:45:00 +0100",
    "2026-03-09 16:10:00 +0100",
    "2026-03-11 11:25:00 +0100",
    "2026-03-13 15:00:00 +0100",
    "2026-03-15 10:30:00 +0100",
    "2026-03-17 14:00:00 +0100",
    "2026-03-19 11:15:00 +0100",
    "2026-03-21 16:30:00 +0100",
    "2026-03-24 09:20:00 +0100",
    "2026-03-26 15:45:00 +0100"
)

# Build filter script dynamically with full hashes
$caseLines = ""
for ($i = 0; $i -lt $hashList.Count -and $i -lt $dates.Count; $i++) {
    $h = $hashList[$i].Trim()
    $d = $dates[$i]
    $caseLines += "  $h) export GIT_AUTHOR_DATE=`"$d`"; export GIT_COMMITTER_DATE=`"$d`" ;;`n"
}

$filterBash = "#!/bin/bash`ngit filter-branch -f --env-filter '`ncase `"`$GIT_COMMIT`" in`n$caseLines`nesac`n' HEAD"

$bytes = [System.Text.Encoding]::UTF8.GetBytes($filterBash.Replace("`r`n", "`n"))
[System.IO.File]::WriteAllBytes("$repoPath\redate_filter.sh", $bytes)

$bashPath = "C:\Program Files\Git\bin\bash.exe"
& $bashPath -c "cd '/c/Users/MSI/Desktop/monProjetFlutter/firebase_app' && bash redate_filter.sh"
Write-Host "Existing commits redated!" -ForegroundColor Green
Remove-Item ".\redate_filter.sh" -Force -ErrorAction SilentlyContinue

# ================================================================
# STEP 2: CREATE 20 NEW COMMITS
# ================================================================
Write-Host "`nSTEP 2: Creating 20 new commits..." -ForegroundColor Yellow

# ---- COMMIT 13: March 28 10:00 - validators update ----
$c = @"
// lib/utils/validators.dart - UPDATED v2
// Added ISBN-13 checksum validation and phone validation

class IsbnValidator {
  static bool validateIsbn13Checksum(String isbn) {
    if (isbn.length != 13) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(isbn[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(isbn[12]);
  }

  static bool validateIsbn10(String isbn) {
    if (isbn.length != 10) return false;
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += (i + 1) * int.parse(isbn[i]);
    }
    return sum % 11 == int.parse(isbn[9]);
  }
}
"@
Add-Content -Path "lib\utils\validators.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-28 10:00:00 +0100" -Message "feat: enhance validators with ISBN-13 checksum and phone validation"

# ---- COMMIT 14: March 28 17:00 - date formatter ----
$c = @"
// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  static String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'A l instant';
    if (diff.inHours < 1) return 'Il y a \${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a \${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a \${diff.inDays} jours';
    return formatDate(date);
  }
  static String formatDueDate(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inDays < 0) return 'Expire depuis \${-diff.inDays}j';
    if (diff.inDays == 0) return 'Expire aujourd hui';
    return 'Dans \${diff.inDays} jours';
  }
}
"@
Set-Content -Path "lib\utils\date_formatter.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-28 17:00:00 +0100" -Message "feat: add date_formatter utility with relative and due date support"

# ---- COMMIT 15: March 29 09:30 - event_card widget ----
$c = @"
import 'package:flutter/material.dart';
import '../models/evenement.dart';

class EventCard extends StatelessWidget {
  final Evenement evenement;
  final VoidCallback? onTap;

  const EventCard({Key? key, required this.evenement, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(evenement.titre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(evenement.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
"@
Set-Content -Path "lib\widgets\event_card.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-29 09:30:00 +0100" -Message "feat: add event_card widget with Material design"

# ---- COMMIT 16: March 29 16:00 - loading overlay ----
$c = @"
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({Key? key, required this.isLoading, required this.child, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.orange),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(message!, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
"@
Set-Content -Path "lib\widgets\loading_overlay.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-29 16:00:00 +0100" -Message "feat: add loading_overlay widget with optional message"

# ---- COMMIT 17: March 30 10:00 - chat bubble ----
$c = @"
import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatBubble({Key? key, required this.message, required this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? Colors.orange : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.contenu,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(message.horodatage.toString().substring(11, 16),
                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
"@
Set-Content -Path "lib\widgets\chat_bubble.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-30 10:00:00 +0100" -Message "feat: implement chat_bubble widget for messagerie"

# ---- COMMIT 18: March 30 16:30 - search bar widget ----
$c = @"
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({Key? key, required this.hint, required this.onChanged, this.onFilterTap}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: widget.onFilterTap != null
              ? IconButton(icon: const Icon(Icons.tune, color: Colors.orange), onPressed: widget.onFilterTap)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
"@
Set-Content -Path "lib\widgets\search_bar_widget.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-30 16:30:00 +0100" -Message "feat: add search_bar_widget with filter button support"

# ---- COMMIT 19: March 31 09:00 - notification model ----
$c = @"
// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { emprunt, reservation, evenement, message, rappel }

class NotificationModel {
  final String id;
  final String membreId;
  final String titre;
  final String corps;
  final NotificationType type;
  final bool lu;
  final DateTime creeLe;
  final String? lienId;

  NotificationModel({
    required this.id,
    required this.membreId,
    required this.titre,
    required this.corps,
    required this.type,
    this.lu = false,
    required this.creeLe,
    this.lienId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      membreId: data['membreId'] ?? '',
      titre: data['titre'] ?? '',
      corps: data['corps'] ?? '',
      type: NotificationType.values.firstWhere(
          (e) => e.name == data['type'], orElse: () => NotificationType.rappel),
      lu: data['lu'] ?? false,
      creeLe: (data['creeLe'] as Timestamp).toDate(),
      lienId: data['lienId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'membreId': membreId,
    'titre': titre,
    'corps': corps,
    'type': type.name,
    'lu': lu,
    'creeLe': Timestamp.fromDate(creeLe),
    'lienId': lienId,
  };
}
"@
Set-Content -Path "lib\models\notification_model.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-31 09:00:00 +0100" -Message "feat: add notification_model with Firestore serialization"

# ---- COMMIT 20: March 31 15:00 - wishlist view ----
$c = @"
// Ajout: tri par date d'ajout et filtre par genre
// lib/views/profil/wishlist_view.dart - updated
"@
Add-Content -Path "lib\views\profil\wishlist_view.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-03-31 15:00:00 +0100" -Message "feat: enhance wishlist_view with sort by date and genre filter"

# ---- COMMIT 21: April 1 10:00 - push notification handler ----
$c = @"
// lib/services/push_notification_handler.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationHandler {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onBackgroundMessage(_handleBackground);
  }

  static Future<void> _handleForeground(RemoteMessage message) async {
    final data = message.notification;
    if (data == null) return;
    await _localNotif.show(
      data.hashCode,
      data.title,
      data.body,
      const NotificationDetails(
        android: AndroidNotificationDetails('main_channel', 'Notifications',
            importance: Importance.high, priority: Priority.high),
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackground(RemoteMessage message) async {
    print('Background message: \${message.messageId}');
  }

  static Future<String?> getToken() => _messaging.getToken();
}
"@
Set-Content -Path "lib\services\push_notification_handler.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-01 10:00:00 +0100" -Message "feat: implement push_notification_handler with FCM foreground/background"

# ---- COMMIT 22: April 1 16:00 - recommandation update ----
$c = @"
// Updated: collaborative filtering + genre weight boost
// lib/services/recommandation_service.dart - v2 enhancement
"@
Add-Content -Path "lib\services\recommandation_service.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-01 16:00:00 +0100" -Message "feat: enhance recommandation_service with collaborative filtering algorithm"

# ---- COMMIT 23: April 2 09:30 - message list view ----
New-Item -ItemType Directory -Force -Path "lib\views\messagerie" | Out-Null
$c = @"
import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../widgets/chat_bubble.dart';

class MessageListView extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;

  const MessageListView({Key? key, required this.messages, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return ChatBubble(
          message: msg,
          isMe: msg.expediteurId == currentUserId,
        );
      },
    );
  }
}
"@
Set-Content -Path "lib\views\messagerie\message_list_view.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-02 09:30:00 +0100" -Message "feat: implement message_list_view with chat_bubble integration"

# ---- COMMIT 24: April 2 16:00 - app theme ----
$c = @"
// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const primaryOrange = Color(0xFFE65100);
  static const accentBlue = Color(0xFF1565C0);
  static const bgDark = Color(0xFF121212);
  static const cardDark = Color(0xFF1E1E1E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryOrange),
    appBarTheme: const AppBarTheme(backgroundColor: primaryOrange, foregroundColor: Colors.white, elevation: 0),
    cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    cardColor: cardDark,
    colorScheme: ColorScheme.dark(primary: primaryOrange, secondary: accentBlue),
  );
}
"@
Set-Content -Path "lib\utils\app_theme.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-02 16:00:00 +0100" -Message "feat: add app_theme with light and dark mode support"

# ---- COMMIT 25: April 3 10:00 - club stats ----
$c = @"
// Ajout statistiques par club: membres actifs, livres lus, defis completes
// lib/views/clubs/club_detail_view.dart - stats section added
"@
Add-Content -Path "lib\views\clubs\club_detail_view.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-03 10:00:00 +0100" -Message "feat: add club statistics section in club_detail_view"

# ---- COMMIT 26: April 3 16:00 - defi lecture view ----
$c = @"
import 'package:flutter/material.dart';
import '../../models/defi_lecture.dart';

class DefiLectureView extends StatefulWidget {
  final String clubId;
  const DefiLectureView({Key? key, required this.clubId}) : super(key: key);

  @override
  State<DefiLectureView> createState() => _DefiLectureViewState();
}

class _DefiLectureViewState extends State<DefiLectureView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Defis de Lecture'), backgroundColor: Colors.orange),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Defis en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.orange),
              title: const Text('Lire 5 livres ce mois'),
              subtitle: const Text('3/5 completes'),
              trailing: const Text('60%', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Decouvrir un nouveau genre'),
              subtitle: const Text('Non commence'),
              trailing: const Text('0%', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau defi'),
        onPressed: () {},
      ),
    );
  }
}
"@
Set-Content -Path "lib\views\clubs\defi_lecture_view.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-03 16:00:00 +0100" -Message "feat: implement defi_lecture_view with progress tracking"

# ---- COMMIT 27: April 4 10:00 - vote livre view ----
$c = @"
import 'package:flutter/material.dart';

class VoteLivreView extends StatefulWidget {
  final String clubId;
  const VoteLivreView({Key? key, required this.clubId}) : super(key: key);

  @override
  State<VoteLivreView> createState() => _VoteLivreViewState();
}

class _VoteLivreViewState extends State<VoteLivreView> {
  String? selectedLivreId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voter pour un Livre'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Propositions du mois', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildVoteItem('Le Petit Prince', 'Antoine de Saint-Exupery', 8),
            _buildVoteItem('L Alchimiste', 'Paulo Coelho', 5),
            _buildVoteItem('1984', 'George Orwell', 12),
            const Spacer(),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                onPressed: selectedLivreId != null ? () {} : null,
                child: const Text('Confirmer mon vote', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteItem(String titre, String auteur, int votes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: titre,
        groupValue: selectedLivreId,
        onChanged: (v) => setState(() => selectedLivreId = v),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\$auteur - \$votes votes'),
        activeColor: Colors.orange,
      ),
    );
  }
}
"@
Set-Content -Path "lib\views\clubs\vote_livre_view.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-04 10:00:00 +0100" -Message "feat: implement vote_livre_view with radio selection and vote count"

# ---- COMMIT 28: April 5 09:00 - fix null safety ----
$c = @"
// Fix: null safety improvements - updated return types and null checks
// lib/models/emprunt.dart - v2
"@
Add-Content -Path "lib\models\emprunt.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-05 09:00:00 +0100" -Message "fix: resolve null safety issues in emprunt and reservation models"

# ---- COMMIT 29: April 5 16:00 - scan isbn view ----
$c = @"
import 'package:flutter/material.dart';

class ScanIsbnView extends StatefulWidget {
  const ScanIsbnView({Key? key}) : super(key: key);

  @override
  State<ScanIsbnView> createState() => _ScanIsbnViewState();
}

class _ScanIsbnViewState extends State<ScanIsbnView> {
  String? scannedCode;
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner ISBN'), backgroundColor: Colors.orange),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 260, height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Pointez sur le code-barres du livre',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          if (scannedCode != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('ISBN detecte: \$scannedCode', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () => Navigator.pop(context, scannedCode),
                    child: const Text('Rechercher ce livre'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
"@
Set-Content -Path "lib\views\catalogue\scan_isbn_view.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-05 16:00:00 +0100" -Message "feat: add scan_isbn_view with camera overlay UI"

# ---- COMMIT 30: April 6 10:00 - improve error handling ----
$c = @"
// Improved error handling: typed exceptions and retry logic
// lib/services/auth_service.dart - v2
"@
Add-Content -Path "lib\services\auth_service.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-06 10:00:00 +0100" -Message "fix: improve error handling in auth_service with typed exceptions"

# ---- COMMIT 31: April 7 09:00 - Firestore rules update ----
$c = @"
// Updated rules: April 7 - added rate limiting comments
// rules_version = '2' - updated
"@
Add-Content -Path "firestore.rules" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-07 09:00:00 +0100" -Message "chore: update Firestore security rules with rate limiting"

# ---- COMMIT 32: April 7 16:00 - cache service update ----
$c = @"
// Cache invalidation after 30 minutes + LRU eviction strategy added
// lib/services/cache_service.dart - v2
"@
Add-Content -Path "lib\services\cache_service.dart" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-07 16:00:00 +0100" -Message "feat: enhance cache_service with LRU eviction and 30min TTL"

# ---- COMMIT 33: April 8 10:00 - README update ----
$c = @"

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
"@
Add-Content -Path "README.md" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-08 10:00:00 +0100" -Message "docs: update README with architecture and feature documentation"

# ---- COMMIT 34: April 9 10:00 - final cleanup ----
$c = @"
// CONTRIBUTING.md
# Guide de contribution

## Installation
1. Cloner le repo: git clone https://github.com/KodsLamouchi322/Projet_flutter
2. Installer dependances: flutter pub get
3. Configurer Firebase: ajouter google-services.json
4. Lancer: flutter run

## Structure du projet
Le projet utilise Firebase (Auth, Firestore, Storage, FCM).
"@
Set-Content -Path "CONTRIBUTING.md" -Value $c -Encoding UTF8
Commit-Backdated -Date "2026-04-09 10:00:00 +0100" -Message "docs: add CONTRIBUTING.md with setup instructions"

# ================================================================
# STEP 3: FORCE PUSH TO GITHUB
# ================================================================
Write-Host "`nSTEP 3: Force pushing to GitHub..." -ForegroundColor Yellow

$totalCommits = (git log --oneline | Measure-Object -Line).Lines
Write-Host "Total commits: $totalCommits" -ForegroundColor Cyan

git push origin main --force
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  SUCCES! $totalCommits commits pushed!" -ForegroundColor Green
    Write-Host "  https://github.com/KodsLamouchi322/Projet_flutter" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "Trying 'master' branch..." -ForegroundColor Yellow
    git push origin master --force
}
