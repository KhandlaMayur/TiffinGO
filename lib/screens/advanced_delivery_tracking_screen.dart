import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/tomtom_routing_service.dart';

class AdvancedDeliveryTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const AdvancedDeliveryTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<AdvancedDeliveryTrackingScreen> createState() =>
      _AdvancedDeliveryTrackingScreenState();
}

class _AdvancedDeliveryTrackingScreenState
    extends State<AdvancedDeliveryTrackingScreen> {
  // Kitchen coordinates for each service
  // Static kitchen coordinates for each service — used as fallback
  static const LatLng _kathiyavadi = LatLng(22.2953, 70.8000);
  static const LatLng _nani = LatLng(22.2964, 70.7903);
  static const LatLng _rajwadi = LatLng(22.3248, 70.7720);
  static const LatLng _desi = LatLng(22.34, 70.80);

  /// Chooses the correct kitchen based on the order's serviceId or name.
  ///
  /// `serviceId` is preferred since it is likely to be a stable identifier;
  /// otherwise the code falls back to checking substrings in the human-readable
  /// `serviceName`.  Defaults to Kathiyavadi if nothing matches.
  LatLng get _selectedKitchen {
    final id = widget.order.serviceId?.toLowerCase();
    if (id != null) {
      if (id.contains('kathiyavadi')) return _kathiyavadi;
      if (id.contains('nani')) return _nani;
      if (id.contains('rajwadi')) return _rajwadi;
      if (id.contains('desi')) return _desi;
    }
    final name = widget.order.serviceName.toLowerCase();
    if (name.contains('kathiyavadi')) return _kathiyavadi;
    if (name.contains('nani')) return _nani;
    if (name.contains('rajwadi')) return _rajwadi;
    if (name.contains('desi')) return _desi;

    return _kathiyavadi; // default
  }

  int _currentStep = 0; // 0: Preparing, 1: Out for Delivery, 2: Delivered

  // Location tracking
  double? _userLat;
  double? _userLng;
  String _locationStatus = 'Fetching location...';
  StreamSubscription<Position>? _positionSub;

  // Route and map data
  TomTomRoute? _route;
  bool _loadingRoute = true;
  late MapController _mapController;
  List<LatLng> _routePoints = [];

  // Rating
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocationAndRoute();
    _simulateDeliveryProgress();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Initialize location tracking and calculate route
  Future<void> _initLocationAndRoute() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateLocation('Location services disabled');
        // Use default location for testing
        if (mounted) {
          setState(() {
            _userLat = 22.3045;
            _userLng = 70.8032;
          });
        }
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _updateLocation('Location permission denied');
          // Use default location for testing
          if (mounted) {
            setState(() {
              _userLat = 22.3045;
              _userLng = 70.8032;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _updateLocation('Location permission permanently denied');
        // Use default location for testing
        if (mounted) {
          setState(() {
            _userLat = 22.3045;
            _userLng = 70.8032;
          });
        }
        return;
      }

      // Get initial position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      _onPositionReceived(pos);

      // Listen to position updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(_onPositionReceived);
    } catch (e) {
      _updateLocation('Error: $e');
      debugPrint('Location init error: $e');
      // Use default location for testing
      if (mounted) {
        setState(() {
          _userLat = 22.3045;
          _userLng = 70.8032;
        });
      }
    }
  }

  /// Handle new position updates
  void _onPositionReceived(Position position) {
    if (!mounted) return;

    setState(() {
      _userLat = position.latitude;
      _userLng = position.longitude;
      _locationStatus =
          'Lat: ${_userLat!.toStringAsFixed(4)}, Lng: ${_userLng!.toStringAsFixed(4)}';
    });

    // Calculate route if we have user location and route not yet calculated
    if (_route == null && _userLat != null && _userLng != null) {
      _calculateRoute();
    }

    // Update map camera to follow user
    if (_userLat != null && _userLng != null) {
      try {
        _mapController.move(
          LatLng(_userLat!, _userLng!),
          14.0, // Default zoom level
        );
      } catch (e) {
        debugPrint('Error moving map: $e');
      }
    }
  }

  /// Update location status text
  void _updateLocation(String status) {
    if (!mounted) return;
    setState(() => _locationStatus = status);
  }

  /// Calculate route from kitchen to user location
  Future<void> _calculateRoute() async {
    if (_userLat == null || _userLng == null) {
      debugPrint('Cannot calculate route: user location not available');
      return;
    }

    final kitchen = _selectedKitchen;
    debugPrint(
        'Calculating route from kitchen (${kitchen.latitude}, ${kitchen.longitude}) to user ($_userLat, $_userLng)');

    final route = await TomTomRoutingService.getRoute(
      startLat: kitchen.latitude,
      startLng: kitchen.longitude,
      endLat: _userLat!,
      endLng: _userLng!,
    );

    if (!mounted) return;

    setState(() {
      _route = route;
      _loadingRoute = false;
      if (route != null) {
        _routePoints = route.routePoints;
        debugPrint(
            'Route calculated: ${route.distanceFormatted}, ${route.durationFormatted}');
      }
    });

    // Animate camera to show route
    if (route != null && _routePoints.isNotEmpty) {
      _fitMapToRoute();
    }
  }

  /// Fit map to show entire route
  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    try {
      // Calculate bounds for all points (route + markers)
      final kitchen = _selectedKitchen;
      List<LatLng> allPoints = [
        kitchen,
        ..._routePoints,
        if (_userLat != null && _userLng != null) LatLng(_userLat!, _userLng!),
      ];

      double minLat = allPoints.first.latitude;
      double maxLat = allPoints.first.latitude;
      double minLng = allPoints.first.longitude;
      double maxLng = allPoints.first.longitude;

      for (var point in allPoints) {
        minLat = minLat > point.latitude ? point.latitude : minLat;
        maxLat = maxLat < point.latitude ? point.latitude : maxLat;
        minLng = minLng > point.longitude ? point.longitude : minLng;
        maxLng = maxLng < point.longitude ? point.longitude : maxLng;
      }

      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      final distance = const Distance().as(
        LengthUnit.Meter,
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      // Calculate zoom based on distance
      double zoom = 15;
      if (distance > 10000)
        zoom = 10;
      else if (distance > 5000)
        zoom = 11;
      else if (distance > 2000)
        zoom = 12;
      else if (distance > 1000) zoom = 13;

      _mapController.move(center, zoom);
    } catch (e) {
      debugPrint('Error fitting map to route: $e');
    }
  }

  /// Simulate delivery progress
  void _simulateDeliveryProgress() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _currentStep = 1);
      Provider.of<OrderProvider>(context, listen: false)
          .updateOrderStatus(widget.order.id, 'Out for Delivery');

      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _currentStep = 2);
        Provider.of<OrderProvider>(context, listen: false)
            .updateOrderStatus(widget.order.id, 'Delivered');

        final subscriptionProvider =
            Provider.of<SubscriptionProvider>(context, listen: false);
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await subscriptionProvider.decrementIfSubscriptionOrder(
            currentUser.uid,
            widget.order.mealType,
            widget.order.mealPlan,
            widget.order.serviceName,
          );
        }

        _showDeliveredDialog();
      }
    }
  }

  /// Show delivered dialog
  void _showDeliveredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Delivered!'),
        content: const Text('Your tiffin has been delivered. Enjoy your meal!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRatingDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show rating dialog
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double tempRating = _userRating;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Rate Your Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text('How was your tiffin?'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () =>
                          setState(() => tempRating = (index + 1).toDouble()),
                      child: Icon(
                        tempRating >= index + 1
                            ? Icons.star
                            : Icons.star_outline,
                        size: 40,
                        color: Colors.orange,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  tempRating > 0
                      ? '${tempRating.toStringAsFixed(0)} out of 5 stars'
                      : 'Select a rating',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: tempRating > 0
                    ? () {
                        _userRating = tempRating;
                        _submitRating();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Submit rating to Firestore
  void _submitRating() async {
    if (_userRating == 0) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'rating': _userRating,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Map
          if (_userLat != null && _userLng != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(_userLat ?? 22.3045, _userLng ?? 70.8032),
                zoom: 14.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                // OpenStreetMap tile layer (works without API key)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tiffin',
                ),

                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: const Color(0xFF1E3A8A),
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Kitchen marker
                    Marker(
                      point: _selectedKitchen,
                      width: 40,
                      height: 40,
                      builder: (context) => GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kitchen Location')),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child:
                              const Icon(Icons.restaurant, color: Colors.white),
                        ),
                      ),
                    ),

                    // User location marker
                    if (_userLat != null && _userLng != null)
                      Marker(
                        point: LatLng(_userLat!, _userLng!),
                        width: 40,
                        height: 40,
                        builder: (context) => GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Your Location (Delivery Address)')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on,
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_locationStatus),
                ],
              ),
            ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomInfoCard(),
          ),
        ],
      ),
    );
  }

  /// Build bottom information card
  Widget _buildBottomInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),

          // Delivery status indicator
          _buildStatusIndicator(),

          const SizedBox(height: 16),

          // Route info (distance and ETA)
          if (_route != null && !_loadingRoute)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.straighten,
                          color: Color(0xFF1E3A8A), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        _route!.distanceFormatted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.schedule,
                          color: Color(0xFF1E3A8A), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        _route!.durationFormatted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.local_shipping,
                          color: Color(0xFF1E3A8A), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (_loadingRoute)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          const SizedBox(height: 16),

          // Order details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Service', widget.order.serviceName),
                _buildDetailRow('Meal Type', widget.order.mealType),
                _buildDetailRow('Meal Plan', widget.order.mealPlan),
                _buildDetailRow('Payment', widget.order.paymentMethod),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build delivery status indicator with steps
  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStep(0, 'Preparing', Icons.restaurant),
          Expanded(
            child: Container(
              height: 3,
              color: _currentStep > 0 ? Colors.green : Colors.grey[300],
            ),
          ),
          _buildStep(1, 'On the way', Icons.local_shipping),
          Expanded(
            child: Container(
              height: 3,
              color: _currentStep > 1 ? Colors.green : Colors.grey[300],
            ),
          ),
          _buildStep(2, 'Delivered', Icons.check_circle),
        ],
      ),
    );
  }

  /// Build single status step
  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build key-value detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  /// Get current delivery status text
  String _getStatusText() {
    switch (_currentStep) {
      case 0:
        return 'Preparing';
      case 1:
        return 'En route';
      case 2:
        return 'Delivered';
      default:
        return 'Processing';
    }
  }
}
