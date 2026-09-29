import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'user_animal_detail_screen.dart';

class UserNotificationsScreen extends StatelessWidget {
  final AppUser user;
  const UserNotificationsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Theme(
      data: AppTheme.user(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Bildirimler'),
          backgroundColor: AppColors.userPrimary,
        ),
        body: StreamBuilder<List<Animal>>(
          stream: db.animalsStream(user.id),
          builder: (ctx, snap) {
            final all = snap.data ?? [];
            final urgent = all
                .where((a) => a.daysUntilBirth >= 0 && a.daysUntilBirth <= 30)
                .toList();

            if (urgent.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 60,
                      color: AppColors.userAccent,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bildirim yok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '30 gün içinde planlı doğum bulunmuyor.',
                      style: TextStyle(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.userPrimary, AppColors.userSecondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${urgent.length} yaklaşan doğum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...urgent.map((a) {
                  final days = a.daysUntilBirth;
                  final color = AppColors.urgency(a.urgencyLabel);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      borderColor: color.withValues(alpha: 0.3),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserAnimalDetailScreen(animal: a),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  days == 0
                                      ? Icons.warning_rounded
                                      : Icons.schedule,
                                  color: color,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    days == 0
                                        ? '⚠️ Doğum zamanı!'
                                        : days == 1
                                        ? 'Yarın doğum bekleniyor'
                                        : '$days gün sonra doğum',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (a.expectedBirth != null)
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy',
                                        'tr',
                                      ).format(a.expectedBirth!),
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            StatusBadge(label: a.urgencyLabel, color: color),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
