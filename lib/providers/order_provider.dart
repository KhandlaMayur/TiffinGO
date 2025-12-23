import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _orderHistory = [];
  List<String> _favoriteServices = [];
  OrderModel? _currentOrder;
  Map<String, dynamic>? _deliveryLocation;

  List<OrderModel> get orderHistory => _orderHistory;
  List<String> get favoriteServices => _favoriteServices;
  OrderModel? get currentOrder => _currentOrder;
  Map<String, dynamic>? get deliveryLocation => _deliveryLocation;

  void addToOrderHistory(OrderModel order) {
    _orderHistory.add(order);
    _currentOrder = order;
    _saveOrderHistory();
    notifyListeners();
  }

  void updateDeliveryLocation(Map<String, dynamic> location) {
    _deliveryLocation = location;
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String status) {
    final index = _orderHistory.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final order = _orderHistory[index];
      _orderHistory[index] = OrderModel(
        id: order.id,
        serviceName: order.serviceName,
        date: order.date,
        amount: order.amount,
        status: status,
        paymentMethod: order.paymentMethod,
        mealType: order.mealType,
        mealPlan: order.mealPlan,
        subscription: order.subscription,
        extraFood: order.extraFood,
        location: order.location,
        paymentCompleted: order.paymentCompleted,
      );
      _saveOrderHistory();
      notifyListeners();
    }
  }

  void updateOrder(OrderModel updatedOrder) {
    final index =
        _orderHistory.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _orderHistory[index] = updatedOrder;
    } else {
      // If order wasn't previously saved (edge-case), add it so rating isn't lost
      _orderHistory.add(updatedOrder);
    }
    _saveOrderHistory();
    notifyListeners();
  }

  void addToFavorites(String serviceName) {
    if (!_favoriteServices.contains(serviceName)) {
      _favoriteServices.add(serviceName);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFromFavorites(String serviceName) {
    _favoriteServices.remove(serviceName);
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String serviceName) {
    return _favoriteServices.contains(serviceName);
  }

  Future<void> _saveOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson =
        _orderHistory.map((order) => jsonEncode(order.toJson())).toList();
    await prefs.setStringList('order_history', ordersJson);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_services', _favoriteServices);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load order history
    final ordersList = prefs.getStringList('order_history');
    if (ordersList != null && ordersList.isNotEmpty) {
      _orderHistory = ordersList.map((orderString) {
        try {
          return OrderModel.fromJson(jsonDecode(orderString));
        } catch (e) {
          return OrderModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            serviceName: 'Sample Order',
            date: DateTime.now().toString().split(' ')[0],
            amount: 100.0,
            status: 'Delivered',
            paymentMethod: 'Cash on Delivery',
            mealType: 'veg',
            mealPlan: 'Normal Tiffine',
            subscription: 'Daily',
            extraFood: [],
            paymentCompleted: true,
          );
        }
      }).toList();
    }

    // Load favorites
    final favoritesList = prefs.getStringList('favorite_services');
    if (favoritesList != null) {
      _favoriteServices = favoritesList;
    }

    notifyListeners();
  }
}
