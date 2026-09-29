import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class VetObservationScreen extends StatefulWidget {
  final Animal animal;
  final String vetId;
  const VetObservationScreen({
    super.key,
    required this.animal,
    required this.vetId,
  });
  @override
  State<VetObservationScreen> createState() => _VetObsState();
}

class _VetObsState extends State<VetObservationScreen> {
  final _tempCtrl = TextEditingController(text: '38.5');
  final _notesCtrl = TextEditingController();
  String _appetite = 'normal';
  String _mobility = 'normal';
  bool _saving = false;
  bool _saved = false;
  final _db = FirestoreService();

  @override
  void dispose() {
    _tempCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final temp = double.tryParse(_tempCtrl.text);
    if (temp == null) {
      _msg('Geçerli bir sıcaklık girin.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _db.addObservation(
        Observation(
          id: '',
          animalId: widget.animal.id,
          date: DateTime.now(),
          appetite: _appetite,
          mobility: _mobility,
          temperature: temp,
          notes: _notesCtrl.text.trim(),
          recordedBy: widget.vetId,
        ),
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = true;
        });
        _msg('Klinik gözlem kaydedildi!');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _msg('Hata: $e', isError: true);
      }
    }
  }

  void _msg(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.vet(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.vetPrimary,
          title: Text('${widget.animal.name} — Klinik Gözlem'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hayvan özeti
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    speciesEmoji(widget.animal.species),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.animal.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${kSpeciesTR[widget.animal.species]} · '
                          '${widget.animal.breed} · '
                          '${widget.animal.daysUntilBirth} gün kaldı',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.vetLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Veteriner Kaydı',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.vetPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // İştah
            _Sec('İştah', Icons.restaurant_outlined, [
              _Choices(_appetite, {
                'iyi': ('İyi', '😊', AppColors.success),
                'normal': ('Normal', '😐', AppColors.vetPrimary),
                'kötü': ('Kötü', '😟', AppColors.danger),
              }, (v) => setState(() => _appetite = v)),
            ]),
            const SizedBox(height: 12),

            // Hareketlilik
            _Sec('Hareketlilik', Icons.directions_walk_outlined, [
              _Choices(_mobility, {
                'aktif': ('Aktif', '🏃', AppColors.success),
                'normal': ('Normal', '🚶', AppColors.vetPrimary),
                'halsiz': ('Halsiz', '🛌', AppColors.warning),
                'hareketsiz': ('Hareketsiz', '⚠️', AppColors.danger),
              }, (v) => setState(() => _mobility = v)),
            ]),
            const SizedBox(height: 12),

            // Sıcaklık
            _Sec('Vücut Sıcaklığı', Icons.thermostat_outlined, [
              TextFormField(
                controller: _tempCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(suffixText: '°C'),
              ),
              const SizedBox(height: 6),
              Text(
                _normalRange(widget.animal.species),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Klinik notlar
            _Sec('Klinik Notlar', Icons.notes_outlined, [
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Klinik bulgular, verilen ilaçlar, '
                      'yapılan müdahaleler...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _saved
                  ? Container(
                      key: const ValueKey('saved'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Klinik gözlem kaydedildi!',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vetPrimary,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Kaydediliyor...' : 'Klinik Gözlemi Kaydet',
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _normalRange(String sp) {
    const r = {
      'Cattle': 'Sığır normal: 38.0–39.0°C',
      'Sheep': 'Koyun normal: 38.5–39.5°C',
      'Goat': 'Keçi normal: 38.5–39.5°C',
      'Horse': 'At normal: 37.5–38.5°C',
      'Pig': 'Domuz normal: 38.0–39.0°C',
      'Dog': 'Köpek normal: 37.5–39.2°C',
      'Cat': 'Kedi normal: 38.0–39.2°C',
    };
    return r[sp] ?? 'Normal: 38.0–39.5°C';
  }
}

class _Sec extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Sec(this.title, this.icon, this.children);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.vetPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Choices extends StatelessWidget {
  final String selected;
  final Map<String, (String, String, Color)> options;
  final void Function(String) onSel;
  const _Choices(this.selected, this.options, this.onSel);

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options.entries.map((e) {
      final (label, emoji, color) = e.value;
      final sel = selected == e.key;
      return InkWell(
        onTap: () => onSel(e.key),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? color : Colors.grey.shade300,
              width: sel ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  color: sel ? color : AppColors.textMid,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
