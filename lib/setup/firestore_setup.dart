import 'package:cloud_firestore/cloud_firestore.dart';

/// Setup Tiffin Service Locations in Firestore
/// Run this ONCE to populate service locations
///
/// Usage: Call setupTiffinServiceLocations() from your app initialization
/// Example: In main.dart or a setup screen
///
/// Service IDs available: kathiyavadi, desi_rotalo, nani, rajwadi

class FirestoreSetup {
  static Future<void> setupTiffinServiceLocations() async {
    final db = FirebaseFirestore.instance;

    // Define your tiffin services with their locations
    // IMPORTANT: Match these IDs with the ones in tiffine_services_list.dart
    final services = [
      {
        'id': 'kathiyavadi',
        'name': 'Kathiyavadi Tiffine Service',
        'latitude': 22.2953, // Trikon Baug, Rajkot
        'longitude': 70.8000,
        'address': 'Trikon Baug, Rajkot',
        'phone': '+91-9876543210',
        'description': 'Authentic Kathiyawadi cuisine with traditional flavors',
        'isActive': true,
      },
      {
        'id': 'desi_rotalo',
        'name': 'Desi Rotalo Tiffine Service',
        'latitude': 22.3400, // Greenland Chowk area, Rajkot
        'longitude': 70.8000,
        'address': 'Greenland Chowk area, Rajkot',
        'phone': '+91-9876543211',
        'description': 'Fresh rotis and traditional Gujarati dishes',
        'isActive': true,
      },
      {
        'id': 'nani',
        'name': 'Nani Tiffine Service',
        'latitude': 22.2964, // Yagnik Road, Rajkot
        'longitude': 70.7903,
        'address': 'Yagnik Road, Rajkot',
        'phone': '+91-9876543212',
        'description': 'Home-style cooking with grandmother\'s recipes',
        'isActive': true,
      },
      {
        'id': 'rajwadi',
        'name': 'Rajwadi Tiffine Service',
        'latitude': 22.3248, // Madhapar, Rajkot
        'longitude': 70.7720,
        'address': 'Madhapar, Rajkot',
        'phone': '+91-9876543213',
        'description': 'Royal Rajasthani cuisine with rich flavors',
        'isActive': true,
      },
    ];

    try {
      for (var service in services) {
        await db
            .collection('tiffin_services')
            .doc(service['id'] as String)
            .set(service, SetOptions(merge: true));
        print('✅ Added/Updated: ${service['name']}');
      }
      print('✅ All services setup complete!');
    } catch (e) {
      print('❌ Error setting up services: $e');
    }
  }

  /// Delete all service locations (for testing/reset)
  static Future<void> clearTiffinServiceLocations() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('tiffin_services').get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      print('🗑️ Deleted: ${doc.id}');
    }
    print('✅ All services deleted');
  }

  /// Get all service locations (for debugging)
  static Future<void> debugPrintServiceLocations() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('tiffin_services').get();

    print('\n📍 Available Tiffin Services:');
    print('─' * 60);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      print('ID: ${doc.id}');
      print('Name: ${data['name']}');
      print('Latitude: ${data['latitude']}');
      print('Longitude: ${data['longitude']}');
      print('Address: ${data['address']}');
      print('─' * 60);
    }
  }
}

/// Example coordinates for Rajkot (use these to update the service locations if needed):
/// 
/// Trikon Baug: 22.2953, 70.8000
/// Yagnik Road: 22.2964, 70.7903
/// Madhapar: 22.3248, 70.7720
/// Greenland Chowk area: 22.3400, 70.8000
/// 
/// To find coordinates for your locations:
/// 1. Open Google Maps
/// 2. Search for your location
/// 3. Right-click → Get coordinates
/// 4. Update the latitude and longitude above
