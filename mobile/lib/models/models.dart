import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Kullanıcı rolleri ────────────────────────────────────────────────────────
enum UserRole { user, vet }

// ─── Uygulama Kullanıcısı ─────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final UserRole role;
  final String? clinicName;
  final String? licenseNo;
  final String? specialty;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.role,
    this.clinicName,
    this.licenseNo,
    this.specialty,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> m) => AppUser(
        id: id,
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        address: m['address'] ?? '',
        email: m['email'] ?? '',
        role: m['role'] == 'vet' ? UserRole.vet : UserRole.user,
        clinicName: m['clinic_name'],
        licenseNo: m['license_no'],
        specialty: m['specialty'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'address': address,
        'email': email,
        'role': role == UserRole.vet ? 'vet' : 'user',
        if (clinicName != null) 'clinic_name': clinicName,
        if (licenseNo != null) 'license_no': licenseNo,
        if (specialty != null) 'specialty': specialty,
      };

  bool get isVet => role == UserRole.vet;
}

// ─── Hayvan ──────────────────────────────────────────────────────────────────
class Animal {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final int age;
  final double weight;
  final DateTime? matingDate;
  final DateTime? expectedBirth;
  final String notes;
  final String? assignedVetId;

  Animal({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.weight,
    this.matingDate,
    this.expectedBirth,
    this.notes = '',
    this.assignedVetId,
  });

  factory Animal.fromMap(String id, Map<String, dynamic> m) => Animal(
        id: id,
        ownerId: m['owner_id'] ?? '',
        name: m['name'] ?? '',
        species: m['species'] ?? '',
        breed: m['breed'] ?? '',
        age: (m['age'] ?? 0) is int
            ? m['age']
            : int.tryParse(m['age'].toString()) ?? 0,
        weight: (m['weight'] ?? 0).toDouble(),
        matingDate: (m['mating_date'] as Timestamp?)?.toDate(),
        expectedBirth: (m['expected_birth'] as Timestamp?)?.toDate(),
        notes: m['notes'] ?? '',
        assignedVetId: m['assigned_vet_id'],
      );

  Map<String, dynamic> toMap() => {
        'owner_id': ownerId,
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'weight': weight,
        'mating_date':
            matingDate != null ? Timestamp.fromDate(matingDate!) : null,
        'expected_birth':
            expectedBirth != null ? Timestamp.fromDate(expectedBirth!) : null,
        'notes': notes,
        if (assignedVetId != null) 'assigned_vet_id': assignedVetId,
      };

  int get daysUntilBirth {
    if (expectedBirth == null) return 999;
    return expectedBirth!.difference(DateTime.now()).inDays;
  }

  String get urgencyLabel {
    final d = daysUntilBirth;
    if (d <= 0) return 'KRİTİK';
    if (d <= 1) return 'ACİL';
    if (d <= 3) return 'YÜKSEK';
    return 'NORMAL';
  }

  static int gestationDays(String species) {
    const map = {
      'Cattle': 283,
      'Sheep': 148,
      'Goat': 150,
      'Horse': 340,
      'Pig': 115,
      'Dog': 63,
      'Cat': 65,
    };
    return map[species] ?? 280;
  }

  static DateTime? calcExpectedBirth(String species, DateTime mating) =>
      mating.add(Duration(days: gestationDays(species)));
}

// ─── Gözlem ──────────────────────────────────────────────────────────────────
class Observation {
  final String id;
  final String animalId;
  final DateTime date;
  final String appetite;
  final String mobility;
  final double temperature;
  final String notes;
  final String? recordedBy;

  Observation({
    required this.id,
    required this.animalId,
    required this.date,
    required this.appetite,
    required this.mobility,
    required this.temperature,
    this.notes = '',
    this.recordedBy,
  });

  factory Observation.fromMap(String id, Map<String, dynamic> m) => Observation(
        id: id,
        animalId: m['animal_id'] ?? '',
        date: (m['date'] as Timestamp).toDate(),
        appetite: m['appetite'] ?? 'normal',
        mobility: m['mobility'] ?? 'normal',
        temperature: (m['temperature'] ?? 38.5).toDouble(),
        notes: m['notes'] ?? '',
        recordedBy: m['recorded_by'],
      );

  Map<String, dynamic> toMap() => {
        'animal_id': animalId,
        'date': Timestamp.fromDate(date),
        'appetite': appetite,
        'mobility': mobility,
        'temperature': temperature,
        'notes': notes,
        if (recordedBy != null) 'recorded_by': recordedBy,
      };
}

// ─── Tahmin ──────────────────────────────────────────────────────────────────
class Prediction {
  final String id;
  final String animalId;
  final DateTime date;
  final double probability;
  final String urgency;
  final String prediction;
  final Map<String, dynamic> modelProbabilities;
  final Map<String, dynamic> inputFeatures;
  final List<String> riskFactors;
  final String explanation;

  Prediction({
    required this.id,
    required this.animalId,
    required this.date,
    required this.probability,
    required this.urgency,
    required this.prediction,
    required this.modelProbabilities,
    required this.inputFeatures,
    required this.riskFactors,
    required this.explanation,
  });

  factory Prediction.fromMap(String id, Map<String, dynamic> m) => Prediction(
        id: id,
        animalId: m['animal_id'] ?? '',
        date: (m['date'] as Timestamp).toDate(),
        probability: (m['probability'] ?? 0).toDouble(),
        urgency: m['urgency'] ?? '',
        prediction: m['prediction'] ?? '',
        modelProbabilities:
            Map<String, dynamic>.from(m['model_probabilities'] ?? {}),
        inputFeatures: Map<String, dynamic>.from(m['input_features'] ?? {}),
        riskFactors: List<String>.from(m['risk_factors'] ?? []),
        explanation: m['explanation'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'animal_id': animalId,
        'date': Timestamp.fromDate(date),
        'probability': probability,
        'urgency': urgency,
        'prediction': prediction,
        'model_probabilities': modelProbabilities,
        'input_features': inputFeatures,
        'risk_factors': riskFactors,
        'explanation': explanation,
      };
}

// ─── Sabitler ─────────────────────────────────────────────────────────────────
const List<String> kSpecies = [
  'Cattle', 'Sheep', 'Goat', 'Horse', 'Pig', 'Dog', 'Cat'
];

const Map<String, String> kSpeciesTR = {
  'Cattle': 'Sığır',
  'Sheep': 'Koyun',
  'Goat': 'Keçi',
  'Horse': 'At',
  'Pig': 'Domuz',
  'Dog': 'Köpek',
  'Cat': 'Kedi',
};

String speciesEmoji(String sp) {
  const m = {
    'Cattle': '🐄',
    'Sheep': '🐑',
    'Goat': '🐐',
    'Horse': '🐴',
    'Pig': '🐷',
    'Dog': '🐕',
    'Cat': '🐈'
  };
  return m[sp] ?? '🐾';
}
