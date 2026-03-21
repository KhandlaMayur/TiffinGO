import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'dart:math' show sin, cos, atan2, sqrt, pi;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../providers/order_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/firestore_order_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/order_model.dart';
import '../services/tomtom_routing_service.dart';
import 'advanced_delivery_tracking_screen.dart';

class PaymentDeliveryScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentDeliveryScreen({
    super.key,
    required this.order,
  });

  @override
  State<PaymentDeliveryScreen> createState() => _PaymentDeliveryScreenState();
}

class _PaymentDeliveryScreenState extends State<PaymentDeliveryScreen> {
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _paymentCompleted = false;
  final TextEditingController _uniqueCodeController = TextEditingController();
  bool _uniqueCodeApplied = false;
  String? _appliedCode;
  double _deliveryCharge = 0.0;
  Position? _currentPosition;
  String _selectedAddress = '';
  bool _useCurrentLocation = true;
  final TextEditingController _otherAddressController = TextEditingController();

  // GST and Delivery Charge Calculation Constants
  static const double GST_RATE = 0.18; // 18% GST
  static const double PER_KM_CHARGE = 5.0; // 5 rupees per kilometer

  // Service location will be fetched from Firestore
  double? _serviceLatitude;
  double? _serviceLongitude;
  double? _serviceRangeKm; // Seller's serviceable range

