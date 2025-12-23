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
    final ref = await _db.collection('subscriptions').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot> subscriptionsForUserStream(String uid) {
    return _db
        .collection('subscriptions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
