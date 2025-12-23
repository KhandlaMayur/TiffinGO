import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  final List<SubscriptionModel> _subscriptionHistory = [];

  List<SubscriptionModel> get subscriptionHistory =>
      List.unmodifiable(_subscriptionHistory);

  bool get hasActiveSubscription =>
      _subscriptionHistory.any((s) => s.isActive && s.isValid);

  SubscriptionModel? get activeSubscription {
    try {
      return _subscriptionHistory.firstWhere((s) => s.isActive && s.isValid);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionsList = prefs.getStringList('subscriptions');
      if (subscriptionsList != null && subscriptionsList.isNotEmpty) {
        _subscriptionHistory.clear();
        _subscriptionHistory.addAll(
          subscriptionsList.map((subString) {
            try {
              return SubscriptionModel.fromJson(jsonDecode(subString));
            } catch (e) {
              return null;
            }
          }).whereType<SubscriptionModel>(),
        );
      }
    } catch (e) {
      // Handle errors gracefully, maybe log them
    }
    notifyListeners();
  }

  Future<void> addSubscription(SubscriptionModel subscription) async {
    _subscriptionHistory.add(subscription);
    await _saveSubscriptions();
    // Persist to Firestore under collection 'user_subscription' with doc id = subscription.id
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('user_subscription')
          .doc(subscription.id)
          .set(subscription.toJson());
    } catch (e) {
      // ignore Firestore errors for now
    }
    notifyListeners();
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    final index =
        _subscriptionHistory.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      _subscriptionHistory[index] = subscription;
      await _saveSubscriptions();
      notifyListeners();
    }
  }

  Future<void> decrementRemainingOrders(String subscriptionId) async {
    final index =
        _subscriptionHistory.indexWhere((sub) => sub.id == subscriptionId);
    if (index != -1) {
      final subscription = _subscriptionHistory[index];
      final newRemaining = (subscription.remainingOrders - 1)
          .clamp(0, subscription.remainingOrders);
      final updated = SubscriptionModel(
        id: subscription.id,
        userId: subscription.userId,
        subscriptionType: subscription.subscriptionType,
        category: subscription.category,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        amount: subscription.amount,
        isActive: subscription.isActive,
        paymentMethod: subscription.paymentMethod,
        paymentCompleted: subscription.paymentCompleted,
        quantityPerDay: subscription.quantityPerDay,
        mealPeriods: subscription.mealPeriods,
        extraOrders: subscription.extraOrders,
        remainingOrders: newRemaining,
        pendingAmount: subscription.pendingAmount,
        autoRenew: subscription.autoRenew,
        pauseStart: subscription.pauseStart,
        pauseEnd: subscription.pauseEnd,
        tiffineService: subscription.tiffineService,
        mealType: subscription.mealType,
        uniqueCode: subscription.uniqueCode,
      );
      await updateSubscription(updated);
      // Update Firestore doc for this subscription
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('user_subscription')
            .doc(subscriptionId)
            .update({
          'remainingOrders': newRemaining,
          'isActive': newRemaining == 0 ? false : subscription.isActive,
        });
      } catch (e) {
        // ignore
      }

      // If remaining orders = 0, auto-cancel locally (and update Firestore in cancel)
      if (newRemaining == 0) {
        await cancelSubscription(subscriptionId);
      }
    }
  }

  Future<bool> decrementIfSubscriptionOrder(String userId, String mealType,
      String category, String tiffineService) async {
    // Find active subscription matching this order
    try {
      final matching = _subscriptionHistory.firstWhere(
        (s) =>
            s.isActive &&
            s.isValid &&
            s.userId == userId &&
            s.mealType == mealType &&
            s.category == category &&
            s.tiffineService == tiffineService &&
            s.remainingOrders > 0,
      );
      // Decrement this subscription's remaining orders
      await decrementRemainingOrders(matching.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    final index =
        _subscriptionHistory.indexWhere((sub) => sub.id == subscriptionId);
    if (index != -1) {
      final subscription = _subscriptionHistory[index];
      _subscriptionHistory[index] = SubscriptionModel(
        id: subscription.id,
        userId: subscription.userId,
        subscriptionType: subscription.subscriptionType,
        category: subscription.category,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        amount: subscription.amount,
        isActive: false,
        paymentMethod: subscription.paymentMethod,
        paymentCompleted: subscription.paymentCompleted,
        quantityPerDay: subscription.quantityPerDay,
        mealPeriods: subscription.mealPeriods,
        extraOrders: subscription.extraOrders,
        autoRenew: subscription.autoRenew,
        pauseStart: subscription.pauseStart,
        pauseEnd: subscription.pauseEnd,
        tiffineService: subscription.tiffineService,
        mealType: subscription.mealType,
        uniqueCode: subscription.uniqueCode,
        remainingOrders: subscription.remainingOrders,
        pendingAmount: subscription.pendingAmount,
      );
      await _saveSubscriptions();
      // Update Firestore to mark inactive
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('user_subscription')
            .doc(subscriptionId)
            .update({
          'isActive': false,
        });
      } catch (e) {
        // ignore
      }
      notifyListeners();
    }
  }

  Future<void> _saveSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionsJson =
          _subscriptionHistory.map((sub) => jsonEncode(sub.toJson())).toList();
      await prefs.setStringList('subscriptions', subscriptionsJson);
    } catch (e) {
      // Handle errors gracefully, maybe log them
    }
  }

  void clear() {
    _subscriptionHistory.clear();
    notifyListeners();
  }
}
