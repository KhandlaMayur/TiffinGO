import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'seller_dashboard_screen.dart';

class SellerServiceFormScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhone;

  const SellerServiceFormScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhone,
  });

  @override
  State<SellerServiceFormScreen> createState() =>
      _SellerServiceFormScreenState();
}

class _SellerServiceFormScreenState extends State<SellerServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _timeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _rangeController = TextEditingController();
  final _locationController = TextEditingController(); // New for location

  bool _jainVeg = false;
  bool _isLoading = false;
  bool _isInitializing = true;

  // Fixed tiffin type categories that the app supports.
  // The value is the internal `planId` used across menu and pricing.
  final List<Map<String, String>> _availableTypes = [
    {'id': 'normal', 'label': 'Normal Tiffin'},
    {'id': 'premium', 'label': 'Premium Tiffin'},
    {'id': 'deluxe', 'label': 'Deluxe Tiffin'},
    {'id': 'gym_diet', 'label': 'Gym / Diet Tiffin'},
  ];

  final Set<String> _selectedTypeIds = {};

  @override
  void initState() {
    super.initState();
    _mobileController.text = widget.userPhone ?? '';
    _loadExistingService();
  }

  Future<void> _loadExistingService() async {
    final doc = await FirebaseFirestore.instance
        .collection('tiffin_services')
        .doc(widget.userId)
        .get();

    if (!doc.exists) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      return;
    }

    final data = doc.data() ?? {};
    _serviceNameController.text = data['serviceName'] as String? ?? '';
    _addressController.text = data['address'] as String? ?? '';
    _timeController.text = data['availableTime'] as String? ?? '';
    _mobileController.text =
        data['mobile'] as String? ?? widget.userPhone ?? '';
    _rangeController.text = (data['serviceRangeKm'] != null)
        ? data['serviceRangeKm'].toString()
        : '';

    _jainVeg = data['jainVeg'] as bool? ?? false;

    final types = (data['tiffinTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    _selectedTypeIds
      ..clear()
      ..addAll(types);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _addressController.dispose();
    _timeController.dispose();
    _mobileController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTypeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tiffin type.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.userId);

      await docRef.set({
        'ownerId': widget.userId,
        'ownerName': widget.userName,
        'serviceName': _serviceNameController.text.trim(),
        'address': _addressController.text.trim(),
        'availableTime': _timeController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'jainVeg': _jainVeg,
        'serviceRangeKm': double.tryParse(_rangeController.text.trim()) ?? 0.0,
        'tiffinTypes': _selectedTypeIds.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service saved. Welcome to your dashboard!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SellerDashboardScreen(
            serviceId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save service: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Your Tiffin Service'),
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Tiffin Service'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hello, ${widget.userName.isNotEmpty ? widget.userName : 'Seller'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us about your tiffin service. This will help customers find you.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(
                    labelText: 'Tiffin Service Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your service name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address / Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Available Time (e.g., 8AM - 2PM)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the available time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rangeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Serviceable Range (km)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter serviceable range';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Jain / Veg option'),
                    const Spacer(),
                    Switch(
                      value: _jainVeg,
                      onChanged: (value) {
                        setState(() {
                          _jainVeg = value;
                        });
                      },
                    ),
                    Text(_jainVeg ? 'Yes' : 'No'),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select Tiffin Types (multiple)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTypes.map((type) {
                    final selected = _selectedTypeIds.contains(type['id']);
                    return FilterChip(
                      label: Text(type['label'] ?? ''),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedTypeIds.add(type['id']!);
                          } else {
                            _selectedTypeIds.remove(type['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save & Continue',
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
