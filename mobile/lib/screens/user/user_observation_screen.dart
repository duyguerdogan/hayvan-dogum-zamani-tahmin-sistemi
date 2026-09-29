import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class UserObservationScreen extends StatefulWidget {
  final Animal animal;
  const UserObservationScreen({super.key, required this.animal});
  @override
  State<UserObservationScreen> createState() => _ObsState();
}

class _ObsState extends State<UserObservationScreen> {
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
    // ✅ Sıcaklık doğrulama
    final temp = double.tryParse(_tempCtrl.text);
    if (temp == null) {
      _msg('Geçerli bir sıcaklık değeri girin.', isError: true);
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
        ),
      );
      if (mounted) {
        // ✅ Başarı durumu göster
        setState(() {
          _saving = false;
          _saved = true;
        });
        _msg('Gözlem başarıyla kaydedildi!');
        // 1.5 saniye sonra geri dön
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _msg('Kayıt hatası: $e', isError: true);
      }
    }
  }

  void _msg(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.user(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('${widget.animal.name} — Gözlem'),
          backgroundColor: AppColors.userPrimary,
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
                  Column(
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
                        '${widget.animal.daysUntilBirth} gün kaldı',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // İştah
            _ObsSection('İştah', Icons.restaurant_outlined, [
              _choices(_appetite, {
                'iyi': ('İyi', '😊', AppColors.success),
                'normal': ('Normal', '😐', AppColors.userPrimary),
                'kötü': ('Kötü', '😟', AppColors.danger),
              }, (v) => setState(() => _appetite = v)),
            ]),
            const SizedBox(height: 12),

            // Hareketlilik
            _ObsSection('Hareketlilik', Icons.directions_walk_outlined, [
              _choices(_mobility, {
                'aktif': ('Aktif', '🏃', AppColors.success),
                'normal': ('Normal', '🚶', AppColors.userPrimary),
                'halsiz': ('Halsiz', '🛌', AppColors.warning),
                'hareketsiz': ('Hareketsiz', '⚠️', AppColors.danger),
              }, (v) => setState(() => _mobility = v)),
            ]),
            const SizedBox(height: 12),

            // Sıcaklık
            _ObsSection('Vücut Sıcaklığı', Icons.thermostat_outlined, [
              TextFormField(
                controller: _tempCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(suffixText: '°C'),
              ),
              const SizedBox(height: 6),
              const Text(
                'Normal aralık: 38.0 – 39.5°C',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ]),
            const SizedBox(height: 12),

            // Notlar
            _ObsSection('Notlar', Icons.notes_outlined, [
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Gözlemlerinizi yazın...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ✅ Kaydet butonu — saved durumunda yeşil onay göster
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
                            'Gözlem kaydedildi!',
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
                      label: Text(
                        _saving ? 'Kaydediliyor...' : 'Gözlemi Kaydet',
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _choices(
    String selected,
    Map<String, (String, String, Color)> opts,
    void Function(String) onSel,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: opts.entries.map((e) {
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

  Widget _ObsSection(String title, IconData icon, List<Widget> children) =>
      Container(
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
                Icon(icon, size: 18, color: AppColors.userPrimary),
                const SizedBox(width: 6),
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
