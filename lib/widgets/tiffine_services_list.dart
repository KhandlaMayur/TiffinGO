import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../models/tiffine_service_model.dart';
import '../data/meal_plans_data.dart';
import '../screens/payment_delivery_screen.dart';
import '../screens/subscription_screen.dart';

class TiffineServicesList extends StatelessWidget {
  final String searchQuery;
  final ScrollController? scrollController;

  const TiffineServicesList({
    super.key,
    this.searchQuery = '',
    this.scrollController,
  });

  final List<Map<String, dynamic>> _services = const [
    {
      'name': 'Kathiyavadi Tiffine Service',
      'description': 'Authentic Kathiyawadi cuisine with traditional flavors',
      'rating': 4.5,
      'deliveryTime': '30-45 mins',
      'price': '₹150-₹300',
      'image': 'assets/images/kathiyavadi.jpg',
      'id': 'kathiyavadi',
    },
    {
      'name': 'Desi Rotalo Tiffine Service',
      'description': 'Fresh rotis and traditional Gujarati dishes',
      'rating': 4.3,
      'deliveryTime': '25-40 mins',
      'price': '₹120-₹250',
      'image': 'assets/images/desi_rotalo.jpg',
      'id': 'desi_rotalo',
    },
    {
      'name': 'Nani Tiffine Service',
      'description': 'Home-style cooking with grandmother\'s recipes',
      'rating': 4.7,
      'deliveryTime': '35-50 mins',
      'price': '₹180-₹350',
      'image': 'assets/images/nani.jpg',
      'id': 'nani',
    },
    {
      'name': 'Rajwadi Tiffine Service',
      'description': 'Royal Rajasthani cuisine with rich flavors',
      'rating': 4.4,
      'deliveryTime': '40-55 mins',
      'price': '₹200-₹400',
      'image': 'assets/images/rajwadi.jpg',
      'id': 'rajwadi',
    },
  ];

  List<Map<String, dynamic>> get _filteredServices {
    if (searchQuery.isEmpty) {
      return _services;
    }
    return _services.where((service) {
      final name = service['name'].toString().toLowerCase();
      final description = service['description'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _filteredServices;

    if (filteredServices.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Tiffine Service Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return _buildServiceCard(context, service, index);
      },
    );
  }

  Widget _buildServiceCard(
      BuildContext context, Map<String, dynamic> service, int index) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final isFavorite = orderProvider.isFavorite(service['name']);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TiffinMenuScreen(service: service),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF1E3A8A).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image (use Image.asset with errorBuilder to avoid crashes from invalid image data)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image with graceful error handling
                        Image.asset(
                          service['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Show a placeholder if the asset image fails to load
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),

                        // Gradient overlay to improve text contrast
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1E3A8A).withOpacity(0.25),
                                const Color(0xFF3B82F6).withOpacity(0.15),
                              ],
                            ),
                          ),
                        ),

                        // Favorite button
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              if (isFavorite) {
                                orderProvider
                                    .removeFromFavorites(service['name']);
                              } else {
                                orderProvider.addToFavorites(service['name']);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Service Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.star,
                            '${service['rating']}',
                            Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.timer,
                            service['deliveryTime'],
                            const Color(0xFF1E3A8A),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.currency_rupee,
                            service['price'],
                            Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TiffinMenuScreen(service: service),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'View Menu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SubscriptionScreen(service: service),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Subscribe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Tiffin Menu Screen
class TiffinMenuScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const TiffinMenuScreen({super.key, required this.service});

  @override
  State<TiffinMenuScreen> createState() => _TiffinMenuScreenState();
}

class _TiffinMenuScreenState extends State<TiffinMenuScreen> {
  String? _selectedMealType; // 'veg' or 'jain'
  String? _selectedMealPlan;
  late String _selectedDay;
  late final String _todayDay;
  final Map<String, int> _selectedExtraFood = {}; // Changed to track quantities
  double _totalPrice = 0.0;

  late final List<MealPlan> _mealPlans;

  @override
  void initState() {
    super.initState();
    // Determine today's weekday and lock other days
    _todayDay = _weekdayToString(DateTime.now().weekday);
    _selectedDay = _todayDay;

    // Get meal plans from data file
    _mealPlans = MealPlansData.getVegMealPlans(widget.service['id']);
    _calculateTotal();
  }

