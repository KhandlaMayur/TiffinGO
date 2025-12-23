class TiffineServiceModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final String city;
  final String deliveryTime;
  final double price;

  TiffineServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.city,
    required this.deliveryTime,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'rating': rating,
      'city': city,
      'deliveryTime': deliveryTime,
      'price': price,
    };
  }

  factory TiffineServiceModel.fromJson(Map<String, dynamic> json) {
    return TiffineServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      rating: json['rating'],
      city: json['city'],
      deliveryTime: json['deliveryTime'],
      price: json['price'],
    );
  }
}

// Meal Type Model
class MealType {
  final String name;
  final String type; // 'veg' or 'jain'

  MealType({required this.name, required this.type});
}

// Extra Food Item Model
class ExtraFoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // 'bread', 'rice', 'sabji', 'dal', 'side', 'sweet'
  final String image;

  ExtraFoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
  });
}

// Meal Plan Item (what's inside the tiffin)
class MealPlanItem {
  final String name;
  final String image;
  final int quantity;

  MealPlanItem({
    required this.name,
    required this.image,
    required this.quantity,
  });
}

// Meal Plan Model
class MealPlan {
  final String id;
  final String name;
  final String description;
  final Map<String, double> prices; // {'veg': price, 'jain': price}
  final String specialOffer;
  final Map<String, List<MealPlanItem>> contents; // {'veg': items, 'jain': items}
  final List<ExtraFoodItem> extraFoodItems;

  MealPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.prices,
    required this.specialOffer,
    required this.contents,
    required this.extraFoodItems,
  });
}

// Subscription Model
class Subscription {
  final String id;
  final String name; // 'Daily', 'Weekly', 'Monthly'
  final int days;
  final double discountPercent;

  Subscription({
    required this.id,
    required this.name,
    required this.days,
    required this.discountPercent,
  });
}

