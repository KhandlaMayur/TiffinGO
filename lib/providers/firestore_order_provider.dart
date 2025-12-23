import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firestore_service.dart';

class FirestoreOrderProvider with ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  StreamSubscription? _ordersSub;

  void subscribeToUserOrders(String uid) {
    _ordersSub?.cancel();
    _ordersSub = _service.ordersForUserStream(uid).listen((snap) {
      _orders = snap.docs.map((d) {
        final m = d.data() as Map<String, dynamic>;
        m['id'] = d.id;
        return m;
      }).toList();
      notifyListeners();
    });
  }

  Future<String> createOrder(Map<String, dynamic> data) =>
      _service.createOrder(data);

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) =>
      _service.updateOrder(orderId, updates);

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}
