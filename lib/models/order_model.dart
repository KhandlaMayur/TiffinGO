class OrderModel {
  final String id;
  final String serviceName;
  final String? serviceId; // ID of tiffine service (e.g., 'kathiyavadi')
  final String date;
  final double amount;
  final String status;
  final String paymentMethod;
  final String mealType;
  final String mealPlan;
  final String? categoryId; // ID of tiffine category (e.g., 'normal')
  final String subscription;
  final List<String> extraFood;
  final Map<String, dynamic>? location;
  final bool paymentCompleted;
  final double rating; // 0-5 stars, 0 means not rated
  final double deliveryCharge; // Delivery charge in rupees
  final double distanceInKm; // Distance from seller to user in km
  final Map<String, dynamic>?
      sellerLocation; // Seller's kitchen location {latitude, longitude}

  OrderModel({
    required this.id,
    required this.serviceName,
    this.serviceId,
    required this.date,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.mealType,
    required this.mealPlan,
    this.categoryId,
    required this.subscription,
    required this.extraFood,
    this.location,
    required this.paymentCompleted,
    this.rating = 0, // Default: not rated
    this.deliveryCharge = 0.0,
    this.distanceInKm = 0.0,
    this.sellerLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'serviceId': serviceId,
      'date': date,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'mealType': mealType,
      'mealPlan': mealPlan,
      'categoryId': categoryId,
      'subscription': subscription,
      'extraFood': extraFood,
      'location': location,
      'paymentCompleted': paymentCompleted,
      'rating': rating,
      'deliveryCharge': deliveryCharge,
      'distanceInKm': distanceInKm,
      'sellerLocation': sellerLocation,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      serviceName: json['serviceName'],
      serviceId: json['serviceId'],
      date: json['date'],
      amount: json['amount'],
      status: json['status'],
      paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
      mealType: json['mealType'] ?? 'veg',
      mealPlan: json['mealPlan'] ?? 'Normal Tiffine',
      categoryId: json['categoryId'],
      subscription: json['subscription'] ?? 'Daily',
      extraFood: List<String>.from(json['extraFood'] ?? []),
      location: json['location'],
      paymentCompleted: json['paymentCompleted'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      distanceInKm: (json['distanceInKm'] ?? 0).toDouble(),
      sellerLocation: json['sellerLocation'],
    );
  }
}
