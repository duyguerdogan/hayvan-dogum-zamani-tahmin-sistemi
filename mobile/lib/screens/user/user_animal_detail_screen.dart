import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'user_observation_screen.dart';

class UserAnimalDetailScreen extends StatelessWidget {
  final Animal animal;
  const UserAnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final color = AppColors.urgency(animal.urgencyLabel);
    final days = animal.daysUntilBirth;

    return Theme(
      data: AppTheme.user(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.userPrimary,
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
                      colors: [AppColors.userPrimary, AppColors.userSecondary],
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
                          style: const TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 8),
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
                  // Doğum uyarı banner
                  if (days <= 7)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            days <= 0 ? Icons.warning_rounded : Icons.schedule,
                            color: color,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  days <= 0
                                      ? 'Doğum zamanı geldi!'
                                      : days == 1
                                      ? 'Yarın doğum bekleniyor'
                                      : '$days gün kaldı',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                if (animal.expectedBirth != null)
                                  Text(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                      'tr',
                                    ).format(animal.expectedBirth!),
                                    style: TextStyle(
                                      color: color.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (days <= 7) const SizedBox(height: 14),

                  // Temel bilgiler
                  AppCard(
                    child: Column(
                      children: [
                        _Row(
                          'Tür',
                          kSpeciesTR[animal.species] ?? animal.species,
                        ),
                        _Row('Irk', animal.breed.isEmpty ? '—' : animal.breed),
                        _Row('Yaş', '${animal.age} yaş'),
                        _Row('Kilo', '${animal.weight} kg'),
                        if (animal.expectedBirth != null)
                          _Row(
                            'Tahmini Doğum',
                            DateFormat(
                              'dd MMMM yyyy',
                              'tr',
                            ).format(animal.expectedBirth!),
                          ),
                        if (animal.notes.isNotEmpty)
                          _Row('Notlar', animal.notes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Aksiyon butonları
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.userPrimary,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Gözlem Ekle'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserObservationScreen(animal: animal),
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
                          label: const Text('Tahmin'),
                          // ✅ DÜZELTME: Bottom sheet açıyor
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) =>
                                _UserPredictionSheet(animal: animal, db: db),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Son tahmin
                  const SectionTitle('Son Tahmin', Icons.insights),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Prediction>>(
                    stream: db.predictionsStream(animal.id),
                    builder: (ctx, snap) {
                      final preds = snap.data ?? [];
                      if (preds.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.psychology_outlined,
                                  color: AppColors.textLight,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Henüz tahmin yapılmadı',
                                  style: TextStyle(color: AppColors.textLight),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (_) => _UserPredictionSheet(
                                      animal: animal,
                                      db: db,
                                    ),
                                  ),
                                  child: const Text('Şimdi Tahmin Yap'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return _UserPredCard(pred: preds.first);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Son gözlemler
                  const SectionTitle(
                    'Son Gözlemler',
                    Icons.visibility_outlined,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Observation>>(
                    stream: db.observationsStream(animal.id),
                    builder: (ctx, snap) {
                      final obs = (snap.data ?? []).take(3).toList();
                      if (obs.isEmpty) {
                        return const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Henüz gözlem girilmedi',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: obs.map((o) => _ObsTile(obs: o)).toList(),
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

// ─── Kullanıcı Tahmin Bottom Sheet ───────────────────────────────────────────
class _UserPredictionSheet extends StatefulWidget {
  final Animal animal;
  final FirestoreService db;
  const _UserPredictionSheet({required this.animal, required this.db});

  @override
  State<_UserPredictionSheet> createState() => _UserPredictionSheetState();
}

class _UserPredictionSheetState extends State<_UserPredictionSheet> {
  final _tempCtrl = TextEditingController();
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
    // Türe göre varsayılan değerler
    _setDefaults(widget.animal.species);
  }

  void _setDefaults(String sp) {
    _tempCtrl.text = '38.5';
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
    for (final c in [_tempCtrl, _hrCtrl, _rrCtrl, _caCtrl, _progCtrl]) {
      c.dispose();
    }
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
      setState(() => _error = 'Lütfen tüm değerleri doğru girin.');
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

      // Firestore'a kaydet
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
          explanation: data['simple_explanation'] ?? '',
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
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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
                Text(
                  'Doğum Tahmini',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${speciesEmoji(widget.animal.species)} '
                  '${widget.animal.name} · '
                  '${kSpeciesTR[widget.animal.species]} · '
                  '${widget.animal.daysUntilBirth} gün kaldı',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
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
                    Expanded(child: _f(_caCtrl, 'Kalsiyum')),
                  ],
                ),
                const SizedBox(height: 10),
                _f(_progCtrl, 'Progesteron ng/mL'),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.userPrimary,
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

                // Hata
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

                // Sonuç
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _ResultCard(result: _result!),
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

// ─── Kullanıcı sonuç kartı (sade) ────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = (result['successful_birth_percent'] ?? 0).toDouble();
    final urgency = result['urgency'] ?? '';
    final color = AppColors.urgency(urgency);
    final simpleEx = result['simple_explanation'] ?? '';
    final risks = List<String>.from(result['risk_factors_list'] ?? []);

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
                    Text(
                      '%${pct.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
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

          if (simpleEx.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.userLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                simpleEx,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMid,
                  height: 1.5,
                ),
              ),
            ),
          ],

          if (risks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Dikkat Edilmesi Gerekenler:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...risks.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 5, color: AppColors.warning),
                    const SizedBox(width: 8),
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

// ─── Yardımcı widget'lar ──────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 120,
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

class _ObsTile extends StatelessWidget {
  final Observation obs;
  const _ObsTile({required this.obs});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.userLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: AppColors.userPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy', 'tr').format(obs.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${obs.temperature}°C · İştah: ${obs.appetite}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                if (obs.notes.isNotEmpty)
                  Text(
                    obs.notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMid,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _UserPredCard extends StatelessWidget {
  final Prediction pred;
  const _UserPredCard({required this.pred});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.urgency(pred.urgency);
    final pct = (pred.probability * 100).toStringAsFixed(0);
    return AppCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pred.probability,
                      strokeWidth: 7,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Text(
                      '%$pct',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(label: pred.urgency, color: color),
                    const SizedBox(height: 6),
                    Text(
                      pred.prediction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pred.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.userLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pred.explanation,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMid,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (pred.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...pred.riskFactors
                .take(3)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 5,
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
