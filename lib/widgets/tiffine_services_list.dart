import 'dart:async';
import 'dart:math' show sin, cos, atan2, sqrt, pi;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../models/tiffine_service_model.dart';
import '../data/meal_plans_data.dart';
import '../screens/payment_delivery_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/meal_plan_details_screen.dart';
import '../services/tomtom_routing_service.dart';

class TiffineServicesList extends StatefulWidget {
  final String searchQuery;
  final ScrollController? scrollController;

  const TiffineServicesList({
    super.key,
    this.searchQuery = '',
    this.scrollController,
  });

  @override
  State<TiffineServicesList> createState() => _TiffineServicesListState();
}

class _TiffineServicesListState extends State<TiffineServicesList> {
  double? _userLat;
  double? _userLng;
  bool _locationFetched = false;

  final List<Map<String, dynamic>> _services = const [];

  /// Geocode cache: docId → {lat, lng} (prevents re-geocoding every rebuild)
  final Map<String, Map<String, double>> _geocodeCache = {};
  /// Track which doc IDs are currently being geocoded to avoid duplicate calls
  final Set<String> _geocodingInProgress = {};

  /// TomTom road distance cache: docId → km (avoids repeat API calls)
  final Map<String, double> _roadDistanceCache = {};
  /// Track which doc IDs are being fetched via TomTom
  final Set<String> _roadDistanceFetching = {};

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) { _setLocationFetched(); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _setLocationFetched(); return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _locationFetched = true;
        });
      }
    } catch (_) {
      _setLocationFetched();
    }
  }

  void _setLocationFetched() {
    if (mounted) setState(() => _locationFetched = true);
  }

  /// Haversine formula – distance in km between two GPS points.
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Geocode a service's address in the background, save to Firestore, and
  /// trigger a rebuild so the filter picks up the new coordinates.
  Future<void> _geocodeServiceAddress(String docId, String address) async {
    if (_geocodingInProgress.contains(docId) || _geocodeCache.containsKey(docId)) return;
    _geocodingInProgress.add(docId);
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final lat = locations.first.latitude;
        final lng = locations.first.longitude;
        _geocodeCache[docId] = {'lat': lat, 'lng': lng};
        debugPrint('📍 Geocoded "$address" → Lat=$lat, Lng=$lng');
        // Persist to Firestore so future loads don't need geocoding
        try {
          await FirebaseFirestore.instance
              .collection('tiffin_services')
              .doc(docId)
              .update({'latitude': lat, 'longitude': lng});
        } catch (_) {}
        if (mounted) setState(() {}); // rebuild with new coords
      }
    } catch (e) {
      debugPrint('⚠️ Failed to geocode "$address": $e');
    } finally {
      _geocodingInProgress.remove(docId);
    }
  }

  /// Fetch road distance via TomTom for a service, cache the result, and
  /// trigger a rebuild so the distance chip shows road km.
  Future<void> _fetchRoadDistance(String docId, double kitchenLat, double kitchenLng) async {
    if (_roadDistanceFetching.contains(docId) || _roadDistanceCache.containsKey(docId)) return;
    if (_userLat == null || _userLng == null) return;
    _roadDistanceFetching.add(docId);
    try {
      final route = await TomTomRoutingService.getRoute(
        startLat: kitchenLat,
        startLng: kitchenLng,
        endLat: _userLat!,
        endLng: _userLng!,
      );
      if (route != null) {
        _roadDistanceCache[docId] = route.distanceInKm;
        debugPrint('🛣️ TomTom road distance for $docId: ${route.distanceInKm} km');
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('⚠️ TomTom failed for $docId: $e');
    } finally {
      _roadDistanceFetching.remove(docId);
    }
  }

  List<Map<String, dynamic>> _filterServices(List<Map<String, dynamic>> services) {
    List<Map<String, dynamic>> result = services;
    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      result = result.where((s) {
        final name = s['name'].toString().toLowerCase();
        final desc = s['description'].toString().toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();
    }
    // Filter by serviceable range if user location is known
    if (_userLat != null && _userLng != null) {
      result = result.where((s) {
        double? lat = (s['latitude'] as num?)?.toDouble();
        double? lng = (s['longitude'] as num?)?.toDouble();
        final rangeKm = (s['serviceRangeKm'] as num?)?.toDouble();

        // Try geocode cache if Firestore has no coords
        if (lat == null || lng == null) {
          final cached = _geocodeCache[s['id']];
          if (cached != null) {
            lat = cached['lat'];
            lng = cached['lng'];
          }
        }

        // Still no coords → trigger background geocode, hide until known
        if (lat == null || lng == null) {
          final address = s['address'] ?? s['description'] ?? '';
          if (address.toString().isNotEmpty && s['id'] != null) {
            _geocodeServiceAddress(s['id'], address.toString());
          }
          // If service has a range set, hide it until we know coordinates
          if (rangeKm != null && rangeKm > 0) return false;
          return true; // no range set → show anyway
        }
        if (rangeKm == null || rangeKm <= 0) return true; // no range set → show
        // Prefer TomTom road distance if cached, else Haversine
        final dist = _roadDistanceCache[s['id']] ?? _distanceKm(_userLat!, _userLng!, lat, lng);
        return dist <= rangeKm;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (!_locationFetched) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('tiffin_services').snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> services = [];

        if (snapshot.hasData) {
          services = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['serviceName'] ?? data['name'] ?? 'Tiffin Service';
            // Exclude closed, unapproved, disabled services and placeholder docs
            return data['isClosed'] != true &&
                data['isApproved'] != false &&
                data['isDisabled'] != true &&
                name.toString().toLowerCase() != 'tiffin service';
          }).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Dynamic Price Calculation
            String priceDisplay = '₹150-₹300';
            if (data['prices'] is Map<String, dynamic>) {
              final pricesMap = data['prices'] as Map<String, dynamic>;
              double minPrice = double.infinity;
              double maxPrice = 0.0;
              bool foundPrices = false;
              
              pricesMap.values.forEach((planPrices) {
                if (planPrices is Map<String, dynamic>) {
                  planPrices.values.forEach((price) {
                    if (price is num) {
                      final p = price.toDouble();
                      if (p > 0) {
                        if (p < minPrice) minPrice = p;
                        if (p > maxPrice) maxPrice = p;
                        foundPrices = true;
                      }
                    }
                  });
                }
              });
              
              if (foundPrices) {
                if (minPrice == maxPrice) {
                  priceDisplay = '₹${minPrice.toStringAsFixed(0)}';
                } else {
                  priceDisplay = '₹${minPrice.toStringAsFixed(0)}-₹${maxPrice.toStringAsFixed(0)}';
                }
              } else {
                priceDisplay = data['price'] ?? data['priceRange'] ?? '₹150-₹300';
              }
            } else {
              priceDisplay = data['price'] ?? data['priceRange'] ?? '₹150-₹300';
            }

            // Dynamic Rating Generation
            double currentRating;
            if (data['rating'] != null && data['rating'] is num) {
              currentRating = (data['rating'] as num).toDouble();
            } else {
              // Generate pseudo-random rating between 4.0 and 4.7 based on doc.id hash
              final hash = doc.id.hashCode.abs();
              final fractional = (hash % 8) / 10; // 0.0 to 0.7
              currentRating = 4.0 + fractional;
            }

            // Compute distance from user to this kitchen
            double? distanceKm;
            double? lat = (data['latitude'] as num?)?.toDouble();
            double? lng = (data['longitude'] as num?)?.toDouble();
            // Use geocode cache if Firestore has no coords
            if (lat == null || lng == null) {
              final cached = _geocodeCache[doc.id];
              if (cached != null) {
                lat = cached['lat'];
                lng = cached['lng'];
              }
            }
            if (_userLat != null && _userLng != null && lat != null && lng != null) {
              // Prefer TomTom cached road distance; fall back to Haversine
              if (_roadDistanceCache.containsKey(doc.id)) {
                distanceKm = _roadDistanceCache[doc.id];
              } else {
                distanceKm = _distanceKm(_userLat!, _userLng!, lat, lng);
                // Trigger async TomTom fetch so the road distance replaces Haversine
                _fetchRoadDistance(doc.id, lat, lng);
              }
            }

            return {
              'id': doc.id,
              'name': data['serviceName'] ?? data['name'] ?? 'Tiffin Service',
              'description': data['address'] ?? data['description'] ?? '',
              'rating': currentRating,
              'deliveryTime':
                  data['availableTime'] ?? data['deliveryTime'] ?? '',
              'price': priceDisplay,
              'image': data['image'] ?? 'assets/images/kathiyavadi.jpg',
              'distanceKm': distanceKm,
              ...data,
            };
          }).toList();

          // Sort by distance (closest first) when user location is known
          if (_userLat != null && _userLng != null) {
            services.sort((a, b) {
              final da = (a['distanceKm'] as double?) ?? double.infinity;
              final db = (b['distanceKm'] as double?) ?? double.infinity;
              return da.compareTo(db);
            });
          }
        }

        // Fallback to built-in list when Firestore has no documents.
        if (services.isEmpty) {
          services = _services;
        }

        final filteredServices = _filterServices(services);

        if (filteredServices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.searchQuery.isNotEmpty ? Icons.search_off : Icons.location_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.searchQuery.isNotEmpty
                      ? 'No Tiffin Service Available'
                      : 'No services available in your area',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.searchQuery.isNotEmpty
                      ? 'Try searching with different keywords'
                      : 'Services outside your delivery range are hidden',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final service = filteredServices[index];
            return _buildServiceCard(context, service, index);
          },
        );
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.star,
                            '${service['rating']}',
                            Colors.amber,
                          ),
                          _buildInfoChip(
                            Icons.timer,
                            service['deliveryTime'],
                            const Color(0xFF1E3A8A),
                          ),
                          _buildInfoChip(
                            Icons.currency_rupee,
                            service['price'],
                            Colors.green,
                          ),
                          // Distance chip
                          if (service['distanceKm'] != null)
                            _buildInfoChip(
                              Icons.near_me,
                              '${(service['distanceKm'] as double).toStringAsFixed(1)} km away',
                              Colors.blueGrey,
                            ),
                          // Serviceable range badge
                          if ((service['serviceRangeKm'] as num?) != null && (service['serviceRangeKm'] as num) > 0)
                            _buildInfoChip(
                              Icons.delivery_dining,
                              'Delivers upto ${(service['serviceRangeKm'] as num).toInt()} km',
                              const Color(0xFF1E3A8A),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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

  late List<MealPlan> _mealPlans;

  Map<String, Map<String, double>>? _servicePriceOverrides;
  Map<String, List<ExtraFoodItem>>? _serviceExtraFoodsOverrides;

  bool _isLoadingServiceConfig = true;
  StreamSubscription<DocumentSnapshot>? _serviceSub;

  @override
  void initState() {
    super.initState();
    // Determine today's weekday and lock other days
    _todayDay = _weekdayToString(DateTime.now().weekday);
    _selectedDay = _todayDay;

    // Get meal plans from data file
    _mealPlans = MealPlansData.getVegMealPlans(widget.service['id']);

    // Load any price overrides that seller has saved for this service.
    _loadServicePriceOverrides();

    // Prefetch Firestore menu data so details screen can load quickly
    MealPlansData.loadData();
    _calculateTotal();
  }

  @override
  void dispose() {
    _serviceSub?.cancel();
    super.dispose();
  }

  void _loadServicePriceOverrides() {
    try {
      _serviceSub = FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.service['id'])
          .snapshots()
          .listen((doc) {
        if (!doc.exists) {
          if (mounted) {
            setState(() {
              _isLoadingServiceConfig = false;
              _mealPlans = [];
            });
          }
          return;
        }

        final data = doc.data();
        if (data == null) {
          if (mounted) {
            setState(() {
              _isLoadingServiceConfig = false;
              _mealPlans = [];
            });
          }
          return;
        }

        // Get base meal plans from data file each time so they don't compound overrides
        var baseMealPlans = MealPlansData.getVegMealPlans(widget.service['id']);

        // Filter available meal plans to those the seller has enabled.
        final allowedTypes =
            (data['tiffinTypes'] as List<dynamic>?)?.cast<String>() ?? [];
        if (allowedTypes.isNotEmpty) {
          _mealPlans = baseMealPlans
              .where((plan) => allowedTypes.contains(plan.id))
              .toList();
        } else {
          _mealPlans = [];
        }

        final prices = data['prices'] as Map<String, dynamic>?;
        if (prices != null) {
          // Convert nested maps to double values and apply to meal plans
          _servicePriceOverrides = {};
          prices.forEach((planId, planData) {
            if (planData is Map<String, dynamic>) {
              final veg = (planData['veg'] is num)
                  ? (planData['veg'] as num).toDouble()
                  : null;
              final jain = (planData['jain'] is num)
                  ? (planData['jain'] as num).toDouble()
                  : null;
              _servicePriceOverrides![planId] = {
                'veg': veg ?? 0.0,
                'jain': jain ?? 0.0,
              };
            }
          });
        }

        final extraFoodsMap = data['extra_foods'] as Map<String, dynamic>?;
        if (extraFoodsMap != null) {
          _serviceExtraFoodsOverrides = {};
          extraFoodsMap.forEach((planId, planExtrasList) {
            if (planExtrasList is List) {
              final items = planExtrasList.map((e) {
                return ExtraFoodItem(
                  id: e['name'],
                  name: e['name'],
                  description: '',
                  price: (e['price'] as num?)?.toDouble() ?? 0.0,
                  category: planId,
                  image: '',
                );
              }).toList();
              _serviceExtraFoodsOverrides![planId] = items;
            }
          });
        }

        _applyPriceOverrides();

        if (mounted) {
          setState(() {
            _isLoadingServiceConfig = false;
          });
        }
      }, onError: (error) {
        debugPrint('Failed to listen to service prices: $error');
        if (mounted) {
          setState(() {
            _isLoadingServiceConfig = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting prices stream: $e');
      if (mounted) {
        setState(() {
          _isLoadingServiceConfig = false;
        });
      }
    }
  }

  void _applyPriceOverrides() {
    if (_servicePriceOverrides == null && _serviceExtraFoodsOverrides == null)
      return;

    _mealPlans = _mealPlans.map((plan) {
      final overrides = _servicePriceOverrides?[plan.id];
      final extraFoods = _serviceExtraFoodsOverrides?[plan.id];

      return MealPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        prices: overrides != null
            ? {
                'veg': overrides['veg'] ?? plan.prices['veg'] ?? 0.0,
                'jain': overrides['jain'] ?? plan.prices['jain'] ?? 0.0,
              }
            : plan.prices,
        specialOffer: plan.specialOffer,
        contents: plan.contents,
        extraFoodItems: extraFoods ?? plan.extraFoodItems,
      );
    }).toList();

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
    const navy = Color(0xFF1E3A8A);

    if (_isLoadingServiceConfig) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.service['name']),
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_mealPlans.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.service['name']),
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'This service has not enabled any meal plans yet. Please check back later or contact the provider.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service['name']),
        backgroundColor: navy,
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
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                              });
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
                                            : Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
              child: _selectedDay == _todayDay
                  ? ElevatedButton(
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
                    )
                  : ElevatedButton(
                      onPressed: null, // Disabled
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Orders only available for today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
      onLongPress: () async {
        debugPrint('🔵 Long-press detected on plan: ${plan.name}');

        if (_selectedMealType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please select a meal type before viewing details.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        try {
          final day = _selectedDay;
          debugPrint(
              '🔵 Fetching menu: ${widget.service['id']} / $_selectedMealType / ${plan.id} / $day');

          final menu = await MealPlansData.getDailyMenu(
              widget.service['id'], _selectedMealType!, plan.id, day,
              forceRefresh: true);

          debugPrint('🟢 Menu fetched: $menu');

          if (!mounted) return;

          if (menu.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Menu will be available soon. Please check back later.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MealPlanDetailsScreen(
                mealPlan: plan,
                mealType: _selectedMealType!,
                serviceId: widget.service['id'],
                selectedDay: day,
                initialMenu: menu,
              ),
            ),
          );
        } catch (e) {
          debugPrint('🔴 Error in long-press: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading menu: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
    double totalExtraFoodPrice = 0.0;
    for (var entry in _selectedExtraFood.entries) {
      if (entry.value > 0) {
        final item =
            mealPlan.extraFoodItems.firstWhere((item) => item.id == entry.key);
        final itemTotal = item.price * entry.value;
        totalExtraFoodPrice += itemTotal;
        extraFoodList.add(
            '${entry.value}x ${item.name} (₹${itemTotal.toStringAsFixed(2)})');
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
}
