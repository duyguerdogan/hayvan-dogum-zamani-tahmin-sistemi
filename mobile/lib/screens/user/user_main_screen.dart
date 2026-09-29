import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_screen.dart';
import 'user_add_animal_screen.dart';
import 'user_animal_detail_screen.dart';
import 'user_calendar_screen.dart';
import 'user_notifications_screen.dart';
import '../../live_monitor_screen.dart'; // DOĞRU

class UserMainScreen extends StatefulWidget {
  final AppUser user;
  const UserMainScreen({super.key, required this.user});
  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _tab = 0;
  final _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.user(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('VetDoğum'),
          backgroundColor: AppColors.userPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserNotificationsScreen(user: widget.user),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(user: widget.user, db: _db),
            _AnimalsTab(user: widget.user, db: _db),
            UserCalendarScreen(uid: widget.user.id),
            LiveMonitorScreen(ownerId: widget.user.id, isVet: false),
            _UserProfile(user: widget.user),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Hayvanlarım',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Takvim',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: 'Canlı İzleme',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
        floatingActionButton: _tab == 1
            ? FloatingActionButton(
                backgroundColor: AppColors.userPrimary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserAddAnimalScreen(ownerId: widget.user.id),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }
}

// ─── Ana Sekme ────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final AppUser user;
  final FirestoreService db;
  const _HomeTab({required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Animal>>(
      stream: db.animalsStream(user.id),
      builder: (ctx, snap) {
        final animals = snap.data ?? [];
        final upcoming = animals
            .where((a) => a.daysUntilBirth >= 0 && a.daysUntilBirth <= 14)
            .toList();
        final risky = animals
            .where((a) => ['KRİTİK', 'ACİL', 'YÜKSEK'].contains(a.urgencyLabel))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Karşılama
            GradientCard(
              colors: [AppColors.userPrimary, AppColors.userSecondary],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.waving_hand,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Merhaba, ${user.name.split(' ').first}!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    upcoming.isEmpty
                        ? 'Yaklaşan doğum bulunmuyor'
                        : '${upcoming.length} yaklaşan doğum var',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (risky.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⚠️ ${risky.length} riskli hayvan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // İstatistikler
            Row(
              children: [
                _StatCard(
                  'Toplam',
                  animals.length.toString(),
                  Icons.pets,
                  AppColors.userPrimary,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  'Bu Hafta',
                  upcoming.length.toString(),
                  Icons.schedule,
                  AppColors.warning,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  'Riskli',
                  risky.length.toString(),
                  Icons.warning_amber,
                  AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Yaklaşan doğumlar
            if (upcoming.isNotEmpty) ...[
              const SectionTitle('Yaklaşan Doğumlar', Icons.schedule),
              const SizedBox(height: 10),
              ...upcoming.map((a) => _UserAnimalCard(animal: a)),
              const SizedBox(height: 20),
            ],

            // Riskli hayvanlar
            if (risky.isNotEmpty) ...[
              const SectionTitle(
                'Dikkat Gerektiren',
                Icons.warning_amber_outlined,
                color: AppColors.danger,
              ),
              const SizedBox(height: 10),
              ...risky.map((a) => _UserAnimalCard(animal: a)),
              const SizedBox(height: 20),
            ],

            if (animals.isEmpty)
              _EmptyState(
                icon: Icons.pets,
                title: 'Henüz hayvan eklemediniz',
                subtitle: 'Hayvanlarım sekmesinden ekleyebilirsiniz.',
              ),
          ],
        );
      },
    );
  }
}

class _AnimalsTab extends StatelessWidget {
  final AppUser user;
  final FirestoreService db;
  const _AnimalsTab({required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Animal>>(
      stream: db.animalsStream(user.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final animals = snap.data ?? [];
        if (animals.isEmpty) {
          return _EmptyState(
            icon: Icons.add_circle_outline,
            title: 'Henüz hayvan yok',
            subtitle: 'Sağ alttaki + butonuna tıklayın.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: animals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _UserAnimalCard(animal: animals[i]),
        );
      },
    );
  }
}

// ─── Kullanıcı Hayvan Kartı ───────────────────────────────────────────────────
class _UserAnimalCard extends StatelessWidget {
  final Animal animal;
  const _UserAnimalCard({required this.animal});

  @override
  Widget build(BuildContext context) {
    final days = animal.daysUntilBirth;
    final color = AppColors.urgency(animal.urgencyLabel);

    return AppCard(
      borderColor: days <= 3 ? color.withValues(alpha: 0.3) : AppColors.border,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserAnimalDetailScreen(animal: animal),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.userLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  speciesEmoji(animal.species),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${kSpeciesTR[animal.species] ?? animal.species} · ${animal.breed}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  if (animal.expectedBirth != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      days <= 0
                          ? '🚨 Doğum zamanı!'
                          : days == 1
                          ? '⚡ Yarın doğum bekleniyor'
                          : '📅 $days gün sonra · ${DateFormat('dd MMM').format(animal.expectedBirth!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: animal.urgencyLabel, color: color),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ortak widget'lar ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.userAccent),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ─── Kullanıcı Profil Sekmesi ─────────────────────────────────────────────────
class _UserProfile extends StatefulWidget {
  final AppUser user;
  const _UserProfile({required this.user});
  @override
  State<_UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<_UserProfile> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _addressCtrl = TextEditingController(text: widget.user.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = AppUser(
        id: widget.user.id,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        email: widget.user.email,
        role: widget.user.role,
      );
      await FirestoreService().saveUser(updated);
      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi!'),
            backgroundColor: AppColors.userPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Center(
        child: Stack(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.userLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.userPrimary,
                size: 44,
              ),
            ),
            if (_editing)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.userPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          widget.user.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      Center(
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.userLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Hayvan Sahibi',
            style: TextStyle(
              color: AppColors.userPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),

      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_editing)
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Düzenle'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.userPrimary,
              ),
              onPressed: () => setState(() => _editing = true),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('İptal'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () {
                setState(() => _editing = false);
                _nameCtrl.text = widget.user.name;
                _phoneCtrl.text = widget.user.phone;
                _addressCtrl.text = widget.user.address;
              },
            ),
        ],
      ),

      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kişisel Bilgiler',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),
            if (_editing) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ] else ...[
              _ProfileRow('Ad Soyad', widget.user.name, Icons.person_outline),
              _ProfileRow('E-posta', widget.user.email, Icons.email_outlined),
              _ProfileRow(
                'Telefon',
                widget.user.phone.isEmpty ? '—' : widget.user.phone,
                Icons.phone_outlined,
              ),
              _ProfileRow(
                'Adres',
                widget.user.address.isEmpty ? '—' : widget.user.address,
                Icons.location_on_outlined,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      if (_editing) ...[
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.userPrimary,
          ),
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
        ),
        const SizedBox(height: 12),
      ],

      // Hayvan istatistikleri
      StreamBuilder<List<Animal>>(
        stream: FirestoreService().animalsStream(widget.user.id),
        builder: (ctx, snap) {
          final animals = snap.data ?? [];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatBox(
                      'Toplam',
                      animals.length.toString(),
                      Icons.pets,
                      AppColors.userPrimary,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      'Yaklaşan',
                      animals
                          .where(
                            (a) =>
                                a.daysUntilBirth >= 0 && a.daysUntilBirth <= 14,
                          )
                          .length
                          .toString(),
                      Icons.schedule,
                      AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      'Riskli',
                      animals
                          .where(
                            (a) => [
                              'KRİTİK',
                              'ACİL',
                              'YÜKSEK',
                            ].contains(a.urgencyLabel),
                          )
                          .length
                          .toString(),
                      Icons.warning_amber,
                      AppColors.danger,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 14),

      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Çıkış Yap'),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
              (_) => false,
            );
          }
        },
      ),
      const SizedBox(height: 24),
    ],
  );
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ProfileRow(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textLight),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
