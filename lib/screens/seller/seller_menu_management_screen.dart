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
  List<String> _planIds = [];

  bool _isLoadingPlanIds = true;

  // Day picker state
  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  late String _selectedDay;

  // Track whether an override exists for the selected day
  bool _hasOverrideForSelectedDay = false;

  @override
  void initState() {
    super.initState();
    // Default to today's weekday
    _selectedDay = _weekdayToString(DateTime.now().weekday);
    _loadServiceConfig();
  }

  String _weekdayToString(int weekday) {
    const names = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return names[weekday - 1];
  }

  /// Compute the YYYY-MM-DD for the next occurrence of [dayName] within the
  /// current week (Mon-Sun). If the day has already passed this week, use the
  /// next week's occurrence.
  String _dateKeyForDay(String dayName) {
    final now = DateTime.now();
    final targetWeekday = _days.indexOf(dayName.toLowerCase()) + 1; // 1=Mon
    int diff = targetWeekday - now.weekday;
    if (diff < 0) diff += 7; // next week
    final targetDate = DateTime(now.year, now.month, now.day + diff);
    return targetDate.toIso8601String().split('T')[0];
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

    // Load existing prices.
    await _loadExistingPrices(data);

    // Load menu for default selected day.
    await _loadMenuForSelectedDay();

    if (!mounted) return;
    setState(() {
      _isLoadingPlanIds = false;
    });
  }

  void _initControllersForPlans() {
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

  /// Load menu data for the currently selected day.
  ///
  /// Priority:
  /// 1. Override for the selected day's date key → show override items.
  /// 2. Default weekly menu for that day → show as editable defaults.
  Future<void> _loadMenuForSelectedDay() async {
    // Clear existing menu text
    for (final plan in _planIds) {
      _controllers['veg_$plan']?.text = '';
      _controllers['jain_$plan']?.text = '';
    }

    final doc = await FirebaseFirestore.instance
        .collection('mealPlans')
        .doc('menus')
        .get();

    if (!doc.exists) {
      _hasOverrideForSelectedDay = false;
      if (mounted) setState(() {});
      return;
    }

    final data = (doc.data() ?? {})[widget.serviceId];
    if (data is! Map<String, dynamic>) {
      _hasOverrideForSelectedDay = false;
      if (mounted) setState(() {});
      return;
    }

    final targetDateKey = _dateKeyForDay(_selectedDay);
    final overrides = (data['overrides'] as Map<String, dynamic>?) ?? {};
    final dayOverride = overrides[targetDateKey] as Map<String, dynamic>?;

    _hasOverrideForSelectedDay = dayOverride != null;

    for (final plan in _planIds) {
      List<dynamic>? vegList;
      List<dynamic>? jainList;

      if (dayOverride != null) {
        // Use override data
        vegList = ((dayOverride['veg'] ?? {}) as Map<String, dynamic>?)?[plan]
            as List<dynamic>?;
        jainList = ((dayOverride['jain'] ?? {}) as Map<String, dynamic>?)?[plan]
            as List<dynamic>?;
      } else {
        // Fall back to default weekly menu for this day
        vegList = ((data['veg'] ?? {})[plan] ?? {})[_selectedDay.toLowerCase()]
            as List<dynamic>?;
        jainList =
            ((data['jain'] ?? {})[plan] ?? {})[_selectedDay.toLowerCase()]
                as List<dynamic>?;
      }

      if (vegList != null && vegList.isNotEmpty) {
        _controllers['veg_$plan']?.text = vegList.join(', ');
      }
      if (jainList != null && jainList.isNotEmpty) {
        _controllers['jain_$plan']?.text = jainList.join(', ');
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
      final targetDateKey = _dateKeyForDay(_selectedDay);

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

      // Save override for the selected day's date.
      final docRef =
          FirebaseFirestore.instance.collection('mealPlans').doc('menus');

      await docRef.set({
        widget.serviceId: {
          'overrides': {
            targetDateKey: overrideData,
          },
        },
      }, SetOptions(merge: true));

      // Save prices to the tiffin service document
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.serviceId)
          .set({
        'prices': priceData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reload to reflect saved state.
      await _loadMenuForSelectedDay();

      if (!mounted) return;

      final dayLabel =
          _selectedDay[0].toUpperCase() + _selectedDay.substring(1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dayLabel\'s menu override saved successfully.'),
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

  /// Remove the override for the selected day so the weekly menu is used
  /// instead.
  Future<void> _removeOverride() async {
    final dayLabel = _selectedDay[0].toUpperCase() + _selectedDay.substring(1);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Override?'),
        content: Text(
          'This will remove the custom menu for $dayLabel and revert to the default weekly menu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final targetDateKey = _dateKeyForDay(_selectedDay);

      await FirebaseFirestore.instance
          .collection('mealPlans')
          .doc('menus')
          .update({
        '${widget.serviceId}.overrides.$targetDateKey': FieldValue.delete(),
      });

      await _loadMenuForSelectedDay();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$dayLabel override removed. Weekly menu will be used.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove override: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Widget _buildDayPicker() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _days.map((day) {
          final isSelected = _selectedDay == day;
          final isToday =
              _weekdayToString(DateTime.now().weekday) == day;
          final label = day[0].toUpperCase() + day.substring(1, 3);
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedDay = day);
              await _loadMenuForSelectedDay();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF001F54)
                    : isToday
                        ? const Color(0xFF001F54).withOpacity(0.1)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF001F54)
                      : isToday
                          ? const Color(0xFF001F54).withOpacity(0.3)
                          : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isToday && !isSelected) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF001F54),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);
    final dayLabel = _selectedDay[0].toUpperCase() + _selectedDay.substring(1);

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
                          // Instruction text
                          const Text(
                            'Select a day and update its menu. The override applies only for that single day and reverts to the weekly menu automatically.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Day picker
                          const Text(
                            'Select Day to Override',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDayPicker(),
                          const SizedBox(height: 12),

                          // Override status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _hasOverrideForSelectedDay
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _hasOverrideForSelectedDay
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hasOverrideForSelectedDay
                                      ? Icons.edit_note
                                      : Icons.info_outline,
                                  size: 18,
                                  color: _hasOverrideForSelectedDay
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _hasOverrideForSelectedDay
                                        ? '$dayLabel has a custom override. Editing override menu.'
                                        : '$dayLabel is using the default weekly menu. Save to create an override.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _hasOverrideForSelectedDay
                                          ? Colors.orange[800]
                                          : Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Menu fields per plan
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
                          }),

                          // Save button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveMenu,
                              icon: const Icon(Icons.save),
                              label: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Save $dayLabel Override',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          // Remove override button (only shown when override exists)
                          if (_hasOverrideForSelectedDay) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isLoading ? null : _removeOverride,
                                icon: const Icon(Icons.restore,
                                    color: Colors.red),
                                label: Text(
                                  'Remove $dayLabel Override (Revert to Weekly)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
