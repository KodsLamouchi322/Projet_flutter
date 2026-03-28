import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Logo BiblioX — utilise le vrai PNG du logo
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText; // ignoré — le texte est dans l'image
  const AppLogo({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/Gemini_Generated_Image_bw3p95bw3p95bw3p.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackLogo(size: size, showText: showText),
      ),
    );
  }
}

/// Version compacte pour les headers — taille fixe, pas d'overflow
class AppLogoCompact extends StatelessWidget {
  final double size;
  const AppLogoCompact({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/Gemini_Generated_Image_bw3p95bw3p95bw3p.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackLogoCompact(size: size),
      ),
    );
  }
}

// ─── Fallback si l'image n'est pas encore dans les assets ────────────────────

class _FallbackLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const _FallbackLogo({required this.size, required this.showText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FallbackLogoCompact(size: size),
        if (showText) ...[
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Biblio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'x',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}

class _FallbackLogoCompact extends StatelessWidget {
  final double size;
  const _FallbackLogoCompact({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A5276),
        border: Border.all(color: const Color(0xFFFFD700), width: size * 0.05),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.3,
              child: _BookRect(
                w: size * 0.13, h: size * 0.26,
                color: const Color(0xFF2E4A8A),
              ),
            ),
            const SizedBox(width: 1),
            _BookRect(
              w: size * 0.15, h: size * 0.30,
              color: const Color(0xFFF39C12),
              hasLines: true,
            ),
            const SizedBox(width: 1),
            Transform.rotate(
              angle: 0.25,
              child: _BookRect(
                w: size * 0.13, h: size * 0.24,
                color: const Color(0xFFE74C3C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookRect extends StatelessWidget {
  final double w, h;
  final Color color;
  final bool hasLines;
  const _BookRect({required this.w, required this.h, required this.color, this.hasLines = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: hasLines
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 1.5, width: w * 0.65, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(height: 2),
                Container(height: 1.5, width: w * 0.55, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(height: 2),
                Container(height: 1.5, width: w * 0.65, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(height: 3),
                Container(height: w * 0.35, width: w * 0.5, color: Colors.white.withValues(alpha: 0.2)),
              ],
            )
          : null,
    );
  }
}
