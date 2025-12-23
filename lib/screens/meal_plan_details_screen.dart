import 'package:flutter/material.dart';
import '../models/tiffine_service_model.dart';
import '../data/meal_plans_data.dart';

class MealPlanDetailsScreen extends StatelessWidget {
  final MealPlan mealPlan;
  final String mealType;
  final String serviceId;
  final String selectedDay;

  const MealPlanDetailsScreen({
    super.key,
    required this.mealPlan,
    required this.mealType,
    required this.serviceId,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    // If a selectedDay is provided, prefer daily menu from MealPlansData
    final dayItems = MealPlansData.getDailyMenu(
        serviceId, mealType, mealPlan.id, selectedDay);
    final items = (dayItems.isNotEmpty)
        ? dayItems
            .map((s) => MealPlanItem(name: s, image: '', quantity: 1))
            .toList()
        : (mealPlan.contents[mealType] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('${mealPlan.name} - ${mealType.toUpperCase()}'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with price
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E3A8A).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF1E3A8A)),
            ),
            child: Column(
              children: [
                Text(
                  '₹${(mealPlan.prices[mealType] ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mealPlan.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What\'s Inside:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          // Meal plan / daily menu items
          ...items.map((item) => _buildFoodItem(item)),
        ],
      ),
    );
  }

  Widget _buildFoodItem(MealPlanItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant,
              color: const Color(0xFF1E3A8A),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          // Food Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} piece(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