  double _gstAmount = 0.0;
  double _distanceInKm = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchServiceLocation();
    _calculateFinalAmount();
    _getCurrentLocation();
  }

  // Fetch the tiffin service location from Firestore
  Future<void> _fetchServiceLocation() async {
    try {
      debugPrint(
          '🔍 Fetching location for service: ${widget.order.serviceName} (ID: ${widget.order.serviceId})');

      // Try fetching using serviceId first (preferred)
      if (widget.order.serviceId != null &&
          widget.order.serviceId!.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('tiffin_services')
            .doc(widget.order.serviceId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          double? lat = (data?['latitude'] as num?)?.toDouble();
          double? lng = (data?['longitude'] as num?)?.toDouble();

          // If latitude/longitude is missing, fallback to geocoding the address
          if ((lat == null || lng == null) && data?['address'] != null) {
            String addressStr = data!['address'] as String;
            if (addressStr.trim().isNotEmpty) {
              try {
                final locations = await locationFromAddress(addressStr);
                if (locations.isNotEmpty) {
                  lat = locations.first.latitude;
                  lng = locations.first.longitude;
                  debugPrint('✅ Geocoded address: Lat=$lat, Lng=$lng');
                }
              } catch (e) {
                debugPrint('❌ Geocoding error for address "$addressStr": $e');
              }
            }
          }

          if (lat != null && lng != null) {
            debugPrint('✅ Found by serviceId: Lat=$lat, Lng=$lng');

            setState(() {
              _serviceLatitude = lat;
              _serviceLongitude = lng;
              _serviceRangeKm = (data?['serviceRangeKm'] as num?)?.toDouble();
            });

            // Recalculate distance if location is already available
            if (_currentPosition != null) {
              _recalculateDeliveryCharge();
            }
            return;
          } else {
            debugPrint('⚠️ Falling back since coordinates still missing.');
          }
        } else {
          debugPrint(
              '❌ Document not found for serviceId: ${widget.order.serviceId}');
        }
      }

      // Fallback: fetch by service name
      debugPrint('🔎 Searching by service name: ${widget.order.serviceName}');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tiffin_services')
          .where('name', isEqualTo: widget.order.serviceName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        double? lat = (data['latitude'] as num?)?.toDouble();
        double? lng = (data['longitude'] as num?)?.toDouble();

        if ((lat == null || lng == null) && data['address'] != null) {
          String addressStr = data['address'] as String;
          if (addressStr.trim().isNotEmpty) {
            try {
              final locations = await locationFromAddress(addressStr);
              if (locations.isNotEmpty) {
                lat = locations.first.latitude;
                lng = locations.first.longitude;
              }
            } catch (e) {
              // Ignore
            }
          }
        }

        if (lat != null && lng != null) {
          debugPrint('✅ Found by name: Lat=$lat, Lng=$lng');

          setState(() {
            _serviceLatitude = lat;
            _serviceLongitude = lng;
            _serviceRangeKm = (querySnapshot.docs.first.data()['serviceRangeKm'] as num?)?.toDouble();
          });

          // Recalculate distance if location is already available
          if (_currentPosition != null) {
            _recalculateDeliveryCharge();
          }
        } else {
          debugPrint('⚠️ Falling back since coordinates still missing.');
        }
      } else {
        debugPrint(
            '❌ No documents found for service name: ${widget.order.serviceName}');
        debugPrint('⚠️ Missing service location');
      }
    } catch (e) {
      debugPrint('❌ Error fetching service location: $e');
    }
  }

  // Recalculate delivery charge — uses TomTom road distance for accuracy.
  // Falls back to Haversine if TomTom is unavailable.
  Future<void> _recalculateDeliveryCharge() async {
    if (_serviceLatitude == null ||
        _serviceLongitude == null ||
        _currentPosition == null) {
      debugPrint('⚠️ Cannot calculate: Missing coordinates');
      return;
    }

    // --- Try TomTom road distance first ---
    double roadDistanceKm = 0.0;
    try {
      final route = await TomTomRoutingService.getRoute(
        startLat: _serviceLatitude!,
        startLng: _serviceLongitude!,
        endLat: _currentPosition!.latitude,
        endLng: _currentPosition!.longitude,
      );
      if (route != null) {
        roadDistanceKm = route.distanceInKm;
        debugPrint('🛣️ TomTom road distance: $roadDistanceKm km');
      }
    } catch (e) {
      debugPrint('⚠️ TomTom call failed, falling back to Haversine: $e');
    }

    // --- Fallback: Haversine straight-line ---
    if (roadDistanceKm == 0.0) {
      roadDistanceKm = _haversineKm(
        _serviceLatitude!,
        _serviceLongitude!,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      debugPrint('📐 Haversine fallback distance: $roadDistanceKm km');
    }

    if (!mounted) return;
    setState(() {
      _distanceInKm = roadDistanceKm;
      debugPrint('📍 Final distance used for billing: $_distanceInKm km');

      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      final hasActiveSubscriptionForCurrentService = subscriptionProvider
          .hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);

      if (hasActiveSubscriptionForCurrentService) {
        _deliveryCharge = 0.0;
        debugPrint('✅ Delivery: FREE (Subscriber)');
      } else {
        _deliveryCharge = _calculateDeliveryCharge(_distanceInKm);
        debugPrint('💰 Delivery charge: ₹$_deliveryCharge ($_distanceInKm km × ₹5/km)');
      }
    });
  }

  /// Haversine formula – straight-line distance in km (fallback only).
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
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
          content: Text('Opened UPI app. Complete the payment.'),
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
            content: Text('Opened UPI app. Complete the payment.'),
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
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('UPI link copied to clipboard'),
                    duration: Duration(seconds: 2)));
              }
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
              setState(() {
                _selectedPaymentMethod = 'Cash on Delivery';
              });
            },
            child: const Text('Use Other Method'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otherAddressController.dispose();
    _uniqueCodeController.dispose();
    super.dispose();
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final double dLat = (lat2 - lat1) * (3.14159265359 / 180.0);
    final double dLon = (lon2 - lon1) * (3.14159265359 / 180.0);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * (3.14159265359 / 180.0)) *
            cos(lat2 * (3.14159265359 / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distanceKm = earthRadiusKm * c;

    return distanceKm;
  }

  // Calculate delivery charge based on distance (5 rupees per km)
  double _calculateDeliveryCharge(double distanceKm) {
    // Only per km charge, no base charge
    return distanceKm * PER_KM_CHARGE;
  }

  // Calculate GST amount
  double _calculateGST(double amount) {
    return amount * GST_RATE;
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('📍 Requesting user location...');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      debugPrint(
          '✅ User location: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
      });

      // Try to calculate distance if service location is available
      if (_serviceLatitude != null && _serviceLongitude != null) {
        debugPrint('✅ Service location available, calculating distance...');
        _recalculateDeliveryCharge();
      } else {
        debugPrint(
            '⏳ Service location not yet loaded, will calculate when available');
      }

      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _selectedAddress =
                '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.postalCode ?? ''}';
          });
        }
      } catch (e) {
        // ignore reverse geocode errors
      }
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
    }
  }

  void _calculateFinalAmount() {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final hasActiveSubscriptionForCurrentService = subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);

    if (hasActiveSubscriptionForCurrentService) {
      _deliveryCharge = 0.0; // Free delivery for subscribers
      _gstAmount = 0.0;      // Zero GST for existing subscribers
    } else {
      // Use calculated delivery charge based on distance, or default if no location
      if (_distanceInKm > 0) {
        _deliveryCharge = _calculateDeliveryCharge(_distanceInKm);
      } else {
        _deliveryCharge = 0.0; // No delivery charge if location not available
      }
      // Calculate GST on meal amount for non-subscribers
      _gstAmount = _calculateGST(widget.order.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment & Delivery'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Summary
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // Delivery Location Selection
          _buildDeliveryLocationSelection(),
          const SizedBox(height: 16),

          // Payment Method Selection
          _buildPaymentMethodSelection(),
          const SizedBox(height: 24),

          // Unique Code Entry (if selected)
          _buildUniqueCodeEntry(),

          // Confirm button for Unique Code method (appears after applying code)
          if (_selectedPaymentMethod == 'Unique Code' &&
              _uniqueCodeApplied &&
              !_paymentCompleted)
            _buildUniqueCodeConfirmButton(orderProvider),

          // ── Out-of-range guard: hide payment/confirm buttons ──────────────
          if (_serviceRangeKm != null && _serviceRangeKm! > 0 && _distanceInKm > _serviceRangeKm!) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Center(
                child: Text(
                  '🚫 Ordering unavailable — outside delivery range',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[ 
            // Payment QR Code (if online)
            if (_selectedPaymentMethod == 'Online Payment' && !_paymentCompleted)
              _buildQRCodeSection(),

            // Confirm Order Button (for online payment)
            if (_selectedPaymentMethod == 'Online Payment' && !_paymentCompleted)
              _buildOnlineConfirmButton(orderProvider),

            // Track Delivery Button
            if (_paymentCompleted) _buildTrackDeliveryButton(orderProvider),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E3A8A)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          _buildSummaryRow('Service', widget.order.serviceName),
          _buildSummaryRow('Meal Type', widget.order.mealType.toUpperCase()),
          _buildSummaryRow('Meal Plan', widget.order.mealPlan),
          _buildSummaryRow('Subscription', widget.order.subscription),
          if (widget.order.extraFood.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Extra Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...widget.order.extraFood.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $item'),
                )),
          ],
          const Divider(),
          _buildSummaryRow(
              'Meal Amount', '₹${widget.order.amount.toStringAsFixed(2)}'),

          // Out-of-range warning
          if (_serviceRangeKm != null && _serviceRangeKm! > 0 && _distanceInKm > _serviceRangeKm!)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delivery not possible — you are ${_distanceInKm.toStringAsFixed(1)} km away. '
                      'This service delivers only within ${_serviceRangeKm!.toInt()} km.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // GST Section (Only compute separately if not zero)
          if (_gstAmount > 0) ...[
            _buildSummaryRow(
              'SGST (9%)',
              '₹${(_gstAmount / 2).toStringAsFixed(2)}',
              color: Colors.orange,
            ),
            _buildSummaryRow(
              'CGST (9%)',
              '₹${(_gstAmount / 2).toStringAsFixed(2)}',
              color: Colors.orange,
            ),
          ],

          // Delivery Charge with Distance Info
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              final hasActiveSubscriptionForCurrentService =
                  subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);

              String deliveryChargeText;
              Color? deliveryChargeColor;

              if (hasActiveSubscriptionForCurrentService) {
                deliveryChargeText = 'FREE (Subscribed)';
                deliveryChargeColor = Colors.green;
              } else {
                deliveryChargeText = _distanceInKm > 0
                    ? '₹${_deliveryCharge.toStringAsFixed(2)} (${_distanceInKm.toStringAsFixed(1)} km)'
                    : '₹${_deliveryCharge.toStringAsFixed(2)}';
                deliveryChargeColor = null;
              }

              return _buildSummaryRow(
                'Delivery Charge',
                deliveryChargeText,
                color: deliveryChargeColor,
              );
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  final hasActiveSubscriptionForCurrentService =
                      subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);
                  double mealWithGST = widget.order.amount + _gstAmount;
                  double finalAmount = mealWithGST +
                      (hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge);
                  if (_uniqueCodeApplied) finalAmount = 0.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${finalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (_uniqueCodeApplied && _appliedCode != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Applied code: $_appliedCode',
                              style: const TextStyle(
                                  color: Colors.green, fontSize: 12)),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1E3A8A)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          RadioListTile<bool>(
            value: true,
            groupValue: _useCurrentLocation,
            onChanged: (v) async {
              if (v == null) return;
              setState(() {
                _useCurrentLocation = v;
              });
              if (v) {
                await _getCurrentLocation();
                // Wait a moment for service location to be fetched if not already available
                if (_serviceLatitude == null || _serviceLongitude == null) {
                  debugPrint('⏳ Waiting for service location to be fetched...');
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (_serviceLatitude != null &&
                      _serviceLongitude != null &&
                      _currentPosition != null) {
                    _recalculateDeliveryCharge();
                  }
                }
              }
            },
            title: const Text('Use current location'),
            subtitle: _selectedAddress.isNotEmpty
                ? Text(_selectedAddress)
                : const Text('Detecting current address...'),
            secondary: const Icon(Icons.my_location),
          ),
          const Divider(),
          RadioListTile<bool>(
            value: false,
            groupValue: _useCurrentLocation,
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _useCurrentLocation = v;
              });
            },
            title: const Text('Enter another location'),
            subtitle: !_useCurrentLocation && _selectedAddress.isNotEmpty
                ? Text(_selectedAddress)
                : null,
            secondary: const Icon(Icons.edit_location_alt),
          ),
          const Divider(),
          // Show text field and save button when "Enter another location" is selected
          if (!_useCurrentLocation) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherAddressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter delivery address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final text = _otherAddressController.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        _selectedAddress = text;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Address',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPaymentMethod,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: <String>[
                'Cash on Delivery',
                'Online Payment',
                'Unique Code'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Cash on Delivery'
                            ? Icons.money
                            : Icons.payment,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedPaymentMethod = val;
                  _paymentCompleted = false;
                  if (val != 'Unique Code') {
                    _uniqueCodeController.clear();
                    _uniqueCodeApplied = false;
                    _appliedCode = null;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUniqueCodeEntry() {
    if (_selectedPaymentMethod != 'Unique Code') return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _uniqueCodeController,
          decoration: InputDecoration(
            labelText: 'Enter Unique Code',
            prefixIcon: const Icon(Icons.vpn_key),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _uniqueCodeApplied ? null : _applyUniqueCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
              child: const Text('Apply Code'),
            ),
            const SizedBox(width: 12),
            if (_uniqueCodeApplied && _appliedCode != null)
              Text('Applied: $_appliedCode',
                  style: const TextStyle(color: Colors.green)),
          ],
        ),
      ],
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
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              final hasActiveSubscriptionForCurrentService =
                  subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);
              final finalAmount = widget.order.amount +
                  (hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge);

              // Use provided UPI id (from your attached QR/image)
              const upiId = 'khandlamayur62@okaxis';
              final upiAmount = finalAmount.toStringAsFixed(2);

              // Validate amount is reasonable (UPI usually has limits like 100k per transaction)
              if (finalAmount <= 0) {
                return const Text('Invalid amount for payment',
                    style: TextStyle(color: Colors.red));
              }
              if (finalAmount > 100000) {
                return const Text(
                    'Amount exceeds UPI transaction limit (₹1,00,000)',
                    style: TextStyle(color: Colors.red));
              }

              final upiNote =
                  Uri.encodeComponent('Tiffin order ${widget.order.id}');
              final upiName = Uri.encodeComponent(widget.order.serviceName);
              // Add unique reference ID for tracking
              final upiUriString =
                  'upi://pay?pa=$upiId&pn=$upiName&tn=$upiNote&am=$upiAmount&cu=INR&tr=ORD${widget.order.id}';

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
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              final hasActiveSubscriptionForCurrentService =
                  subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);
              final finalAmount = widget.order.amount +
                  (hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge);
              return Text(
                'Amount: ₹${finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _applyUniqueCode() async {
    final code = _uniqueCodeController.text.trim();
    if (code.isEmpty) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('subscription_codes').doc(code);
      final doc = await docRef.get();
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Code not found')));
        }
        return;
      }
      final data = doc.data()!;
      // Validate code is for this exact tiffin service + category + meal type using IDs
      final codeServiceId = data['tiffineServiceId'] as String?;
      final codeCategoryId = data['categoryId'] as String?;
      final codeMealType = data['mealType'] as String?;

      // Check service ID match
      if (codeServiceId != null && codeServiceId != widget.order.serviceId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code not valid for this service')));
        }
        return;
      }
      // Check category ID match
      if (codeCategoryId != null && codeCategoryId != widget.order.categoryId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Code not valid for this meal plan')));
        }
        return;
      }
      // Check meal type match
      if (codeMealType != null && codeMealType != widget.order.mealType) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Code not valid for this meal type')));
        }
        return;
      }

      final remaining = (data['remainingUses'] ?? 0) as int;
      final isActive = data['isActive'] ?? true;
      final expiresAtStr = data['expiresAt'] as String?;
      final expiresAt =
          expiresAtStr != null ? DateTime.parse(expiresAtStr) : null;

      if (!isActive ||
          remaining <= 0 ||
          (expiresAt != null && DateTime.now().isAfter(expiresAt))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code expired or exhausted')));
        }
        return;
      }

      // Atomically decrement remainingUses
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        final current = (snapshot.data()?['remainingUses'] ?? 0) as int;
        if (current <= 0) throw Exception('No remaining uses');
        tx.update(docRef, {'remainingUses': FieldValue.increment(-1)});
        if (current - 1 <= 0) tx.update(docRef, {'isActive': false});
      });

      // Decrement local subscription (if present) so UI reflects change immediately
      try {
        final subscriptionProvider =
            Provider.of<SubscriptionProvider>(context, listen: false);
        var matching;
        try {
          matching = subscriptionProvider.subscriptionHistory
              .firstWhere((s) => s.uniqueCode != null && s.uniqueCode == code);
        } catch (e) {
          matching = null;
        }
        if (matching != null) {
          await subscriptionProvider.decrementRemainingOrders(matching.id);
        }
      } catch (_) {}

      setState(() {
        _uniqueCodeApplied = true;
        _appliedCode = code;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code applied — order will be free')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to apply code: $e')));
      }
    }
  }

  Future<Map<String, String?>> _fetchUserDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'name': null, 'phone': null};
    try {
      final snap = await FirebaseFirestore.instance.collection('user_register').doc(uid).get();
      if (snap.exists) {
        return {
          'name': snap.data()?['name'] as String?,
          'phone': snap.data()?['phone'] as String?,
        };
      }
    } catch (_) {}
    return {'name': null, 'phone': null};
  }

  Widget _buildOnlineConfirmButton(OrderProvider orderProvider) {
    return Container(
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
        onPressed: () async {
          final subscriptionProvider =
              Provider.of<SubscriptionProvider>(context, listen: false);
          final hasActiveSubscriptionForCurrentService =
              subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);
          // Ensure delivery charge (and GST) is included in the final amount.
          // GST is calculated on the meal amount and displayed above.
          final double originalAmount = widget.order.amount + _gstAmount + _deliveryCharge;
          var finalAmount = widget.order.amount +
              _gstAmount +
              (hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge);
          // If unique code is applied, order is free
          if (_uniqueCodeApplied) finalAmount = 0.0;

          final userDetails = await _fetchUserDetails();

          final updatedOrder = OrderModel(
            id: widget.order.id,
            serviceName: widget.order.serviceName,
            serviceId: widget.order.serviceId,
            date: widget.order.date,
            amount: finalAmount,
            originalAmount: originalAmount,
            status: 'Pending',
            userName: userDetails['name'],
            userMobile: userDetails['phone'],
            paymentMethod: _selectedPaymentMethod,
            mealType: widget.order.mealType,
            mealPlan: widget.order.mealPlan,
            categoryId: widget.order.categoryId,
            subscription: widget.order.subscription,
            extraFood: widget.order.extraFood,
            // Build a robust location map: prefer selected address and current GPS,
            // otherwise fall back to existing order location if available.
            location: (() {
              final existingLocation = widget.order.location;
              Map<String, dynamic>? finalLocation;
              if (_selectedAddress.isNotEmpty || _currentPosition != null) {
                finalLocation = {
                  'address': _selectedAddress.isNotEmpty
                      ? _selectedAddress
                      : (existingLocation != null
                          ? (existingLocation['address'] ?? '')
                          : ''),
                  'latitude': _currentPosition?.latitude ??
                      (existingLocation != null
                          ? existingLocation['latitude']
                          : null),
                  'longitude': _currentPosition?.longitude ??
                      (existingLocation != null
                          ? existingLocation['longitude']
                          : null),
                };
              } else {
                finalLocation = existingLocation;
              }
              return finalLocation;
            })(),
            paymentCompleted: true,
            deliveryCharge: hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge,
            distanceInKm: _distanceInKm,
            sellerLocation:
                _serviceLatitude != null && _serviceLongitude != null
                    ? {
                        'latitude': _serviceLatitude,
                        'longitude': _serviceLongitude,
                      }
                    : null,
          );

          // Save locally
          orderProvider.addToOrderHistory(updatedOrder);

          // Also attempt to persist to Firestore (if user authenticated)
          try {
            final fsProvider =
                Provider.of<FirestoreOrderProvider>(context, listen: false);
            final orderMap = updatedOrder.toJson();
            orderMap['userId'] =
                FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
            if (_uniqueCodeApplied && _appliedCode != null) {
              orderMap['appliedUniqueCode'] = _appliedCode;
            }
            await fsProvider.createOrder(orderMap);
            // Successfully saved to Firestore
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to save order to Firestore: $e'),
                backgroundColor: Colors.red,
              ));
            }
          }

          setState(() {
            _paymentCompleted = true;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdvancedDeliveryTrackingScreen(order: updatedOrder),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Confirm Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildUniqueCodeConfirmButton(OrderProvider orderProvider) {
    // Mirrors online confirm but assumes unique code was applied and makes order free
    return Container(
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
        onPressed: () async {
          final subscriptionProvider =
              Provider.of<SubscriptionProvider>(context, listen: false);
          // finalAmount is zero because unique code applied
          final double originalAmount = widget.order.amount + _gstAmount + _deliveryCharge;
          var finalAmount = 0.0;

          final userDetails = await _fetchUserDetails();

          final updatedOrder = OrderModel(
            id: widget.order.id,
            serviceName: widget.order.serviceName,
            date: widget.order.date,
            amount: finalAmount,
            originalAmount: originalAmount,
            status: 'Pending',
            userName: userDetails['name'],
            userMobile: userDetails['phone'],
            paymentMethod: _selectedPaymentMethod,
            mealType: widget.order.mealType,
            mealPlan: widget.order.mealPlan,
            subscription: widget.order.subscription,
            extraFood: widget.order.extraFood,
            // Build a robust location map: prefer selected address and current GPS,
            // otherwise fall back to existing order location if available.
            location: (() {
              final existingLocation = widget.order.location;
              Map<String, dynamic>? finalLocation;
              if (_selectedAddress.isNotEmpty || _currentPosition != null) {
                finalLocation = {
                  'address': _selectedAddress.isNotEmpty
                      ? _selectedAddress
                      : (existingLocation != null
                          ? (existingLocation['address'] ?? '')
                          : ''),
                  'latitude': _currentPosition?.latitude ??
                      (existingLocation != null
                          ? existingLocation['latitude']
                          : null),
                  'longitude': _currentPosition?.longitude ??
                      (existingLocation != null
                          ? existingLocation['longitude']
                          : null),
                };
              } else {
                finalLocation = existingLocation;
              }
              return finalLocation;
            })(),
            paymentCompleted: true,
          );

          // Save locally
          orderProvider.addToOrderHistory(updatedOrder);

          // Persist to Firestore if available
          try {
            final fsProvider =
                Provider.of<FirestoreOrderProvider>(context, listen: false);
            final orderMap = updatedOrder.toJson();
            orderMap['userId'] =
                FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
            if (_uniqueCodeApplied && _appliedCode != null) {
              orderMap['appliedUniqueCode'] = _appliedCode;
            }
            await fsProvider.createOrder(orderMap);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to save order to Firestore: $e'),
                backgroundColor: Colors.red,
              ));
            }
          }

          setState(() {
            _paymentCompleted = true;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdvancedDeliveryTrackingScreen(order: updatedOrder),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Confirm Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTrackDeliveryButton(OrderProvider orderProvider) {
    return ElevatedButton(
      onPressed: () {
        // Update order with payment status
        final subscriptionProvider =
            Provider.of<SubscriptionProvider>(context, listen: false);
        final hasActiveSubscriptionForCurrentService =
            subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);
        final finalAmount = widget.order.amount +
            (hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge);

        final updatedOrder = OrderModel(
          id: widget.order.id,
          serviceName: widget.order.serviceName,
          serviceId: widget.order.serviceId,
          date: widget.order.date,
          amount: finalAmount,
          status: 'Pending',
          paymentMethod: _selectedPaymentMethod,
          mealType: widget.order.mealType,
          mealPlan: widget.order.mealPlan,
          categoryId: widget.order.categoryId,
          subscription: widget.order.subscription,
          extraFood: widget.order.extraFood,
          location: widget.order.location,
          paymentCompleted: true,
          deliveryCharge: hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge,
          distanceInKm: _distanceInKm,
          sellerLocation: _serviceLatitude != null && _serviceLongitude != null
              ? {
                  'latitude': _serviceLatitude,
                  'longitude': _serviceLongitude,
                }
              : null,
        );

        orderProvider.updateOrderStatus(widget.order.id, 'Pending');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AdvancedDeliveryTrackingScreen(order: updatedOrder),
          ),
        );
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
          Icon(Icons.location_on),
          SizedBox(width: 8),
          Text(
            'Track Delivery',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    // Block entirely if outside delivery range
    final bool outOfRange = _serviceRangeKm != null &&
        _serviceRangeKm! > 0 &&
        _distanceInKm > _serviceRangeKm!;
    if (outOfRange) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: null, // disabled
          icon: const Icon(Icons.location_off),
          label: Text(
            'Delivery not available (${_distanceInKm.toStringAsFixed(1)} km > ${_serviceRangeKm!.toInt()} km limit)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade300,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.shade200,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    if (_selectedPaymentMethod == 'Cash on Delivery' && !_paymentCompleted) {
      return Container(
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
          onPressed: () async {
            // Proceed with COD order
            final orderProvider =
                Provider.of<OrderProvider>(context, listen: false);

            final subscriptionProvider =
                Provider.of<SubscriptionProvider>(context, listen: false);
            final hasActiveSubscriptionForCurrentService =
                subscriptionProvider.hasActiveSubscriptionForService(widget.order.serviceId ?? widget.order.serviceName);
            // Ensure GST + delivery charge are included in final amount
            final double originalAmount = widget.order.amount + _gstAmount + _deliveryCharge;
            var finalAmount = widget.order.amount +
                _gstAmount +
                (hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge);
            // If unique code is applied, order is free
            if (_uniqueCodeApplied) finalAmount = 0.0;

            final userDetails = await _fetchUserDetails();

            final updatedOrder = OrderModel(
              id: widget.order.id,
              serviceName: widget.order.serviceName,
              serviceId: widget.order.serviceId,
              date: widget.order.date,
              amount: finalAmount,
              originalAmount: originalAmount,
              status: 'Pending',
              userName: userDetails['name'],
              userMobile: userDetails['phone'],
              paymentMethod: _selectedPaymentMethod,
              mealType: widget.order.mealType,
              mealPlan: widget.order.mealPlan,
              categoryId: widget.order.categoryId,
              subscription: widget.order.subscription,
              extraFood: widget.order.extraFood,
              // Build a robust location map: prefer selected address and current GPS,
              // otherwise fall back to existing order location if available.
              location: (() {
                final existingLocation = widget.order.location;
                Map<String, dynamic>? finalLocation;
                if (_selectedAddress.isNotEmpty || _currentPosition != null) {
                  finalLocation = {
                    'address': _selectedAddress.isNotEmpty
                        ? _selectedAddress
                        : (existingLocation != null
                            ? (existingLocation['address'] ?? '')
                            : ''),
                    'latitude': _currentPosition?.latitude ??
                        (existingLocation != null
                            ? existingLocation['latitude']
                            : null),
                    'longitude': _currentPosition?.longitude ??
                        (existingLocation != null
                            ? existingLocation['longitude']
                            : null),
                  };
                } else {
                  finalLocation = existingLocation;
                }
                return finalLocation;
              })(),
              paymentCompleted: false,
              deliveryCharge: hasActiveSubscriptionForCurrentService ? 0.0 : _deliveryCharge,
              distanceInKm: _distanceInKm,
              sellerLocation:
                  _serviceLatitude != null && _serviceLongitude != null
                      ? {
                          'latitude': _serviceLatitude,
                          'longitude': _serviceLongitude,
                        }
                      : null,
            );

            // Save locally
            orderProvider.addToOrderHistory(updatedOrder);

            // Persist to Firestore if available
            try {
              final fsProvider =
                  Provider.of<FirestoreOrderProvider>(context, listen: false);
              final orderMap = updatedOrder.toJson();
              orderMap['userId'] =
                  FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
              if (_uniqueCodeApplied && _appliedCode != null) {
                orderMap['appliedUniqueCode'] = _appliedCode;
              }
              await fsProvider.createOrder(orderMap);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Failed to save order to Firestore: $e'),
                  backgroundColor: Colors.red,
                ));
              }
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdvancedDeliveryTrackingScreen(order: updatedOrder),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Confirm Order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
