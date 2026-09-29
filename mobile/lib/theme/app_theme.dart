import 'package:flutter/material.dart';

// ─── Renk Paleti ─────────────────────────────────────────────────────────────
class AppColors {
  // Kullanıcı teması — mavi/mor
  static const userPrimary   = Color(0xFF3D5AFE);
  static const userSecondary = Color(0xFF1A237E);
  static const userAccent    = Color(0xFF82B1FF);
  static const userLight     = Color(0xFFE8EAFF);

  // Veteriner teması — koyu teal/petrol
  static const vetPrimary    = Color(0xFF006064);
  static const vetSecondary  = Color(0xFF00363A);
  static const vetAccent     = Color(0xFF80DEEA);
  static const vetLight      = Color(0xFFE0F7FA);

  // Ortak
  static const danger        = Color(0xFFD32F2F);
  static const warning       = Color(0xFFF57C00);
  static const success       = Color(0xFF2E7D32);
  static const info          = Color(0xFF0288D1);

  // Nötr
  static const bg            = Color(0xFFF8F9FC);
  static const surface       = Colors.white;
  static const textDark      = Color(0xFF1A1A2E);
  static const textMid       = Color(0xFF4A4A6A);
  static const textLight     = Color(0xFF9E9EB8);
  static const border        = Color(0xFFE8E8F0);

  // Urgency renkleri
  static Color urgency(String u) {
    switch (u) {
      case 'KRİTİK': return danger;
      case 'ACİL':   return Color(0xFFE53935);
      case 'YÜKSEK': return warning;
      default:       return success;
    }
  }
}

// ─── Temalar ──────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData user() => _buildTheme(
    AppColors.userPrimary, AppColors.userSecondary, AppColors.userLight,
  );

  static ThemeData vet() => _buildTheme(
    AppColors.vetPrimary, AppColors.vetSecondary, AppColors.vetLight,
  );

  static ThemeData _buildTheme(Color primary, Color secondary, Color light) =>
      ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary, brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: Colors.white, letterSpacing: 0.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary, width: 1.5),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: AppColors.textMid),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: light,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

// ─── Ortak Widget'lar ─────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  const AppCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? AppColors.border),
    ),
    padding: padding ?? const EdgeInsets.all(16),
    child: child,
  );
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsets? padding;
  const GradientCard(
      {super.key, required this.colors, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    padding: padding ?? const EdgeInsets.all(20),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  const SectionTitle(this.title, this.icon, {this.color, super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18,
        color: color ?? Theme.of(context).colorScheme.primary),
    const SizedBox(width: 8),
    Text(title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark)),
  ]);
}
