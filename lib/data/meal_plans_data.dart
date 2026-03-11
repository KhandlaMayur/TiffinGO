import 'package:flutter/foundation.dart';
import '../models/tiffine_service_model.dart';
import '../services/firestore_service.dart';

class MealPlansData {
  // Store as dynamic to handle Firestore's Map<String, dynamic> format
  static Map<String, dynamic>? _dailyMenus;
  static final FirestoreService _firestoreService = FirestoreService();

  static Future<void> loadData() async {
    if (_dailyMenus != null) return;
    final data = await _firestoreService.getMealPlansData();
    _dailyMenus = data;
  }

  static Future<List<String>> getDailyMenu(
      String service, String menuType, String planType, String day) async {
    await loadData();
    try {
      final serviceData = _dailyMenus?[service];
      if (serviceData == null) return [];

      final typeData = serviceData[menuType];
      if (typeData == null) return [];

      final planData = typeData[planType];
      if (planData == null) return [];

      final dayData = planData[day.toLowerCase()];
      if (dayData is List) {
        return dayData.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      return [];
    }
  }

  static List<MealPlan> getVegMealPlans(String serviceId) {
    return [
      MealPlan(
        id: 'normal',
        name: 'Normal Tiffine',
        description: 'Regular nutritious meal',
        prices: {'veg': 100.0, 'jain': 110.0},
        specialOffer: '10% off on first order',
        contents: {
          'veg': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Main Course',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Dal/Kadhi', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Salad', image: 'assets/images/salad.jpg', quantity: 1),
          ],
          'jain': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Jain Main Course',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Jain Dal/Kadhi',
                image: 'assets/images/dal.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Salad', image: 'assets/images/salad.jpg', quantity: 1),
          ],
        },
        extraFoodItems: [
          ExtraFoodItem(
            id: 'extra1',
            name: 'Extra Roti',
            description: '2 Rotis',
            price: 20.0,
            category: 'bread',
            image: 'assets/images/chapati.jpg',
          ),
          ExtraFoodItem(
            id: 'extra2',
            name: 'Extra Rice',
            description: 'Bowl of rice',
            price: 25.0,
            category: 'rice',
            image: 'assets/images/rice.jpg',
          ),
        ],
      ),
      MealPlan(
        id: 'premium',
        name: 'Premium Tiffine',
        description: 'Delicious premium meal',
        prices: {'veg': 150.0, 'jain': 160.0},
        specialOffer: '15% off on weekly subscription',
        contents: {
          'veg': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Premium Main Course',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Dal/Kadhi', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Salad', image: 'assets/images/salad.jpg', quantity: 1),
          ],
          'jain': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Jain Premium Main Course',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Jain Dal/Kadhi',
                image: 'assets/images/dal.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Salad', image: 'assets/images/salad.jpg', quantity: 1),
          ],
        },
        extraFoodItems: [
          ExtraFoodItem(
            id: 'extra3',
            name: 'Mohanthal',
            description: 'Traditional sweet',
            price: 40.0,
            category: 'sweet',
            image: 'assets/images/sweet.jpg',
          ),
          ExtraFoodItem(
            id: 'extra4',
            name: 'Barfi',
            description: 'Sweet barfi',
            price: 35.0,
            category: 'sweet',
            image: 'assets/images/sweet.jpg',
          ),
        ],
      ),
      MealPlan(
        id: 'deluxe',
        name: 'Deluxe Tiffine',
        description: 'Luxury meal experience',
        prices: {'veg': 200.0, 'jain': 210.0},
        specialOffer: '20% off on monthly subscription',
        contents: {
          'veg': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Deluxe Main Course',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Dal/Kadhi', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Sweet', image: 'assets/images/sweet.jpg', quantity: 1),
          ],
          'jain': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Jain Deluxe Main Course',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Jain Dal/Kadhi',
                image: 'assets/images/dal.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Sweet', image: 'assets/images/sweet.jpg', quantity: 1),
          ],
        },
        extraFoodItems: [
          ExtraFoodItem(
            id: 'extra5',
            name: 'Gulab Jamun',
            description: '2 pieces',
            price: 50.0,
            category: 'sweet',
            image: 'assets/images/sweet.jpg',
          ),
          ExtraFoodItem(
            id: 'extra6',
            name: 'Rabdi',
            description: 'Creamy dessert',
            price: 60.0,
            category: 'sweet',
            image: 'assets/images/sweet.jpg',
          ),
        ],
      ),
      MealPlan(
        id: 'gym_diet',
        name: 'Gym Tiffin',
        description: 'High protein meal',
        prices: {'veg': 180.0, 'jain': 190.0},
        specialOffer: '5% off on all orders',
        contents: {
          'veg': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 2),
            MealPlanItem(
                name: 'Brown Rice',
                image: 'assets/images/rice.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Moong Dal', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Boiled Veg',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
          ],
          'jain': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 2),
            MealPlanItem(
                name: 'Brown Rice',
                image: 'assets/images/rice.jpg',
                quantity: 1),
            MealPlanItem(
                name: 'Moong Dal', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Boiled Veg',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
          ],
        },
        extraFoodItems: [
          ExtraFoodItem(
            id: 'extra7',
            name: 'Extra Protein',
            description: 'Protein shake',
            price: 80.0,
            category: 'side',
            image: 'assets/images/protein.jpg',
          ),
        ],
      ),
      MealPlan(
        id: 'combo',
        name: 'Combo Tiffine',
        description: 'Meal combo',
        prices: {'veg': 170.0, 'jain': 180.0},
        specialOffer: '12% off on combo',
        contents: {
          'veg': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Dal', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Sabji', image: 'assets/images/sabji.jpg', quantity: 1),
          ],
          'jain': [
            MealPlanItem(
                name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
            MealPlanItem(
                name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
            MealPlanItem(
                name: 'Jain Dal', image: 'assets/images/dal.jpg', quantity: 1),
            MealPlanItem(
                name: 'Jain Sabji',
                image: 'assets/images/sabji.jpg',
                quantity: 1),
          ],
        },
        extraFoodItems: [
          ExtraFoodItem(
            id: 'extra8',
            name: 'Extra Curry',
            description: 'Additional curry',
            price: 30.0,
            category: 'sabji',
            image: 'assets/images/sabji.jpg',
          ),
        ],
      ),
    ];
  }
}
