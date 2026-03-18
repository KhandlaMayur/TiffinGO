import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'seller_service_form_screen.dart';

class SellerWeeklyMenuScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const SellerWeeklyMenuScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<SellerWeeklyMenuScreen> createState() => _SellerWeeklyMenuScreenState();
}

class _SellerWeeklyMenuScreenState extends State<SellerWeeklyMenuScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  late TabController _tabController;

  // controllers structured as: _controllers[day][plan][veg/jain]
  final Map<String, Map<String, Map<String, TextEditingController>>>
      _controllers = {};

  // Store prices per plan (price remains global per plan)
  final Map<String, TextEditingController> _priceControllers = {};

  List<String> _planIds = [];
  bool _isLoadingPlanIds = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    _loadServiceConfig();
  }

  Future<void> _loadServiceConfig() async {
    setState(() {
      _isLoadingPlanIds = true;
    });

    final doc = await FirebaseFirestore.instance
        .collection('tiffin_services')
        .doc(widget.serviceId)
        .get();

    if (!doc.exists) {
      if (mounted) {
        setState(() {
          _isLoadingPlanIds = false;
        });
      }
      return;
    }

    final data = doc.data() ?? {};
    _planIds = (data['tiffinTypes'] as List<dynamic>?)?.cast<String>() ?? [];

    _initControllersForPlans();

    await Future.wait([
      _loadExistingMenus(),
      _loadExistingPrices(data),
    ]);

    if (!mounted) return;
    setState(() {
      _isLoadingPlanIds = false;
    });
  }

  void _initControllersForPlans() {
    // Dipsose prior to clearing if already loaded
    for (final dayControllers in _controllers.values) {
      for (final planControllers in dayControllers.values) {
        planControllers['veg']?.dispose();
        planControllers['jain']?.dispose();
      }
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _priceControllers.clear();

    for (final day in _days) {
      _controllers[day] = {};
      for (final plan in _planIds) {
        _controllers[day]![plan] = {
          'veg': TextEditingController(),
          'jain': TextEditingController(),
        };
      }
    }

    for (final plan in _planIds) {
      _priceControllers['veg_${plan}_price'] = TextEditingController();
      _priceControllers['jain_${plan}_price'] = TextEditingController();
    }
  }

  Future<void> _loadExistingPrices([Map<String, dynamic>? serviceData]) async {
    Map<String, dynamic>? data = serviceData;
    if (data == null) {
      final doc = await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.serviceId)
          .get();

      if (!doc.exists) return;
      data = doc.data() as Map<String, dynamic>?;
    }

    if (data == null) return;
    final prices = data['prices'] as Map<String, dynamic>?;
    if (prices == null) return;

    for (final plan in _planIds) {
      final planPrice = prices[plan] as Map<String, dynamic>?;
      if (planPrice == null) continue;

      final veg = planPrice['veg'];
      final jain = planPrice['jain'];
      if (veg != null) {
        _priceControllers['veg_${plan}_price']?.text = veg.toString();
      }
      if (jain != null) {
        _priceControllers['jain_${plan}_price']?.text = jain.toString();
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadExistingMenus() async {
    final doc = await FirebaseFirestore.instance
        .collection('mealPlans')
        .doc('menus')
        .get();

    if (!doc.exists) return;

    final data = (doc.data() ?? {})[widget.serviceId];
    if (data is! Map<String, dynamic>) return;

    for (final plan in _planIds) {
      for (final day in _days) {
        final vegList =
            ((data['veg'] ?? {})[plan] ?? {})[day] as List<dynamic>?;
        final jainList =
            ((data['jain'] ?? {})[plan] ?? {})[day] as List<dynamic>?;

        if (vegList != null && vegList.isNotEmpty) {
          _controllers[day]![plan]!['veg']?.text = vegList.join(', ');
        }
        if (jainList != null && jainList.isNotEmpty) {
          _controllers[day]![plan]!['jain']?.text = jainList.join(', ');
        }
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final dayControllers in _controllers.values) {
      for (final planControllers in dayControllers.values) {
        planControllers['veg']?.dispose();
        planControllers['jain']?.dispose();
      }
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMenu() async {
    if (_planIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tiffin types selected. Check service settings.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> serviceData = {
        'veg': {},
        'jain': {},
      };

      final Map<String, dynamic> priceData = {};

      for (final plan in _planIds) {
        serviceData['veg'][plan] = {};
        serviceData['jain'][plan] = {};

        for (final day in _days) {
          final vegItems = _controllers[day]![plan]!['veg']!
              .text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          final jainItems = _controllers[day]![plan]!['jain']!
              .text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          serviceData['veg'][plan][day] = vegItems;
          serviceData['jain'][plan][day] = jainItems;
        }

        // Gather prices for this plan
        final vegPrice = double.tryParse(
                _priceControllers['veg_${plan}_price']?.text ?? '') ??
            0.0;
        final jainPrice = double.tryParse(
                _priceControllers['jain_${plan}_price']?.text ?? '') ??
            0.0;

        priceData[plan] = {
          'veg': vegPrice,
          'jain': jainPrice,
        };
      }

      await FirebaseFirestore.instance
          .collection('mealPlans')
          .doc('menus')
          .set({
        widget.serviceId: serviceData,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.serviceId)
          .set({
        'prices': priceData,
        'menus':
            serviceData, // Store the weekly menu structurally in the seller doc
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reload the form fields so the latest data is immediately visible.
      await _loadExistingMenus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly Menu updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update menu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNoPlansView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'No tiffin types are configured. Please edit your service.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SellerServiceFormScreen(
                    userId: widget.serviceId,
                    userName: widget.serviceName,
                  ),
                ),
              );
            },
            child: const Text('Edit Service Types'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabContent(String day) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configure ${day[0].toUpperCase()}${day.substring(1)} Menu',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F54),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter items separated by commas. Prices apply all week per plan.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._planIds.map((plan) {
              final displayName = plan[0].toUpperCase() +
                  plan.substring(1).replaceAll('_', ' ');
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF001F54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceControllers['veg_${plan}_price'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Veg Price (₹)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter veg price';
                              }
                              return double.tryParse(value.trim()) == null
                                  ? 'Invalid number'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceControllers['jain_${plan}_price'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jain Price (₹)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter jain price';
                              }
                              return double.tryParse(value.trim()) == null
                                  ? 'Invalid number'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _controllers[day]![plan]?['veg'],
                      decoration: const InputDecoration(
                        labelText: 'Veg Items (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers[day]![plan]?['jain'],
                      decoration: const InputDecoration(
                        labelText: 'Jain Items (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F54),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Weekly Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Menu'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: _days.map((day) {
            final shortLabel = day[0].toUpperCase() + day.substring(1, 3);
            return Tab(text: shortLabel);
          }).toList(),
        ),
      ),
      body: SafeArea(
        child: _isLoadingPlanIds
            ? const Center(child: CircularProgressIndicator())
            : _planIds.isEmpty
                ? _buildNoPlansView()
                : TabBarView(
                    controller: _tabController,
                    children:
                        _days.map((day) => _buildDayTabContent(day)).toList(),
                  ),
      ),
    );
  }
}
