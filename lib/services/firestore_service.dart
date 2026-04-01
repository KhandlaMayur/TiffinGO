import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<String> createOrder(Map<String, dynamic> orderData) async {
    // If caller provided an `id` field, use it as the document ID so
    // subsequent updates using that id (e.g., rating updates) will succeed.
    final providedId =
        (orderData['id'] is String && (orderData['id'] as String).isNotEmpty)
            ? orderData['id'] as String
            : null;

    if (providedId != null) {
      final docRef = _db.collection('orders').doc(providedId);
      await docRef.set({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return providedId;
    } else {
      final ref = await _db.collection('orders').add({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) =>
      _db.collection('orders').doc(orderId).update(updates);

  Stream<QuerySnapshot> ordersForUserStream(String uid) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createSubscription(Map<String, dynamic> data) async {
    final ref = await _db.collection('user_subscription').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot> subscriptionsForUserStream(String uid) {
    return _db
        .collection('user_subscription')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getMealPlansData() async {
    // retrieve the document and handle both formats:
    // 1. { data: { ... } }  (upload method used in code)
    // 2. { kathiyavadi: {...}, desi_rotalo: {...}, ... } (manually pasted)
    final doc = await _db.collection('mealPlans').doc('menus').get();
    if (!doc.exists) return null;
    final raw = doc.data();
    if (raw == null) return null;

    final combinedData = <String, dynamic>{};

    if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      combinedData.addAll(raw['data'] as Map<String, dynamic>);
    }

    // Add root level keys (which represent individual service IDs added by sellers)
    raw.forEach((key, value) {
      if (key != 'data') {
        combinedData[key] = value;
      }
    });

    return combinedData;
  }


}
