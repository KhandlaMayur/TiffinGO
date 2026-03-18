import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'seller_service_form_screen.dart';

class SellerMenuManagementScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const SellerMenuManagementScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<SellerMenuManagementScreen> createState() =>
      _SellerMenuManagementScreenState();
}

class _SellerMenuManagementScreenState
    extends State<SellerMenuManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Store comma-separated menu items for each plan + meal type
  final Map<String, TextEditingController> _controllers = {};

  // Store prices per plan + meal type
  final Map<String, TextEditingController> _priceControllers = {};

  /// Plan IDs that this seller currently offers.
  ///
  /// This is loaded from the seller service document's `tiffinTypes` field.
  List<String> _planIds = [];

  bool _isLoadingPlanIds = true;

  @override
  void initState() {
    super.initState();
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

    // Load existing menus and prices for the selected types.
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
    // Dispose old controllers if reinitializing.
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _priceControllers.clear();

    for (final plan in _planIds) {
      _controllers['veg_$plan'] = TextEditingController();
      _controllers['jain_$plan'] = TextEditingController();

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

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingMenus() async {
    final doc = await FirebaseFirestore.instance
        .collection('mealPlans')
        .doc('menus')
        .get();

    if (!doc.exists) return;

    final data = (doc.data() ?? {})[widget.serviceId];
    if (data is! Map<String, dynamic>) return;

    // Use today's override menu (if any) for display; otherwise fall back to the
    // standard weekly menu used by the app.
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final overrides = (data['overrides'] as Map<String, dynamic>?) ?? {};
    final todayOverride = overrides[todayKey] as Map<String, dynamic>?;

    for (final plan in _planIds) {
      final vegOverrideList = ((todayOverride?['veg'] ?? {})
          as Map<String, dynamic>?)?[plan] as List<dynamic>?;
      final jainOverrideList = ((todayOverride?['jain'] ?? {})
          as Map<String, dynamic>?)?[plan] as List<dynamic>?;

      final vegList = vegOverrideList ??
          ((data['veg'] ?? {})[plan] ?? {})['monday'] as List<dynamic>?;
      final jainList = jainOverrideList ??
          ((data['jain'] ?? {})[plan] ?? {})['monday'] as List<dynamic>?;

      if (vegList != null && vegList.isNotEmpty) {
        _controllers['veg_$plan']?.text = vegList.join(', ');
      }
      if (jainList != null && jainList.isNotEmpty) {
        _controllers['jain_$plan']?.text = jainList.join(', ');
      }
    }

    setState(() {});
  }

  Future<void> _saveMenu() async {
    if (_planIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tiffin types selected for this service. Please configure your service first.',
          ),
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
      // We treat "Manage Standard Menu" as a way for sellers to update today's menu.
      // This is stored under mealPlans/menus/{serviceId}/overrides/{YYYY-MM-DD}.
      final todayKey = DateTime.now().toIso8601String().split('T')[0];

      final Map<String, dynamic> overrideData = {
        'veg': {},
        'jain': {},
      };

      final Map<String, dynamic> priceData = {};

      for (final plan in _planIds) {
        final vegItems = _controllers['veg_$plan']!
            .text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final jainItems = _controllers['jain_$plan']!
            .text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        overrideData['veg'][plan] = vegItems;
        overrideData['jain'][plan] = jainItems;

        // Prices for this plan
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

      // Save override for the current date.
      final docRef =
          FirebaseFirestore.instance.collection('mealPlans').doc('menus');

      await docRef.set({
        widget.serviceId: {
          'overrides': {
            todayKey: overrideData,
          },
        },
      }, SetOptions(merge: true));

      // Save prices to the tiffin service document so user can see the correct price
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.serviceId)
          .set({
        'prices': priceData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Refresh in case other fields are updated elsewhere.
      await _loadExistingMenus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update menu: ${e.toString()}'),
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
              'No tiffin types are configured for your service. Please select at least one type in the service settings.',
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

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Menu - ${widget.serviceName}'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoadingPlanIds
            ? const Center(child: CircularProgressIndicator())
            : _planIds.isEmpty
                ? _buildNoPlansView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'This updates today\'s menu (overrides weekly menu) for users once saved.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ..._planIds.map((plan) {
                            final displayName = plan[0].toUpperCase() +
                                plan.substring(1).replaceAll('_', ' ');
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceControllers[
                                            'veg_${plan}_price'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Veg Price',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Enter veg price';
                                          }
                                          if (double.tryParse(value.trim()) ==
                                              null) {
                                            return 'Invalid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceControllers[
                                            'jain_${plan}_price'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Jain Price',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Enter jain price';
                                          }
                                          if (double.tryParse(value.trim()) ==
                                              null) {
                                            return 'Invalid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _controllers['veg_$plan'],
                                  decoration: const InputDecoration(
                                    labelText: 'Veg Items (comma separated)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _controllers['jain_$plan'],
                                  decoration: const InputDecoration(
                                    labelText: 'Jain Items (comma separated)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveMenu,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Save Menu',
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
                  ),
      ),
    );
  }
}
