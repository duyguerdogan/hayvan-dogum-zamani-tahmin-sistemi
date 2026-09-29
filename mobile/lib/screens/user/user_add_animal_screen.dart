import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class UserAddAnimalScreen extends StatefulWidget {
  final String ownerId;
  final Animal? animal;
  const UserAddAnimalScreen({super.key, required this.ownerId, this.animal});
  @override
  State<UserAddAnimalScreen> createState() => _State();
}

class _State extends State<UserAddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _species = 'Cattle';
  DateTime? _mating, _expectedBirth;
  bool _saving = false;
  final _db = FirestoreService();

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    if (a != null) {
      _nameCtrl.text = a.name;
      _breedCtrl.text = a.breed;
      _ageCtrl.text = a.age.toString();
      _weightCtrl.text = a.weight.toString();
      _notesCtrl.text = a.notes;
      _species = a.species;
      _mating = a.matingDate;
      _expectedBirth = a.expectedBirth;
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _breedCtrl, _ageCtrl, _weightCtrl, _notesCtrl])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.user(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(
            widget.animal != null ? 'Hayvanı Düzenle' : 'Yeni Hayvan',
          ),
          backgroundColor: AppColors.userPrimary,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section('Temel Bilgiler', [
                _field(
                  _nameCtrl,
                  'Hayvan Adı *',
                  Icons.label_outline,
                  validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _species,
                  decoration: const InputDecoration(
                    labelText: 'Tür *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: kSpecies
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('${speciesEmoji(s)} ${kSpeciesTR[s]!}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _species = v!;
                      if (_mating != null)
                        _expectedBirth = Animal.calcExpectedBirth(
                          _species,
                          _mating!,
                        );
                    });
                  },
                ),
                const SizedBox(height: 12),
                _field(_breedCtrl, 'Irk', Icons.eco_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _ageCtrl,
                        'Yaş',
                        Icons.cake_outlined,
                        type: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        _weightCtrl,
                        'Kilo (kg)',
                        Icons.monitor_weight_outlined,
                        type: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              _Section('Çiftleşme ve Doğum', [
                _dateTile(
                  'Çiftleşme Tarihi',
                  Icons.favorite_outline,
                  _mating,
                  () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime.now(),
                    );
                    if (d != null)
                      setState(() {
                        _mating = d;
                        _expectedBirth = Animal.calcExpectedBirth(_species, d);
                      });
                  },
                ),
                const SizedBox(height: 10),
                _dateTile(
                  'Tahmini Doğum',
                  Icons.child_care,
                  _expectedBirth,
                  () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate:
                          _expectedBirth ??
                          DateTime.now().add(const Duration(days: 60)),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 400)),
                    );
                    if (d != null) setState(() => _expectedBirth = d);
                  },
                  subtitle: _mating != null
                      ? 'Otomatik (${Animal.gestationDays(_species)} gün)'
                      : null,
                ),
                if (_expectedBirth != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.userLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.userPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Doğuma ${_expectedBirth!.difference(DateTime.now()).inDays} gün kaldı',
                          style: const TextStyle(
                            color: AppColors.userPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 14),
              _Section('Notlar', [
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ek notlar',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ]),
              const SizedBox(height: 24),
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
                    : Icon(
                        widget.animal != null
                            ? Icons.save_outlined
                            : Icons.add_circle_outline,
                      ),
                label: Text(widget.animal != null ? 'Güncelle' : 'Hayvan Ekle'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id =
          widget.animal?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _db.saveAnimal(
        Animal(
          id: id,
          ownerId: widget.ownerId,
          name: _nameCtrl.text.trim(),
          species: _species,
          breed: _breedCtrl.text.trim(),
          age: int.tryParse(_ageCtrl.text) ?? 0,
          weight: double.tryParse(_weightCtrl.text) ?? 0,
          matingDate: _mating,
          expectedBirth: _expectedBirth,
          notes: _notesCtrl.text.trim(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kaydedildi!'),
            backgroundColor: AppColors.userPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: c,
    keyboardType: type,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: validator,
  );

  Widget _dateTile(
    String label,
    IconData icon,
    DateTime? date,
    VoidCallback onTap, {
    String? subtitle,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.userPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null
                      ? DateFormat('dd MMMM yyyy', 'tr').format(date)
                      : 'Seçin',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: date != null
                        ? AppColors.textDark
                        : AppColors.textLight,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.userPrimary,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textLight,
            size: 18,
          ),
        ],
      ),
    ),
  );

  Widget _Section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}
