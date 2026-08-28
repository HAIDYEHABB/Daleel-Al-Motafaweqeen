import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Renders the real app logo (assets/logo.png). Falls back to a vector
/// redraw (open book + swoosh) if the asset is ever missing, so the UI
/// never breaks if someone forgets to add the image file.
class AppLogoMark extends StatelessWidget {
  final double size;
  const AppLogoMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: AppColors.heroGradient,
          ),
          child: Icon(Icons.auto_stories_rounded,
              color: Colors.white, size: size * 0.56),
        ),
      ),
    );
  }
}

/// The signature accent element: a soft diagonal "swoosh" band with
/// scattered stars, echoing the logo's starlit page. Used behind hero
/// headers to keep the brand consistent without repeating a plain
/// gradient block on every screen.
class AppSwooshHeader extends StatelessWidget {
  final Widget child;
  final double height;
  const AppSwooshHeader({super.key, required this.child, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppRadius.lg),
        bottomRight: Radius.circular(AppRadius.lg),
      ),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(
              left: -30,
              top: -40,
              child: _swooshCircle(120, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              right: -20,
              bottom: -50,
              child: _swooshCircle(160, Colors.white.withValues(alpha: 0.10)),
            ),
            const Positioned(right: 28, top: 22, child: _Star(size: 14)),
            const Positioned(right: 70, top: 50, child: _Star(size: 8)),
            const Positioned(left: 40, bottom: 30, child: _Star(size: 10)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _swooshCircle(double d, Color color) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Star extends StatelessWidget {
  final double size;
  const _Star({required this.size});
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded,
        size: size, color: Colors.white.withValues(alpha: 0.85));
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const PrimaryButton(
      {super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// A small rounded metric card used on dashboards
/// (e.g. "نسبة الحضور 90%").
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpace.md, horizontal: AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Chip-style badge, e.g. "متبقي: 3 حصص" or a group's student count.
class InfoBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const InfoBadge(
      {super.key, required this.text, this.color = AppColors.primary, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: GoogleFonts.cairo(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
