import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static Future<bool> checkHealth() async {
    try {
      final r = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> predict({
    required Animal animal,
    required double bodyTemp,
    required int heartRate,
    required int respRate,
    required double calcium,
    required double progesterone,
    required String appetite,
    required String mobility,
  }) async {
    final dbb = animal.daysUntilBirth.clamp(0, 30);

    final udderScore = dbb <= 2
        ? 5
        : dbb <= 5
        ? 4
        : dbb <= 10
        ? 3
        : 2;
    final vulvaScore = dbb <= 1
        ? 5
        : dbb <= 3
        ? 4
        : dbb <= 7
        ? 3
        : 1;
    final restlessScore = dbb <= 1
        ? 5
        : dbb <= 3
        ? 4
        : dbb <= 7
        ? 3
        : 1;
    final activityScore = mobility == 'hareketsiz'
        ? 1
        : mobility == 'halsiz'
        ? 2
        : mobility == 'normal'
        ? 3
        : 5;
    final tempDrop = dbb <= 2
        ? 1.2
        : dbb <= 5
        ? 0.6
        : 0.1;
    final appetiteScore = appetite == 'kötü'
        ? -40
        : appetite == 'normal'
        ? -10
        : 0;
    final feedIntake = (animal.weight * 0.025).clamp(0.5, 50.0);
    final waterIntake = (animal.weight * 0.08).clamp(1.0, 80.0);

    // Tam olarak 30 field — API şemasıyla birebir
    final body = <String, dynamic>{
      'species': animal.species,
      'age_years': animal.age,
      'parity': 1,
      'gestation_days': Animal.gestationDays(animal.species),
      'days_before_birth': dbb,
      'body_temp_celsius': bodyTemp,
      'temp_change_celsius': -tempDrop,
      'udder_development_score': udderScore,
      'udder_edema_present': dbb <= 2 ? 1 : 0,
      'teat_enlargement_score': (udderScore - 1).clamp(0, 5),
      'milk_secretion_present': dbb <= 2 ? 1 : 0,
      'vulva_swelling_score': vulvaScore,
      'vulva_discharge_present': dbb <= 1 ? 1 : 0,
      'pelvic_relaxation_score': (vulvaScore - 1).clamp(0, 5),
      'appetite_change_percent': appetiteScore,
      'feed_intake_kg': feedIntake,
      'water_intake_liters': waterIntake,
      'activity_level_score': activityScore,
      'restlessness_score': restlessScore,
      'nesting_behavior_present': dbb <= 1 ? 1 : 0,
      'isolation_behavior_present': dbb <= 1 ? 1 : 0,
      'aggression_score': dbb <= 2 ? 3 : 1,
      'lying_frequency_per_hour': dbb <= 2 ? 8 : 4,
      'standing_frequency_per_hour': dbb <= 2 ? 7 : 3,
      'respiration_rate_per_min': respRate,
      'heart_rate_bpm': heartRate,
      'calcium_level_mmol_l': calcium,
      'progesterone_ng_ml': progesterone,
      'labor_stage': dbb == 0 ? 2 : 1,
      'risk_factors': _calcRisk(animal, calcium, progesterone, heartRate),
    };

    assert(body.length == 30, 'HATA: ${body.length} field var, 30 olmalı');

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        data['risk_factors_list'] = _buildRiskList(
          animal,
          calcium,
          progesterone,
          heartRate,
          bodyTemp,
          dbb,
        );
        data['explanation'] = _buildVetExplanation(data, dbb);
        data['simple_explanation'] = _buildUserExplanation(data, dbb);
        data['input_features'] = body;
        return data;
      } else {
        String detail = 'API hatası: ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          if (err is Map && err['detail'] != null) {
            detail = err['detail'].toString();
          }
        } catch (_) {}
        throw Exception(detail);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static int _calcRisk(Animal a, double ca, double prog, int hr) {
    int r = 0;
    if (a.age < 2 || a.age > 8) r++;
    if (ca < _caThreshold(a.species)) r++;
    if (prog > 5.0) r++;
    if (hr > _hrThreshold(a.species)) r++;
    return r;
  }

  static double _caThreshold(String sp) {
    const t = {
      'Cattle': 8.0,
      'Sheep': 1.5,
      'Goat': 1.8,
      'Horse': 9.0,
      'Pig': 1.3,
      'Dog': 1.8,
      'Cat': 1.8,
    };
    return t[sp] ?? 8.0;
  }

  static int _hrThreshold(String sp) {
    const t = {
      'Cattle': 95,
      'Sheep': 120,
      'Goat': 140,
      'Horse': 55,
      'Pig': 110,
      'Dog': 110,
      'Cat': 160,
    };
    return t[sp] ?? 100;
  }

  static List<String> _buildRiskList(
    Animal a,
    double ca,
    double prog,
    int hr,
    double temp,
    int dbb,
  ) {
    final risks = <String>[];
    if (a.age < 2) risks.add('Genç hayvan — ilk doğum riski yüksek');
    if (a.age > 8) risks.add('İleri yaş — komplikasyon riski artmış');
    if (ca < _caThreshold(a.species))
      risks.add('Düşük kalsiyum (hipokalsemi riski)');
    if (prog > 5.0) risks.add('Yüksek progesteron — doğum gecikmesi olabilir');
    if (prog < 1.5) risks.add('Düşük progesteron — doğum başlamış olabilir');
    if (hr > _hrThreshold(a.species))
      risks.add('Yüksek kalp atış hızı — stres belirtisi');
    if (temp > 39.5) risks.add('Ateş — enfeksiyon riski var');
    if (temp < 37.5) risks.add('Düşük vücut ısısı — doğum başlıyor olabilir');
    if (dbb == 0) risks.add('Doğum vakti geldi');
    if (dbb <= 1) risks.add('24 saat içinde doğum bekleniyor');
    if (risks.isEmpty) risks.add('Belirgin risk faktörü tespit edilmedi');
    return risks;
  }

  static String _buildVetExplanation(Map<String, dynamic> data, int dbb) {
    final pct = data['successful_birth_percent'] ?? 0;
    final urgency = data['urgency'] ?? '';
    final models = data['model_probabilities'] as Map? ?? {};
    final buf = StringBuffer();
    buf.writeln('▸ Başarılı doğum olasılığı: %$pct');
    buf.writeln('▸ Öncelik: $urgency');
    buf.writeln('▸ Doğuma kalan: $dbb gün');
    if (models.isNotEmpty) {
      buf.writeln('\nEnsemble Model Sonuçları:');
      models.forEach((k, v) => buf.writeln('  • $k → %$v'));
    }
    buf.writeln('');
    if (dbb <= 1) {
      buf.writeln('⚠️ Anlık müdahale gerekebilir.');
      buf.writeln('Doğum kanalı kontrolü önerilir.');
    } else if (dbb <= 3) {
      buf.writeln('Yakın takip: 12 saatte bir kontrol önerilir.');
    } else {
      buf.writeln('Rutin takip yeterli.');
    }
    return buf.toString();
  }

  static String _buildUserExplanation(Map<String, dynamic> data, int dbb) {
    final urgency = data['urgency'] ?? 'NORMAL';
    final pct = (data['successful_birth_percent'] ?? 0).toDouble();
    if (urgency == 'KRİTİK' || urgency == 'ACİL') {
      return 'Hayvanınız doğum yapıyor veya çok yakında yapacak! '
          'Hemen veterinerinizi arayın ve hayvanı sakin bir ortamda tutun.';
    } else if (urgency == 'YÜKSEK') {
      return 'Doğum yaklaşıyor. Hayvanı sık sık kontrol edin, '
          'su ve yem erişimini sağlayın. Veterinerinizi bilgilendirin.';
    } else if (pct >= 80) {
      return 'Her şey normal görünüyor. '
          'Günlük takibinizi sürdürün ve veterinerinizle iletişimde kalın.';
    } else {
      return 'Bazı parametreler dikkat gerektiriyor. '
          'Veterinerinize danışmanızı öneririz.';
    }
  }
}
