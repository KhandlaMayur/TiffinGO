class SubscriptionModel {
  final String id;
  final String userId;
  final String subscriptionType; // 'daily', 'weekly', 'monthly'
  final String category; // 'normal', 'premium', 'deluxe', 'gym/diet', 'combo'
  final String? tiffineService; // 'kathiyavadi', 'rajwadi', etc.
  final String? mealType; // 'veg', 'jain'
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final bool isActive;
  final String paymentMethod;
  final bool paymentCompleted;
  // Optional additional details
  final int quantityPerDay;
  final List<String> mealPeriods;
  final int extraOrders;
  final int remainingOrders;
  final double pendingAmount;
  final bool autoRenew;
  final DateTime? pauseStart;
  final DateTime? pauseEnd;
  final String? uniqueCode; // Unique code generated for this subscription

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.subscriptionType,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.isActive,
    required this.paymentMethod,
    required this.paymentCompleted,
    this.quantityPerDay = 1,
    this.mealPeriods = const [],
    this.extraOrders = 0,
    this.autoRenew = true,
    this.pauseStart,
    this.pauseEnd,
    this.tiffineService,
    this.mealType,
    this.uniqueCode,
    this.remainingOrders = 0,
    this.pendingAmount = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionType': subscriptionType,
      'category': category,
      'tiffineService': tiffineService,
      'mealType': mealType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'paymentCompleted': paymentCompleted,
      'quantityPerDay': quantityPerDay,
      'mealPeriods': mealPeriods,
      'extraOrders': extraOrders,
      'remainingOrders': remainingOrders,
      'pendingAmount': pendingAmount,
      'autoRenew': autoRenew,
      'pauseStart': pauseStart?.toIso8601String(),
      'pauseEnd': pauseEnd?.toIso8601String(),
      'uniqueCode': uniqueCode,
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      userId: json['userId'],
      subscriptionType: json['subscriptionType'],
      category: json['category'],
      tiffineService: json['tiffineService'],
      mealType: json['mealType'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      amount: json['amount'].toDouble(),
      isActive: json['isActive'] ?? true,
      paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
      paymentCompleted: json['paymentCompleted'] ?? false,
      quantityPerDay: json['quantityPerDay'] ?? 1,
      mealPeriods: (json['mealPeriods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      extraOrders: json['extraOrders'] ?? 0,
      remainingOrders: json['remainingOrders'] ?? 0,
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      autoRenew: json['autoRenew'] ?? true,
      pauseStart: json['pauseStart'] != null
          ? DateTime.parse(json['pauseStart'])
          : null,
      pauseEnd:
          json['pauseEnd'] != null ? DateTime.parse(json['pauseEnd']) : null,
      uniqueCode: json['uniqueCode'],
    );
  }

  bool get isValid {
    if (!isActive || !paymentCompleted) return false;
    return DateTime.now().isBefore(endDate);
  }
}
