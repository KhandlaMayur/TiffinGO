import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/order_provider.dart';
import '../providers/location_provider.dart';
import '../providers/firestore_order_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/order_model.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const DeliveryTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  int _currentStep = 0; // 0: Preparing, 1: Out for Delivery, 2: Delivered
  // TomTom & location state
  final String _tomtomApiKey = 'DbYZO9XiU3YZJl1eJLshFvJa7c4c5viJ';
  double? _latitude;
  double? _longitude;
  String _locationText = 'Fetching location...';
  StreamSubscription<Position>? _positionSub;
  // WebView controller (nullable until initialized)
  WebViewController? _webController;
  bool _webAvailable = true;
  double _userRating = 0; // 0-5 stars

  // Initialize WebView controller
  Future<WebViewController> _initializeWebController() async {
    // Check platform support first
    if (!(Platform.isAndroid || Platform.isIOS)) {
      setState(() => _webAvailable = false);
      throw UnsupportedError('WebView is not supported on this platform');
    }

    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      await controller.setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          if (_latitude != null && _longitude != null) {
            final js =
                'if (typeof updatePosition === "function") updatePosition($_latitude, $_longitude);';
            try {
              controller.runJavaScript(js);
            } catch (e) {
              debugPrint('Failed to update map position: $e');
            }
          }
        },
        onWebResourceError: (error) {
          debugPrint('WebView error: ${error.description}');
          setState(() => _webAvailable = false);
        },
      ));

      final htmlContent = _tomTomHtml(_latitude, _longitude);
      await controller.loadHtmlString(htmlContent);
      return controller;
    } catch (e) {
      setState(() => _webAvailable = false);
      throw Exception('Failed to initialize WebView: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _simulateDeliveryProgress();
    _initLocationAndMap();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndMap() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = 'Enable location services';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationText = 'Location permission permanently denied';
      });
      return;
    }

    // Get initial position
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _onNewPosition(pos);
    } catch (e) {
      setState(() {
        _locationText = 'Unable to get location: $e';
      });
    }

    // Subscribe to updates
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      _onNewPosition(pos);
    });
  }

  void _onNewPosition(Position pos) {
    if (!mounted) return;
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _locationText =
          'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}';
    });

    // Update webview map marker if created
    if (_webController != null) {
      final js =
          'if (typeof updatePosition === "function") updatePosition($_latitude, $_longitude);';
      try {
        _webController!.runJavaScript(js);
      } catch (_) {
        try {
          // fallback older API name
          _webController!.runJavaScript(js);
        } catch (_) {}
      }
    }
  }

  // Generate a small HTML page that loads the TomTom Web SDK and exposes updatePosition(lat, lon)
  String _tomTomHtml(double? initialLat, double? initialLng) {
    final lat = initialLat ?? 12.9716; // fallback coordinates (Bengaluru)
    final lng = initialLng ?? 77.5946;
    const cssUrl =
        'https://api.tomtom.com/maps-sdk-for-web/6.x/6.17.0/maps/maps.css';
    const jsUrl =
        'https://api.tomtom.com/maps-sdk-for-web/6.x/6.17.0/maps/maps-web.min.js';

    final html = '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="$cssUrl" />
  <style>html, body, #map { height: 100%; margin: 0; padding: 0; }</style>
</head>
<body>
  <div id="map"></div>
  <script src="$jsUrl"></script>
  <script>
    const apiKey = "$_tomtomApiKey";
    const map = tt.map({
      key: apiKey,
      container: 'map',
      center: [$lng, $lat],
      zoom: 14
    });

    let marker = tt.marker().setLngLat([$lng, $lat]).addTo(map);

    function updatePosition(lat, lon) {
      try {
        marker.setLngLat([lon, lat]);
        map.setCenter([lon, lat]);
      } catch (e) {
        console.log('updatePosition error', e);
      }
    }

    window.updatePosition = updatePosition;
  </script>
</body>
</html>
''';

    return Uri.dataFromString(html, mimeType: 'text/html', encoding: utf8)
        .toString();
  }

  void _simulateDeliveryProgress() async {
    // Simulate order preparation
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _currentStep = 1;
      });
      Provider.of<OrderProvider>(context, listen: false)
          .updateOrderStatus(widget.order.id, 'Out for Delivery');

      // Simulate out for delivery
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _currentStep = 2;
        });
        Provider.of<OrderProvider>(context, listen: false)
            .updateOrderStatus(widget.order.id, 'Delivered');

        // Auto-decrement subscription remaining orders if this is a subscription order
        final subscriptionProvider =
            Provider.of<SubscriptionProvider>(context, listen: false);
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await subscriptionProvider.decrementIfSubscriptionOrder(
            currentUser.uid,
            widget.order.mealType ?? '',
            widget.order.mealPlan ?? '',
            widget.order.serviceName,
          );
        }

        // Show delivered message
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Order Delivered!'),
                content: const Text(
                    'Your tiffin has been successfully delivered. Enjoy your meal!'),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _showRatingDialog(); // Show rating dialog
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
        });
      }
    }
  }

  Future<void> _showRatingDialog() async {
    // Use a StatefulBuilder so the dialog UI updates when stars are tapped
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double tempRating = _userRating; // local dialog rating
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate Your Order'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'How was your tiffin?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  // Star rating widget
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tempRating = starValue.toDouble();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            tempRating >= starValue
                                ? Icons.star
                                : Icons.star_outline,
                            size: 40,
                            color: Colors.orange[700],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tempRating > 0
                        ? '${tempRating.toStringAsFixed(0)} out of 5 stars'
                        : 'Select a rating',
                    style: TextStyle(
                      fontSize: 14,
                      color: tempRating > 0 ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close rating dialog
                    Navigator.of(context).pop(); // Go back to home
                  },
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: tempRating > 0
                      ? () {
                          // Save the rating to the parent state and submit
                          setState(() {}); // ensure dialog updated immediately
                          _userRating = tempRating;
                          _submitRating();
                          Navigator.of(context).pop(); // Close rating dialog
                          Navigator.of(context).pop(); // Go back to home
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitRating() async {
    if (_userRating == 0) return;

    // Create updated order with rating
    final updatedOrder = OrderModel(
      id: widget.order.id,
      serviceName: widget.order.serviceName,
      serviceId: widget.order.serviceId,
      date: widget.order.date,
      amount: widget.order.amount,
      status: 'Delivered',
      paymentMethod: widget.order.paymentMethod,
      mealType: widget.order.mealType,
      mealPlan: widget.order.mealPlan,
      categoryId: widget.order.categoryId,
      subscription: widget.order.subscription,
      extraFood: widget.order.extraFood,
      location: widget.order.location,
      paymentCompleted: widget.order.paymentCompleted,
      rating: _userRating,
    );

    // Update order in local provider
    Provider.of<OrderProvider>(context, listen: false)
        .updateOrder(updatedOrder);

    // Save rating to Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.order.id)
            .update({
          'rating': _userRating,
          'ratedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your rating! 🌟'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving rating to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving rating: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Status
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
                const Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: ${widget.order.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.4)),
              ),
              child: Text(
                // Prefer provider value if it's been set, otherwise use local text
                (locationProvider.currentLocation.isNotEmpty
                    ? locationProvider.currentLocation
                    : _locationText),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Delivery Steps
          const Text(
            'Delivery Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),

          // Step Indicator
          Row(
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
          const SizedBox(height: 24),

          // Map View (TomTom Web SDK via WebView)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF1E3A8A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FutureBuilder<WebViewController>(
                future: _initializeWebController(),
                builder: (context, snapshot) {
                  // Show fallback UI for WebView not available
                  if (!_webAvailable) {
                    return Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.map,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _locationText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _webAvailable = true);
                                  },
                                  child: const Text('Retry map'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Handle initialization errors
                  if (snapshot.hasError) {
                    setState(() => _webAvailable = false);
                    return Stack(
                      children: [
                        Center(
                          child:
                              Text('Error initializing map: ${snapshot.error}'),
                        ),
                      ],
                    );
                  }

                  // Show loading indicator while initializing
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Show the map
                  return WebViewWidget(controller: snapshot.data!);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Order Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Service', widget.order.serviceName),
                _buildDetailRow(
                    'Meal Type', widget.order.mealType.toUpperCase()),
                _buildDetailRow('Meal Plan', widget.order.mealPlan),
                _buildDetailRow('Payment', widget.order.paymentMethod),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
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
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_currentStep) {
      case 0:
        return 'Preparing Your Order';
      case 1:
        return 'Out for Delivery';
      case 2:
        return 'Delivered';
      default:
        return 'Processing';
    }
  }
}
