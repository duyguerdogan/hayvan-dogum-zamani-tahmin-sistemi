import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'user_animal_detail_screen.dart';

class UserCalendarScreen extends StatefulWidget {
  final String uid;
  const UserCalendarScreen({super.key, required this.uid});
  @override
  State<UserCalendarScreen> createState() => _CalState();
}

class _CalState extends State<UserCalendarScreen> {
  final _db = FirestoreService();
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.user(),
      child: StreamBuilder<List<Animal>>(
        stream: _db.animalsStream(widget.uid),
        builder: (ctx, snap) {
          final animals = snap.data ?? [];
          final events = <DateTime, List<Animal>>{};
          for (final a in animals) {
            if (a.expectedBirth == null) continue;
            final d = DateTime(
              a.expectedBirth!.year,
              a.expectedBirth!.month,
              a.expectedBirth!.day,
            );
            events.putIfAbsent(d, () => []).add(a);
          }

          List<Animal> eventsFor(DateTime d) =>
              events[DateTime(d.year, d.month, d.day)] ?? [];
          final selAnimals = eventsFor(_selected);

          return Column(
            children: [
              TableCalendar<Animal>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 400)),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                eventLoader: eventsFor,
                onDaySelected: (s, f) => setState(() {
                  _selected = s;
                  _focused = f;
                }),
                onPageChanged: (f) => setState(() => _focused = f),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.userPrimary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.userAccent.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 6,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: selAnimals.isEmpty
                    ? Center(
                        child: Text(
                          '${DateFormat('dd MMMM', 'tr').format(_selected)}\ntarihinde doğum yok',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: selAnimals.map((a) {
                          final color = AppColors.urgency(a.urgencyLabel);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserAnimalDetailScreen(animal: a),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Text(
                                      speciesEmoji(a.species),
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            kSpeciesTR[a.species] ?? a.species,
                                            style: const TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      label: a.urgencyLabel,
                                      color: color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