  String _weekdayToString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  // Previous hardcoded list removed - using MealPlansData now
  /*
  final List<MealPlan> _mealPlans = [
    MealPlan(
      id: 'normal',
      name: 'Normal Tiffine',
      description: 'Regular nutritious meal',
      prices: {'veg': 100.0, 'jain': 110.0},
      specialOffer: '10% off on first order',
      extraFoodItems: [
        ExtraFoodItem(
          id: 'extra1',
          name: 'Extra Roti',
          description: '2 Rotis',
          price: 20.0,
          mealPlan: 'normal',
        ),
        ExtraFoodItem(
          id: 'extra2',
          name: 'Extra Rice',
          description: 'Bowl of rice',
          price: 25.0,
          mealPlan: 'normal',
        ),
      ],
    ),
    MealPlan(
      id: 'premium',
      name: 'Premium Tiffine',
      description: 'Delicious premium meal',
      prices: {'veg': 150.0, 'jain': 160.0},
      specialOffer: '15% off on weekly subscription',
      extraFoodItems: [
        ExtraFoodItem(
          id: 'extra3',
          name: 'Mohanthal',
          description: 'Traditional sweet',
          price: 40.0,
          mealPlan: 'premium',
        ),
        ExtraFoodItem(
          id: 'extra4',
          name: 'Barfi',
          description: 'Sweet barfi',
          price: 35.0,
          mealPlan: 'premium',
        ),
      ],
    ),
    MealPlan(
      id: 'deluxe',
      name: 'Deluxe Tiffine',
      description: 'Luxury meal experience',
      prices: {'veg': 200.0, 'jain': 210.0},
      specialOffer: '20% off on monthly subscription',
      extraFoodItems: [
        ExtraFoodItem(
          id: 'extra5',
          name: 'Gulab Jamun',
          description: '2 pieces',
          price: 50.0,
          mealPlan: 'deluxe',
        ),
        ExtraFoodItem(
          id: 'extra6',
          name: 'Rabdi',
          description: 'Creamy dessert',
          price: 60.0,
          mealPlan: 'deluxe',
        ),
      ],
    ),
    MealPlan(
      id: 'gym',
      name: 'Gym Tiffin',
      description: 'High protein meal',
      prices: {'veg': 180.0, 'jain': 190.0},
      specialOffer: '5% off on all orders',
      extraFoodItems: [
        ExtraFoodItem(
          id: 'extra7',
          name: 'Extra Protein',
          description: 'Protein shake',
          price: 80.0,
          mealPlan: 'gym',
        ),
      ],
    ),
    MealPlan(
      id: 'combo',
      name: 'Combo Tiffine',
      description: 'Meal combo',
      prices: {'veg': 170.0, 'jain': 180.0},
      specialOffer: '12% off on combo',
      extraFoodItems: [
        ExtraFoodItem(
          id: 'extra8',
          name: 'Extra Curry',
          description: 'Additional curry',
          price: 30.0,
          mealPlan: 'combo',
        ),
      ],
    ),
  ];
  */

