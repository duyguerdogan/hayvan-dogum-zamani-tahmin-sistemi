import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ─── Kullanıcı ─────────────────────────────────────────────────────────────
  Future<void> saveUser(AppUser user) =>
      _db.collection('users').doc(user.id).set(user.toMap());

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  // Hayvan sahibinin adı (veteriner kartları için)
  final Map<String, String> _nameCache = {};

  Future<String> getCachedUserName(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final name = doc.exists
          ? (doc.data()?['name'] ?? 'Bilinmiyor')
          : 'Bilinmiyor';
      _nameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Bilinmiyor';
    }
  }

  // ─── Hayvan ────────────────────────────────────────────────────────────────
  Future<void> saveAnimal(Animal animal) =>
      _db.collection('animals').doc(animal.id).set(animal.toMap());

  Future<void> deleteAnimal(String id) =>
      _db.collection('animals').doc(id).delete();

  Future<Animal?> getAnimal(String id) async {
    final doc = await _db.collection('animals').doc(id).get();
    if (!doc.exists) return null;
    return Animal.fromMap(doc.id, doc.data()!);
  }

  // owner_id filtresi
  Stream<List<Animal>> animalsStream(String ownerId) {
    return _db
        .collection('animals')
        .where('owner_id', isEqualTo: ownerId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Animal.fromMap(d.id, d.data()))
              .toList();
          // Dart tarafında sırala — Firestore index gerektirmez
          list.sort((a, b) => a.daysUntilBirth.compareTo(b.daysUntilBirth));
          return list;
        });
  }

  // Veteriner için — tüm hayvanlar
  Stream<List<Animal>> allAnimalsStream() {
    return _db.collection('animals').snapshots().map((s) {
      final list = s.docs.map((d) => Animal.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.daysUntilBirth.compareTo(b.daysUntilBirth));
      return list;
    });
  }

  // ─── Gözlem ────────────────────────────────────────────────────────────────

  Future<void> addObservation(Observation obs) =>
      _db.collection('observations').add(obs.toMap());

  Stream<List<Observation>> observationsStream(String animalId) {
    return _db
        .collection('observations')
        .where('animal_id', isEqualTo: animalId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Observation.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  // ─── Tahmin ────────────────────────────────────────────────────────────────

  Future<void> savePrediction(Prediction pred) =>
      _db.collection('predictions').add(pred.toMap());

  Stream<List<Prediction>> predictionsStream(String animalId) {
    return _db
        .collection('predictions')
        .where('animal_id', isEqualTo: animalId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Prediction.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list.take(10).toList();
        });
  }

  // Veteriner listesi
  Future<List<AppUser>> getVets() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'vet')
        .get();
    return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
  }
}
