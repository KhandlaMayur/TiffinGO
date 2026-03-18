import 'package:flutter/material.dart';
import '../models/tiffine_service_model.dart';
import '../data/meal_plans_data.dart';

class MealPlanDetailsScreen extends StatefulWidget {
  final MealPlan mealPlan;
  final String mealType;
  final String serviceId;
  final String selectedDay;

  /// optional pre-fetched list of menu strings, useful to display immediately
  final List<String>? initialMenu;

  const MealPlanDetailsScreen({
    super.key,
    required this.mealPlan,
    required this.mealType,
    required this.serviceId,
    required this.selectedDay,
    this.initialMenu,
  });

  @override
  State<MealPlanDetailsScreen> createState() => _MealPlanDetailsScreenState();
}

class _MealPlanDetailsScreenState extends State<MealPlanDetailsScreen> {
  List<String> dayItems = [];
  bool _loading = false;

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '📄 MealPlanDetailsScreen init: initialMenu=${widget.initialMenu}, length=${widget.initialMenu?.length ?? 0}');
    if (widget.initialMenu != null && widget.initialMenu!.isNotEmpty) {
      debugPrint('📄 Using initialMenu from navigation');
      dayItems = widget.initialMenu!;
    } else {
      debugPrint('📄 No initialMenu, fetching from Firestore...');
      _loadDayItems();
    }
  }

  Future<void> _loadDayItems() async {
    setState(() {
      _loading = true;
    });

    // Force refresh to ensure latest seller updates are reflected immediately.
    final items = await MealPlansData.getDailyMenu(
      widget.serviceId,
      widget.mealType,
      widget.mealPlan.id,
      widget.selectedDay,
      forceRefresh: true,
    );

    // debug output – will appear in console when running
    debugPrint(
        'loaded menu: ${widget.serviceId}/${widget.mealType}/${widget.mealPlan.id}/${widget.selectedDay} -> $items');
    setState(() {
      dayItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<MealPlanItem> items = dayItems
        .map((s) => MealPlanItem(name: s, image: '', quantity: 1))
        .toList();

    Widget bodyContent;
    if (_loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      bodyContent = Center(
        child: Text(
          'No menu available for ${_capitalize(widget.selectedDay)}.\n'
          'Please make sure the Firestore document contains the data.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      bodyContent = ListView(
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
                  '₹${(widget.mealPlan.prices[widget.mealType] ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.mealPlan.description,
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.mealPlan.name} ${_capitalize(widget.serviceId)} ${_capitalize(widget.selectedDay)}'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: bodyContent,
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
            child: const Icon(
              Icons.restaurant,
              color: Color(0xFF1E3A8A),
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
