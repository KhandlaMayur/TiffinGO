import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider with ChangeNotifier {
  String _currentLocation = 'Loading...';
  String _currentAddress = '';
  bool _isLoading = false;

  String get currentLocation => _currentLocation;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentLocation = 'Location services disabled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentLocation = 'Location permission denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentLocation = 'Location permissions permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 🔹 Add your API key section here (around line 50–60)
      // Add your API key here
      const String apiKey = 'DbYZO9XiU3YZJl1eJLshFvJa7c4c5viJ';
      
      // Use the API key in your geocoding requests (optional customization)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'en_US', // Add locale if needed
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentLocation = '${place.locality}, ${place.administrativeArea}';
        _currentAddress = '${place.street}, ${place.locality}, ${place.administrativeArea}';
      } else {
        _currentLocation = 'Location not found';
        _currentAddress = 'Address not found';
      }
    } catch (e) {
      _currentLocation = 'Error getting location';
      _currentAddress = 'Error getting address';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setLocation(String location) {
    _currentLocation = location;
    notifyListeners();
  }
}
