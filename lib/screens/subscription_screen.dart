import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../models/subscription_model.dart';
import 'subscription_invoice_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic>? service; // Optional service to pre-fill

  const SubscriptionScreen({
    super.key,
    this.service,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedSubscriptionType; // 'daily', 'weekly', 'monthly'
  String?
      _selectedCategory; // 'normal', 'premium', 'deluxe', 'gym/diet', 'combo'
  String? _selectedMealType; // 'veg' or 'jain'
  String? _selectedTiffineService; // 'kathiyavadi', 'rajwadi', etc.
  // Meal periods (Breakfast/Lunch/Dinner/Combo) - allow multiple selection
  final Map<String, bool> _selectedMealPeriods = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'combo': false,
  };
  int _quantity = 1; // tiffins per day
  DateTime? _startDate;
  bool _allowPause = false;
  DateTime? _pauseStart;
  DateTime? _pauseEnd;
  bool _autoRenew = true;
  int _extraOrders = 0;
  String _selectedPaymentMethod = 'Online Payment';
  bool _paymentCompleted = false;
  bool _isFirstTimeUser = true; // Check if user is first time
  double _totalPrice = 0.0;

  final List<Map<String, dynamic>> _subscriptionTypes = [
    {'id': 'daily', 'name': 'Daily', 'days': 1, 'discount': 0},
    {'id': 'weekly', 'name': 'Weekly', 'days': 7, 'discount': 10},
    {'id': 'monthly', 'name': 'Monthly', 'days': 30, 'discount': 20},
  ];

  final List<Map<String, dynamic>> _tiffineServices = [
    {'id': 'kathiyavadi', 'name': 'Kathiyavadi Tiffine Service'},
    {'id': 'desi_rotalo', 'name': 'Desi Rotalo Tiffine Service'},
    {'id': 'nani', 'name': 'Nani Tiffine Service'},
    {'id': 'rajwadi', 'name': 'Rajwadi Tiffine Service'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'id': 'normal', 'name': 'Normal Tiffine', 'basePrice': 100},
    {'id': 'premium', 'name': 'Premium Tiffine', 'basePrice': 150},
    {'id': 'deluxe', 'name': 'Deluxe Tiffine', 'basePrice': 200},
    {'id': 'gym/diet', 'name': 'Gym/Diet Tiffine', 'basePrice': 180},
    {'id': 'combo', 'name': 'Combo Tiffine', 'basePrice': 170},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
    });
    _ensurePrefill();
  }

  void _ensurePrefill() {
    if (widget.service != null) {
      final svc = widget.service!;
      setState(() {
        _selectedTiffineService = svc['id']?.toString();
        _selectedCategory = svc['category']?.toString();
        _selectedMealType = svc['mealType']?.toString();
        _calculateTotal();
      });
    }
  }

  Future<void> _launchUpi(String uriString) async {
    final uri = Uri.parse(uriString);
    // Try launching directly; some devices may not report canLaunchUrl correctly
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Wait a moment then show success message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Opened UPI app. Complete the payment to get your unique code.'),
          duration: Duration(seconds: 3),
        ));
      }
      return;
    } catch (e) {
      debugPrint('Direct launch error: $e');
    }

    // fallback: try canLaunchUrl then launch
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Opened UPI app. Complete the payment to get your unique code.'),
            duration: Duration(seconds: 3),
          ));
        }
        return;
      }
    } catch (e) {
      debugPrint('CanLaunchUrl error: $e');
    }

    if (!mounted) return;

    final storeUri = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/search?q=upi&c=apps')
        : Uri.parse('https://apps.apple.com/search?term=upi');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Issue'),
        content: const Text(
            'If you see "limit exceeded" or "transaction failed":\n\n• Check if your bank\'s daily/monthly UPI limit is reached\n• Verify you have sufficient balance\n• Try a different UPI app (Google Pay, PhonePe, etc)\n• Contact your bank for UPI limits\n\nYou can also copy the UPI link and paste it into your preferred UPI app manually.'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: uriString));
              Navigator.pop(ctx);
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('UPI link copied to clipboard'),
                    duration: Duration(seconds: 2)));
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await launchUrl(storeUri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('Find UPI App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _checkFirstTimeUser() {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    setState(() {
      _isFirstTimeUser = subscriptionProvider.subscriptionHistory.isEmpty;
    });
  }

  void _calculateTotal() {
    if (_selectedSubscriptionType == null ||
        _selectedCategory == null ||
        _selectedMealType == null) {
      _totalPrice = 0.0;
      return;
    }

    final subscription = _subscriptionTypes.firstWhere(
      (sub) => sub['id'] == _selectedSubscriptionType,
    );
    final category = _categories.firstWhere(
      (cat) => cat['id'] == _selectedCategory,
    );

    double basePrice = category['basePrice'].toDouble();
    if (_selectedMealType == 'jain') {
      basePrice += 10; // Jain meals cost 10 more
    }

    double price = basePrice * subscription['days'];

    // multiply by quantity per day
    price = price * _quantity;

    // add extra orders (charged at basePrice each)
    price += (_extraOrders * basePrice);

    // Apply subscription discount
    price = price * (1 - subscription['discount'] / 100);

    // Apply first-time user discount
    if (_isFirstTimeUser) {
      price = price * 0.9; // 10% discount for first-time users
    }

    setState(() {
      _totalPrice = price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _buildQuickOrderButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First-time user banner
            if (_isFirstTimeUser)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'First-time user discount: 10% off!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Active subscription summary (if any)
            Consumer<SubscriptionProvider>(
              builder: (context, subscriptionProvider, child) {
                final active = subscriptionProvider.activeSubscription;
                if (active == null) return const SizedBox.shrink();

                // Check if remaining orders = 0 and show dialog
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (active.remainingOrders == 0 && active.isActive) {
                    _showSubscriptionExpiredDialog(
                        context, subscriptionProvider, active.id);
                  }
                });

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Subscription',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Remaining orders: ${active.remainingOrders}'),
                              const SizedBox(height: 6),
                              Text(
                                  'Pending: ₹${active.pendingAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  'Expires: ${active.endDate.day}/${active.endDate.month}/${active.endDate.year}'),
                              const SizedBox(height: 6),
                              Text(
                                  active.paymentCompleted
                                      ? 'Paid'
                                      : 'Payment Pending',
                                  style: TextStyle(
                                      color: active.paymentCompleted
                                          ? Colors.green
                                          : Colors.red)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                final sub = active;
                                if (sub != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubscriptionInvoiceScreen(
                                          subscription: sub),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                minimumSize: const Size(0, 40),
                              ),
                              icon: const Icon(Icons.receipt_long, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('View Invoice',
                                    style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () async {
                                // Place order using subscription (decrement remainingOrders)
                                if (active.remainingOrders > 0) {
                                  await subscriptionProvider
                                      .decrementRemainingOrders(active.id);
                                  // Sync with Firestore if unique code exists
                                  if (active.uniqueCode != null &&
                                      active.uniqueCode!.isNotEmpty) {
                                    await _syncRemainingUsesWithFirestore(
                                        active.uniqueCode!);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Order placed! Remaining orders decreased by 1')),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'No remaining orders available'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                minimumSize: const Size(0, 40),
                              ),
                              icon: const Icon(Icons.shopping_cart, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Place Order',
                                    style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () async {
                                await subscriptionProvider
                                    .cancelSubscription(active.id);
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Subscription cancelled')));
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                minimumSize: const Size(0, 40),
                              ),
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Cancel',
                                    style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tiffine Service Selection (choose service first)
            const Text(
              'Select Tiffine Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            _buildTiffineServiceDropdown(),
            const SizedBox(height: 24),

            // Subscription Type Selection (Dropdown) - shown after service selected
            if (_selectedTiffineService != null) ...[
              const Text(
                'Select Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              _buildSubscriptionTypeDropdown(),
              const SizedBox(height: 24),
            ],

            // Meal Type Selection
            if (_selectedSubscriptionType != null) ...[
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
            ],

            // Category Selection (Dropdown)
            if (_selectedMealType != null) ...[
              const Text(
                'Select Tiffine Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
            ],

            // Additional subscription options (meal periods, quantity, start date, extra orders)
            if (_selectedCategory != null) ...[
              _buildMealPeriodChips(),
              const SizedBox(height: 16),
              _buildQuantitySelector(),
              const SizedBox(height: 16),
              _buildStartDatePicker(),
              const SizedBox(height: 12),
              _buildAutoRenewToggle(),
              const SizedBox(height: 12),
              _buildPauseToggle(),
              const SizedBox(height: 12),
              _buildExtraOrdersSection(),
              const SizedBox(height: 16),
            ],

            // Payment Section
            if (_totalPrice > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
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
              const SizedBox(height: 24),
              _buildPaymentMethodSelection(),
              const SizedBox(height: 24),

              // QR Code Section
              if (_selectedPaymentMethod == 'Online Payment')
                _buildQRCodeSection(),

              // Confirm Subscription Button (opens UPI if not already paid)
              _buildConfirmSubscriptionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOrderButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _extraOrders++;
          _calculateTotal();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Quick extra tiffin ordered (added to extras)')));
      },
      icon: const Icon(Icons.flash_on),
      label: const Text('Quick Order'),
      backgroundColor: const Color.fromARGB(255, 76, 175, 80),
    );
  }

  Widget _buildSubscriptionTypeDropdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E3A8A),
              width: 2,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubscriptionType,
              hint: const Text(
                'Select Subscription Type',
                style: TextStyle(color: Colors.grey),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF1E3A8A),
                size: 28,
              ),
              items: _subscriptionTypes.map((subscription) {
                return DropdownMenuItem<String>(
                  value: subscription['id'],
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subscription['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (subscription['discount'] > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${subscription['discount']}% off',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSubscriptionType = value;
                    _selectedCategory = null;
                    _selectedMealType = null;
                    _calculateTotal();
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedMealType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealType = value;
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

  Widget _buildCategoryDropdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E3A8A),
              width: 2,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text(
                'Select Tiffine Category',
                style: TextStyle(color: Colors.grey),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF1E3A8A),
                size: 28,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${category['basePrice']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _calculateTotal();
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        // For subscriptions we allow only online payment
        _buildPaymentOption('Online Payment', Icons.payment),
      ],
    );
  }

  Widget _buildMealPeriodChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Meal Period(s)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedMealPeriods.keys.map((key) {
            final label = key[0].toUpperCase() + key.substring(1);
            final isSelected = _selectedMealPeriods[key]!;
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedMealPeriods[key] = val;
                  _calculateTotal();
                });
              },
              selectedColor: const Color(0xFF1E3A8A),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity per day',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_quantity > 1) _quantity--;
                    _calculateTotal();
                  });
                },
                icon: const Icon(Icons.remove),
              ),
              Text('$_quantity', style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: () {
                  setState(() {
                    _quantity++;
                    _calculateTotal();
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      _calculateTotal();
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    _startDate == null
                        ? 'Select Start Date'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                    style: TextStyle(
                        color: _startDate == null ? Colors.grey : Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoRenewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Auto-renew',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        Switch(
          value: _autoRenew,
          activeColor: const Color(0xFF1E3A8A),
          onChanged: (val) {
            setState(() {
              _autoRenew = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPauseToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Allow Pause / Skip Days',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            Switch(
              value: _allowPause,
              activeColor: const Color(0xFF1E3A8A),
              onChanged: (val) {
                setState(() {
                  _allowPause = val;
                  if (!val) {
                    _pauseStart = null;
                    _pauseEnd = null;
                  }
                });
              },
            ),
          ],
        ),
        if (_allowPause) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _pauseStart ?? now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _pauseStart = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(_pauseStart == null
                        ? 'Pause Start'
                        : '${_pauseStart!.day}/${_pauseStart!.month}/${_pauseStart!.year}'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _pauseEnd ?? now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _pauseEnd = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(_pauseEnd == null
                        ? 'Pause End'
                        : '${_pauseEnd!.day}/${_pauseEnd!.month}/${_pauseEnd!.year}'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExtraOrdersSection() {
    return Row(
      children: [
        const Text(
          'Extra orders',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_extraOrders > 0) _extraOrders--;
                    _calculateTotal();
                  });
                },
                icon: const Icon(Icons.remove),
              ),
              Text('$_extraOrders', style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: () {
                  setState(() {
                    _extraOrders++;
                    _calculateTotal();
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
          _paymentCompleted = false;
        });
      },
      child: Container(
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
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
            ),
            const SizedBox(width: 6),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E3A8A)),
      ),
      child: Column(
        children: [
          const Text(
            'Scan QR Code to Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          // Build a UPI deep-link using the provided UPI id
          Builder(builder: (context) {
            const upiId = 'khandlamayur62@okaxis';
            final upiAmount = _totalPrice.toStringAsFixed(2);

            // Validate amount is reasonable
            if (_totalPrice <= 0) {
              return Column(
                children: [
                  const Text(
                      'Invalid amount. Please check your subscription details.',
                      style: TextStyle(color: Colors.red)),
                ],
              );
            }

            final upiNote = Uri.encodeComponent('Subscription Payment');
            final upiName =
                Uri.encodeComponent(widget.service?['name'] ?? 'Tiffin');
            final upiUriString =
                'upi://pay?pa=$upiId&pn=$upiName&tn=$upiNote&am=$upiAmount&cu=INR&tr=SUB${DateTime.now().millisecondsSinceEpoch}';

            return Column(
              children: [
                QrImageView(
                  data: upiUriString,
                  version: QrVersions.auto,
                  size: 200,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _launchUpi(upiUriString);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open UPI app'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Amount: ₹$upiAmount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfirmSubscriptionButton() {
    return ElevatedButton(
      onPressed: () async {
        // If online payment, show UPI flow first
        if (_selectedPaymentMethod == 'Online Payment') {
          await _showUpiPaymentConfirmation();
        } else {
          // For other payment methods, directly confirm
          _confirmSubscription();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle),
          SizedBox(width: 8),
          Text(
            'Confirm Subscription',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpiPaymentConfirmation() async {
    // Build UPI URI
    const upiId = 'khandlamayur62@okaxis';
    final upiAmount = _totalPrice.toStringAsFixed(2);
    final upiNote = Uri.encodeComponent('Subscription Payment');
    final upiName = Uri.encodeComponent(widget.service?['name'] ?? 'Tiffin');
    final upiUriString =
        'upi://pay?pa=$upiId&pn=$upiName&tn=$upiNote&am=$upiAmount&cu=INR';

    // Launch UPI app
    await _launchUpi(upiUriString);

    // Show confirmation dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text(
            'Have you completed the UPI payment?\n\n'
            'Please confirm only after successful payment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _paymentCompleted = true;
                });
                _confirmSubscription();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Yes, Paid'),
            ),
          ],
        ),
      );
    }
  }

  void _confirmSubscription() {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final subscription = _subscriptionTypes.firstWhere(
      (sub) => sub['id'] == _selectedSubscriptionType,
    );
    final startDate = _startDate ?? DateTime.now();
    final endDate = startDate.add(Duration(days: subscription['days']));

    final selectedPeriods = _selectedMealPeriods.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final periodsCount =
        selectedPeriods.isNotEmpty ? selectedPeriods.length : 1;
    final daysCount = (subscription['days'] as int);
    final allowedUses = daysCount * periodsCount;

    final subscriptionModel = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authProvider.currentUser?.contact ?? 'user',
      subscriptionType: _selectedSubscriptionType!,
      category: _selectedCategory!,
      tiffineService: _selectedTiffineService,
      mealType: _selectedMealType,
      startDate: startDate,
      endDate: endDate,
      amount: _totalPrice,
      isActive: true,
      paymentMethod: _selectedPaymentMethod,
      paymentCompleted: _paymentCompleted,
      quantityPerDay: _quantity,
      mealPeriods: selectedPeriods,
      extraOrders: _extraOrders,
      remainingOrders: allowedUses,
      pendingAmount: _paymentCompleted ? 0.0 : _totalPrice,
      autoRenew: _autoRenew,
      pauseStart: _pauseStart,
      pauseEnd: _pauseEnd,
    );

    subscriptionProvider.addSubscription(subscriptionModel);

    // Generate a unique 6-digit code for this subscription and store in Firestore
    _generateAndStoreSubscriptionCode(subscriptionModel, selectedPeriods.length)
        .then((codeData) async {
      if (codeData != null) {
        // update local subscription with unique code
        final updatedSub = SubscriptionModel(
          id: subscriptionModel.id,
          userId: subscriptionModel.userId,
          subscriptionType: subscriptionModel.subscriptionType,
          category: subscriptionModel.category,
          tiffineService: subscriptionModel.tiffineService,
          mealType: subscriptionModel.mealType,
          startDate: subscriptionModel.startDate,
          endDate: subscriptionModel.endDate,
          amount: subscriptionModel.amount,
          isActive: subscriptionModel.isActive,
          paymentMethod: subscriptionModel.paymentMethod,
          paymentCompleted: subscriptionModel.paymentCompleted,
          quantityPerDay: subscriptionModel.quantityPerDay,
          mealPeriods: subscriptionModel.mealPeriods,
          extraOrders: subscriptionModel.extraOrders,
          remainingOrders: subscriptionModel.remainingOrders,
          pendingAmount: subscriptionModel.pendingAmount,
          autoRenew: subscriptionModel.autoRenew,
          pauseStart: subscriptionModel.pauseStart,
          pauseEnd: subscriptionModel.pauseEnd,
          uniqueCode: codeData['code'],
        );
        await subscriptionProvider.updateSubscription(updatedSub);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Subscription Purchased'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your subscription was purchased successfully.'),
                const SizedBox(height: 12),
                Text('Unique Code: ${codeData['code']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Allowed uses: ${codeData['allowedUses']}'),
                const SizedBox(height: 8),
                const Text(
                    'Share this code for free orders until uses are exhausted.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: codeData['code'].toString()));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                },
                child: const Text('Copy Code'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription purchased (no code generated).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).whenComplete(() {
      Navigator.pop(context);
    });
  }

  Future<Map<String, dynamic>?> _generateAndStoreSubscriptionCode(
      SubscriptionModel subscription, int selectedPeriodsCount) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Compute allowed uses: subscription.days * selectedPeriodsCount
      final subInfo = _subscriptionTypes
          .firstWhere((s) => s['id'] == subscription.subscriptionType);
      final days = (subInfo['days'] as int);
      final periods = selectedPeriodsCount > 0 ? selectedPeriodsCount : 1;
      final allowedUses = days * periods;

      // Try generating a unique 6-digit code (avoid collisions)
      String? code;
      const maxAttempts = 8;
      final rand = Random.secure();
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final candidate = (100000 + rand.nextInt(900000)).toString();
        final doc = await firestore
            .collection('subscription_codes')
            .doc(candidate)
            .get();
        if (!doc.exists) {
          code = candidate;
          break;
        }
      }

      if (code == null) {
        final fallback =
            (DateTime.now().millisecondsSinceEpoch % 900000 + 100000)
                .toString();
        code = fallback;
      }

      final userId = fb.FirebaseAuth.instance.currentUser?.uid ??
          Provider.of<AuthProvider>(context, listen: false)
              .currentUser
              ?.contact ??
          'anonymous';

      final codeData = {
        'code': code,
        'subscriptionId': subscription.id,
        'userId': userId,
        'allowedUses': allowedUses,
        'remainingUses': allowedUses,
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': subscription.endDate.toIso8601String(),
        'isActive': true,
        // Restrict code to this combination so it cannot be used for others
        'tiffineServiceId': subscription.tiffineService,
        'categoryId': subscription.category,
        'mealType': subscription.mealType,
      };

      await firestore.collection('subscription_codes').doc(code).set(codeData);

      return codeData;
    } catch (e) {
      return null;
    }
  }

  Widget _buildTiffineServiceDropdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E3A8A),
              width: 2,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTiffineService,
              hint: const Text(
                'Select Tiffine Service',
                style: TextStyle(color: Colors.grey),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF1E3A8A),
                size: 28,
              ),
              items: _tiffineServices.map((service) {
                return DropdownMenuItem<String>(
                  value: service['id'],
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      service['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTiffineService = value;
                    _calculateTotal();
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncRemainingUsesWithFirestore(String uniqueCode) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('subscription_codes').doc(uniqueCode);
      final doc = await docRef.get();

      if (doc.exists) {
        final remainingUses = (doc['remainingUses'] as int?) ?? 0;
        if (remainingUses > 0) {
          await docRef.update({'remainingUses': remainingUses - 1});
        }
      }
    } catch (e) {
      debugPrint('Error syncing remainingUses with Firestore: $e');
    }
  }

  void _showSubscriptionExpiredDialog(BuildContext context,
      SubscriptionProvider provider, String subscriptionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Subscription Completed'),
        content: const Text(
          'All remaining orders have been used. Would you like to purchase a new subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.cancelSubscription(subscriptionId);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedSubscriptionType = null;
                _selectedCategory = null;
                _selectedMealType = null;
                _selectedTiffineService = null;
                _quantity = 1;
                _extraOrders = 0;
                _totalPrice = 0.0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase New'),
          ),
        ],
      ),
    );
  }
}
