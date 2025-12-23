import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firestore_service.dart';

class FirestoreSubscriptionProvider with ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Map<String, dynamic>> _subscriptions = [];
  StreamSubscription? _subsSub;

  List<Map<String, dynamic>> get subscriptions => _subscriptions;

  void subscribeToUserSubscriptions(String uid) {
    _subsSub?.cancel();
    _subsSub = _service.subscriptionsForUserStream(uid).listen((snap) {
      _subscriptions = snap.docs.map((d) {
        final m = d.data() as Map<String, dynamic>;
        m['id'] = d.id;
        return m;
      }).toList();
      notifyListeners();
    });
  }

  Future<String> createSubscription(Map<String, dynamic> data) =>
      _service.createSubscription(data);

  @override
  void dispose() {
    _subsSub?.cancel();
    super.dispose();
  }
}
