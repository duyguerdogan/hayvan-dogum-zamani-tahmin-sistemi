import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_screen.dart';
import '../../live_monitor_screen.dart'; // DOĞRU
import 'vet_observation_screen.dart';

class VetMainScreen extends StatefulWidget {
  final AppUser user;
  const VetMainScreen({super.key, required this.user});
  @override
  State<VetMainScreen> createState() => _VetMainState();
}

class _VetMainState extends State<VetMainScreen> {
  int _tab = 0;
  final _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.vet(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.vetPrimary,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services, size: 20),
              SizedBox(width: 8),
              Text('VetDoğum'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            _VetDashboard(vet: widget.user, db: _db),
            _VetAllAnimals(vet: widget.user, db: _db),
            LiveMonitorScreen(ownerId: widget.user.id, isVet: true),
            _VetProfile(vet: widget.user),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.vetLight,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Tüm Hayvanlar',
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
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
class _VetDashboard extends StatelessWidget {
  final AppUser vet;
  final FirestoreService db;
  const _VetDashboard({required this.vet, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Animal>>(
      stream: db.allAnimalsStream(),
      builder: (ctx, snap) {
        final all = snap.data ?? [];
        final critical = all
            .where((a) => ['KRİTİK', 'ACİL'].contains(a.urgencyLabel))
            .toList();
        final upcoming = all
            .where((a) => a.daysUntilBirth >= 0 && a.daysUntilBirth <= 7)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GradientCard(
              colors: [AppColors.vetPrimary, AppColors.vetSecondary],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_services,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dr. ${vet.name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (vet.clinicName != null && vet.clinicName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      vet.clinicName!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    critical.isEmpty
                        ? 'Kritik durum yok ✓'
                        : '${critical.length} kritik durum!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toplam ${all.length} hayvan takip ediliyor',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _VetStat(
                  'Toplam',
                  all.length.toString(),
                  Icons.pets,
                  AppColors.vetPrimary,
                ),
                const SizedBox(width: 8),
                _VetStat(
                  'Bu Hafta',
                  upcoming.length.toString(),
                  Icons.schedule,
                  AppColors.warning,
                ),
                const SizedBox(width: 8),
                _VetStat(
                  'Kritik',
                  critical.length.toString(),
                  Icons.warning_amber,
                  AppColors.danger,
                ),
                const SizedBox(width: 8),
                _VetStat(
                  'Normal',
                  all
                      .where((a) => a.urgencyLabel == 'NORMAL')
                      .length
                      .toString(),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ApiStatus(),
            const SizedBox(height: 16),

            if (critical.isNotEmpty) ...[
              const SectionTitle(
                'KRİTİK / ACİL',
                Icons.warning_amber,
                color: AppColors.danger,
              ),
              const SizedBox(height: 10),
              ...critical.map(
                (a) => _VetAnimalCard(animal: a, vet: vet, db: db),
              ),
              const SizedBox(height: 16),
            ],

            if (upcoming.isNotEmpty) ...[
              const SectionTitle('Bu Hafta Doğum', Icons.schedule),
              const SizedBox(height: 10),
              ...upcoming.map(
                (a) => _VetAnimalCard(animal: a, vet: vet, db: db),
              ),
            ],

            if (all.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 60, color: AppColors.vetAccent),
                      SizedBox(height: 16),
                      Text(
                        'Henüz kayıtlı hayvan yok',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Tüm Hayvanlar ────────────────────────────────────────────────────────────
class _VetAllAnimals extends StatefulWidget {
  final AppUser vet;
  final FirestoreService db;
  const _VetAllAnimals({required this.vet, required this.db});
  @override
  State<_VetAllAnimals> createState() => _VetAllAnimalsState();
}

class _VetAllAnimalsState extends State<_VetAllAnimals> {
  String _filter = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Animal>>(
      stream: widget.db.allAnimalsStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        final filtered = _filter == 'Tümü'
            ? all
            : all.where((a) => a.urgencyLabel == _filter).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Tümü', 'KRİTİK', 'ACİL', 'YÜKSEK', 'NORMAL']
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: AppColors.vetLight,
                            checkmarkColor: AppColors.vetPrimary,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Bu kategoride hayvan yok',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _VetAnimalCard(
                        animal: filtered[i],
                        vet: widget.vet,
                        db: widget.db,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Veteriner Profil ─────────────────────────────────────────────────────────
class _VetProfile extends StatefulWidget {
  final AppUser vet;
  const _VetProfile({required this.vet});
  @override
  State<_VetProfile> createState() => _VetProfileState();
}

class _VetProfileState extends State<_VetProfile> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _clinicCtrl;
  late TextEditingController _licCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vet.name);
    _phoneCtrl = TextEditingController(text: widget.vet.phone);
    _clinicCtrl = TextEditingController(text: widget.vet.clinicName ?? '');
    _licCtrl = TextEditingController(text: widget.vet.licenseNo ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _clinicCtrl.dispose();
    _licCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = AppUser(
        id: widget.vet.id,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: widget.vet.address,
        email: widget.vet.email,
        role: widget.vet.role,
        clinicName: _clinicCtrl.text.trim().isEmpty
            ? null
            : _clinicCtrl.text.trim(),
        licenseNo: _licCtrl.text.trim().isEmpty ? null : _licCtrl.text.trim(),
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
            backgroundColor: AppColors.vetPrimary,
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
                color: AppColors.vetLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services,
                color: AppColors.vetPrimary,
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
                    color: AppColors.vetPrimary,
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
          'Dr. ${widget.vet.name}',
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
            color: AppColors.vetLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Veteriner Hekim',
            style: TextStyle(
              color: AppColors.vetPrimary,
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
                foregroundColor: AppColors.vetPrimary,
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
                _nameCtrl.text = widget.vet.name;
                _phoneCtrl.text = widget.vet.phone;
                _clinicCtrl.text = widget.vet.clinicName ?? '';
                _licCtrl.text = widget.vet.licenseNo ?? '';
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
            ] else ...[
              _PR('Ad Soyad', widget.vet.name, Icons.person_outline),
              _PR('E-posta', widget.vet.email, Icons.email_outlined),
              _PR(
                'Telefon',
                widget.vet.phone.isEmpty ? '—' : widget.vet.phone,
                Icons.phone_outlined,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mesleki Bilgiler',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),
            if (_editing) ...[
              TextField(
                controller: _clinicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Klinik Adı',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _licCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lisans No',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ] else ...[
              _PR(
                'Klinik',
                widget.vet.clinicName?.isNotEmpty == true
                    ? widget.vet.clinicName!
                    : '—',
                Icons.local_hospital_outlined,
              ),
              _PR(
                'Lisans No',
                widget.vet.licenseNo?.isNotEmpty == true
                    ? widget.vet.licenseNo!
                    : '—',
                Icons.badge_outlined,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      if (_editing) ...[
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vetPrimary,
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

class _PR extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _PR(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.vetPrimary),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
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

// ─── Veteriner Hayvan Kartı ───────────────────────────────────────────────────
class _VetAnimalCard extends StatelessWidget {
  final Animal animal;
  final AppUser vet;
  final FirestoreService db;
  const _VetAnimalCard({
    required this.animal,
    required this.vet,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.urgency(animal.urgencyLabel);
    final days = animal.daysUntilBirth;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        borderColor: color.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _VetAnimalDetail(animal: animal, vet: vet, db: db),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        speciesEmoji(animal.species),
                        style: const TextStyle(fontSize: 24),
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
                        Text(
                          '${kSpeciesTR[animal.species]} · ${animal.breed} · ${animal.age} yaş · ${animal.weight}kg',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                        FutureBuilder<String>(
                          future: db.getCachedUserName(animal.ownerId),
                          builder: (ctx, snap) => Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 11,
                                color: AppColors.userPrimary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Sahip: ${snap.data ?? "..."}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.userPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(label: animal.urgencyLabel, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _Chip(
                      Icons.schedule,
                      days <= 0 ? 'Doğum zamanı' : '$days gün',
                    ),
                    const SizedBox(width: 12),
                    if (animal.expectedBirth != null)
                      _Chip(
                        Icons.calendar_today,
                        DateFormat('dd MMM').format(animal.expectedBirth!),
                      ),
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.textLight),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textMid),
      ),
    ],
  );
}

// ─── Veteriner Hayvan Detay ───────────────────────────────────────────────────
class _VetAnimalDetail extends StatelessWidget {
  final Animal animal;
  final AppUser vet;
  final FirestoreService db;
  const _VetAnimalDetail({
    required this.animal,
    required this.vet,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.urgency(animal.urgencyLabel);

    return Theme(
      data: AppTheme.vet(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.vetPrimary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  animal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.vetPrimary, AppColors.vetSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          speciesEmoji(animal.species),
                          style: const TextStyle(fontSize: 52),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                          label: animal.urgencyLabel,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Klinik Bilgiler',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _VRow(
                          'Tür',
                          kSpeciesTR[animal.species] ?? animal.species,
                        ),
                        _VRow('Irk', animal.breed.isEmpty ? '—' : animal.breed),
                        _VRow('Yaş', '${animal.age} yaş'),
                        _VRow('Canlı Ağırlık', '${animal.weight} kg'),
                        _VRow(
                          'Gebelik Süresi',
                          '${Animal.gestationDays(animal.species)} gün',
                        ),
                        if (animal.matingDate != null)
                          _VRow(
                            'Çiftleşme',
                            DateFormat(
                              'dd MMMM yyyy',
                              'tr',
                            ).format(animal.matingDate!),
                          ),
                        if (animal.expectedBirth != null) ...[
                          _VRow(
                            'Tahmini Doğum',
                            DateFormat(
                              'dd MMMM yyyy',
                              'tr',
                            ).format(animal.expectedBirth!),
                          ),
                          _VRow(
                            'Kalan Süre',
                            animal.daysUntilBirth <= 0
                                ? '⚠️ Doğum zamanı'
                                : '${animal.daysUntilBirth} gün',
                            color: color,
                          ),
                        ],
                        if (animal.notes.isNotEmpty)
                          _VRow('Notlar', animal.notes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vetPrimary,
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Gözlem Ekle'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VetObservationScreen(
                                animal: animal,
                                vetId: vet.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                          ),
                          icon: const Icon(Icons.psychology_outlined, size: 18),
                          label: const Text('ML Tahmin'),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) =>
                                _VetPredictionSheet(animal: animal, db: db),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle('Tahmin Geçmişi', Icons.insights),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Prediction>>(
                    stream: db.predictionsStream(animal.id),
                    builder: (ctx, snap) {
                      final preds = snap.data ?? [];
                      if (preds.isEmpty) {
                        return const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Tahmin yapılmadı',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: preds
                            .map((p) => _VetPredTile(pred: p))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(
                    'Tüm Gözlemler',
                    Icons.visibility_outlined,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Observation>>(
                    stream: db.observationsStream(animal.id),
                    builder: (ctx, snap) {
                      final obs = snap.data ?? [];
                      if (obs.isEmpty) {
                        return const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Gözlem girilmedi',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: obs.map((o) => _VetObsTile(obs: o)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Veteriner Tahmin Bottom Sheet ───────────────────────────────────────────
class _VetPredictionSheet extends StatefulWidget {
  final Animal animal;
  final FirestoreService db;
  const _VetPredictionSheet({required this.animal, required this.db});
  @override
  State<_VetPredictionSheet> createState() => _VetPredictionSheetState();
}

class _VetPredictionSheetState extends State<_VetPredictionSheet> {
  final _tempCtrl = TextEditingController(text: '38.5');
  final _hrCtrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _caCtrl = TextEditingController();
  final _progCtrl = TextEditingController(text: '5.0');
  String _appetite = 'normal';
  String _mobility = 'normal';
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setDefaults(widget.animal.species);
  }

  void _setDefaults(String sp) {
    switch (sp) {
      case 'Cat':
        _hrCtrl.text = '130';
        _rrCtrl.text = '25';
        _caCtrl.text = '2.2';
      case 'Dog':
        _hrCtrl.text = '85';
        _rrCtrl.text = '28';
        _caCtrl.text = '2.3';
      case 'Cattle':
        _hrCtrl.text = '75';
        _rrCtrl.text = '35';
        _caCtrl.text = '9.5';
      case 'Sheep':
        _hrCtrl.text = '100';
        _rrCtrl.text = '30';
        _caCtrl.text = '2.0';
      case 'Goat':
        _hrCtrl.text = '110';
        _rrCtrl.text = '32';
        _caCtrl.text = '2.5';
      case 'Horse':
        _hrCtrl.text = '42';
        _rrCtrl.text = '22';
        _caCtrl.text = '11.0';
      case 'Pig':
        _hrCtrl.text = '90';
        _rrCtrl.text = '45';
        _caCtrl.text = '1.8';
      default:
        _hrCtrl.text = '80';
        _rrCtrl.text = '30';
        _caCtrl.text = '9.5';
    }
  }

  @override
  void dispose() {
    for (final c in [_tempCtrl, _hrCtrl, _rrCtrl, _caCtrl, _progCtrl])
      c.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    final temp = double.tryParse(_tempCtrl.text);
    final hr = int.tryParse(_hrCtrl.text);
    final rr = int.tryParse(_rrCtrl.text);
    final ca = double.tryParse(_caCtrl.text);
    final prog = double.tryParse(_progCtrl.text);

    if (temp == null ||
        hr == null ||
        rr == null ||
        ca == null ||
        prog == null) {
      setState(() => _error = 'Tüm değerleri doğru girin.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await ApiService.predict(
        animal: widget.animal,
        bodyTemp: temp,
        heartRate: hr,
        respRate: rr,
        calcium: ca,
        progesterone: prog,
        appetite: _appetite,
        mobility: _mobility,
      );
      setState(() {
        _result = data;
        _loading = false;
      });

      await widget.db.savePrediction(
        Prediction(
          id: '',
          animalId: widget.animal.id,
          date: DateTime.now(),
          probability: (data['successful_birth_percent'] ?? 0) / 100.0,
          urgency: data['urgency'] ?? '',
          prediction: data['prediction'] ?? '',
          modelProbabilities: Map<String, dynamic>.from(
            data['model_probabilities'] ?? {},
          ),
          inputFeatures: Map<String, dynamic>.from(
            data['input_features'] ?? {},
          ),
          riskFactors: List<String>.from(data['risk_factors_list'] ?? []),
          explanation: data['explanation'] ?? '',
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                const Text(
                  'ML Tahmin Analizi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.vetLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Railway API — Ensemble Model (RF + XGBoost + MLP + LSTM)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.vetSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _f(_tempCtrl, 'Sıcaklık °C')),
                    const SizedBox(width: 10),
                    Expanded(child: _f(_hrCtrl, 'Kalp atışı/dk')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _f(_rrCtrl, 'Solunum/dk')),
                    const SizedBox(width: 10),
                    Expanded(child: _f(_caCtrl, 'Kalsiyum mmol/L')),
                  ],
                ),
                const SizedBox(height: 10),
                _f(_progCtrl, 'Progesteron ng/mL'),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vetPrimary,
                  ),
                  onPressed: _loading ? null : _predict,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.psychology_outlined),
                  label: Text(
                    _loading
                        ? 'API analiz ediyor...'
                        : 'Tahmin Yap (Railway ML)',
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _VetResultCard(result: _result!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );
}

// ─── Veteriner Sonuç Kartı ────────────────────────────────────────────────────
class _VetResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _VetResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = (result['successful_birth_percent'] ?? 0).toDouble();
    final urgency = result['urgency'] ?? '';
    final color = AppColors.urgency(urgency);
    final models = result['model_probabilities'] as Map? ?? {};
    final risks = List<String>.from(result['risk_factors_list'] ?? []);
    final exp = result['explanation'] ?? '';

    return AppCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 8,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '%${pct.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const Text(
                          'başarı',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(label: urgency, color: color),
                    const SizedBox(height: 6),
                    Text(
                      result['prediction'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (models.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Model Olasılıkları',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ...models.entries.map((e) {
              final v = (e.value as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: v / 100,
                          minHeight: 8,
                          color: AppColors.vetPrimary,
                          backgroundColor: AppColors.vetLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${v.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (exp.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.vetLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                exp,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.vetSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],

          if (risks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Risk Faktörleri',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...risks.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tahmin ve Gözlem Tile'ları ───────────────────────────────────────────────
class _VetPredTile extends StatelessWidget {
  final Prediction pred;
  const _VetPredTile({required this.pred});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.urgency(pred.urgency);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '%${(pred.probability * 100).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(label: pred.urgency, color: color),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM HH:mm', 'tr').format(pred.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pred.prediction,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pred.modelProbabilities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: pred.modelProbabilities.entries
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.vetLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.vetSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VetObsTile extends StatelessWidget {
  final Observation obs;
  const _VetObsTile({required this.obs});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.vetLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.vetPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy HH:mm', 'tr').format(obs.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        _OChip('İştah: ${obs.appetite}'),
                        _OChip('Hareket: ${obs.mobility}'),
                        _OChip('${obs.temperature}°C'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (obs.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              obs.notes,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMid,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _OChip extends StatelessWidget {
  final String label;
  const _OChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.vetLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, color: AppColors.vetSecondary),
    ),
  );
}

// ─── API Durum Widget ─────────────────────────────────────────────────────────
class _ApiStatus extends StatefulWidget {
  @override
  State<_ApiStatus> createState() => _ApiStatusState();
}

class _ApiStatusState extends State<_ApiStatus> {
  bool? _online;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await ApiService.checkHealth();
    if (mounted) setState(() => _online = ok);
  }

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _online == null
                ? Colors.grey
                : _online!
                ? AppColors.success
                : AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Railway ML API',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _online == null
                    ? 'Kontrol ediliyor...'
                    : _online!
                    ? 'Çevrimiçi — Ensemble (RF+XGBoost+MLP+LSTM)'
                    : 'Çevrimdışı',
                style: TextStyle(
                  fontSize: 11,
                  color: _online == null
                      ? AppColors.textLight
                      : _online!
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: () {
            setState(() => _online = null);
            _check();
          },
          color: AppColors.vetPrimary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}

// ─── Yardımcı ─────────────────────────────────────────────────────────────────
class _VRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _VRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color ?? AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _VetStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _VetStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(10),
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