  void _calculateTotal() {
    if (_selectedMealType == null || _selectedMealPlan == null) {
      _totalPrice = 0.0;
      return;
    }

    final mealPlan =
        _mealPlans.firstWhere((plan) => plan.id == _selectedMealPlan);
    double price = mealPlan.prices[_selectedMealType] ?? 0.0;

    // Add extra food prices
    for (var entry in _selectedExtraFood.entries) {
      if (entry.value > 0) {
        final extraItem = mealPlan.extraFoodItems.firstWhere(
          (item) => item.id == entry.key,
          orElse: () => ExtraFoodItem(
            id: '',
            name: '',
            description: '',
            price: 0.0,
            category: '',
            image: '',
          ),
        );
        if (extraItem.id.isNotEmpty) {
          price += extraItem.price * entry.value;
        }
      }
    }

    setState(() {
      _totalPrice = price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service['name']),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Price Display at Top
          if (_totalPrice > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.currency_rupee, color: Colors.green),
                  Text(
                    _totalPrice.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Type Selection - FIRST
                  const Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMealTypeChip('Veg', 'veg', Icons.eco),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMealTypeChip('Jain', 'jain', Icons.spa),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Day selector row (Mon - Sun)
                  const Text(
                    'Select Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 4),
                        ...[
                          'monday',
                          'tuesday',
                          'wednesday',
                          'thursday',
                          'friday',
                          'saturday',
                          'sunday'
                        ].map((day) {
                          final isSelected = _selectedDay == day;
                          final isToday = _todayDay == day;
                          final label =
                              day[0].toUpperCase() + day.substring(1, 3);
                          return GestureDetector(
                            onTap: isToday
                                ? () {
                                    setState(() {
                                      _selectedDay = day;
                                    });
                                  }
                                : () {
                                    // Day is locked - show a brief message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '$label is locked. Only today ( ${_todayDay[0].toUpperCase() + _todayDay.substring(1)} ) is available.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : isToday
                                        ? Colors.grey[200]
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : isToday
                                          ? Colors.grey[300]!
                                          : Colors.grey[200]!,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : isToday
                                                ? Colors.grey[800]
                                                : Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!isToday) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.lock,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meal Plans - THIRD
                  if (_selectedMealType != null) ...[
                    const Text(
                      'Select Meal Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_mealPlans.map((plan) => _buildMealPlanCard(plan))),
                    const SizedBox(height: 24),

                    // Extra Food Options - FOURTH
                    if (_selectedMealPlan != null) ...[
                      ...(_buildExtraFoodSection()),
                    ],
                  ],
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Order Now Button (shown only when items are selected)
      bottomNavigationBar: _totalPrice > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _showOrderConfirmation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Order Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMealTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedMealType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealType = value;
          _selectedMealPlan = null;
          _selectedExtraFood.clear();
          _calculateTotal();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlanCard(MealPlan plan) {
    final isSelected = _selectedMealPlan == plan.id;
    final price = plan.prices[_selectedMealType] ?? 0.0;

    return GestureDetector(
      onLongPress: () {
        // Show meal plan details popup with animation
        _showMealPlanDetailsPopup(context, plan);
      },
      onTap: () {
        setState(() {
          _selectedMealPlan = plan.id;
          _selectedExtraFood.clear();
          _calculateTotal();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A8A).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.black,
                  ),
                ),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan.specialOffer,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExtraFoodSection() {
    if (_selectedMealPlan == null) return [];

    final mealPlan =
        _mealPlans.firstWhere((plan) => plan.id == _selectedMealPlan);

    return [
      const Text(
        'Add Extra Food',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
      const SizedBox(height: 12),
      ...(mealPlan.extraFoodItems.map((item) => _buildExtraFoodCard(item))),
    ];
  }

  Widget _buildExtraFoodCard(ExtraFoodItem item) {
    final quantity = _selectedExtraFood[item.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: quantity > 0
            ? const Color(0xFF1E3A8A).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0 ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: quantity > 0 ? const Color(0xFF1E3A8A) : Colors.grey,
                onPressed: quantity > 0
                    ? () {
                        setState(() {
                          _selectedExtraFood[item.id] = quantity - 1;
                          _calculateTotal();
                        });
                      }
                    : null,
              ),
              Text(
                quantity.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF1E3A8A),
                onPressed: () {
                  setState(() {
                    _selectedExtraFood[item.id] = quantity + 1;
                    _calculateTotal();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation() {
    final mealPlan =
        _mealPlans.firstWhere((plan) => plan.id == _selectedMealPlan);

    // Build extra food list with quantities
    final List<String> extraFoodList = [];
    for (var entry in _selectedExtraFood.entries) {
      if (entry.value > 0) {
        final item =
            mealPlan.extraFoodItems.firstWhere((item) => item.id == entry.key);
        extraFoodList.add('${entry.value}x ${item.name}');
      }
    }

    // Create order
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serviceName: widget.service['name'],
      serviceId: widget.service['id'], // Add service ID for code validation
      date: DateTime.now().toString().split(' ')[0],
      amount: _totalPrice,
      status: 'Ordering',
      paymentMethod: 'Cash on Delivery',
      mealType: _selectedMealType!,
      mealPlan: mealPlan.name,
      categoryId: _selectedMealPlan, // Add category ID for code validation
      subscription: 'Daily',
      extraFood: extraFoodList,
      location: null,
      paymentCompleted: false,
    );

    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDeliveryScreen(order: order),
      ),
    );
  }

  void _showMealPlanDetailsPopup(BuildContext context, MealPlan plan) {
    final mealItems = plan.contents[_selectedMealType] ?? [];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: AlertDialog(
            title: Text(
              plan.name,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Meal Type: ${_selectedMealType ?? "N/A"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Menu Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (mealItems.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mealItems
                          .map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.restaurant,
                                      size: 16,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.name}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    )
                  else
                    const Text(
                      'No items for this meal type',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Text(
                          '₹${plan.prices[_selectedMealType]?.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
