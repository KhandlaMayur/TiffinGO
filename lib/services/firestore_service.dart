import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<String> createOrder(Map<String, dynamic> orderData) async {
    // If caller provided an `id` field, use it as the document ID so
    // subsequent updates using that id (e.g., rating updates) will succeed.
    final providedId =
        (orderData['id'] is String && (orderData['id'] as String).isNotEmpty)
            ? orderData['id'] as String
            : null;

    if (providedId != null) {
      final docRef = _db.collection('orders').doc(providedId);
      await docRef.set({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return providedId;
    } else {
      final ref = await _db.collection('orders').add({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) =>
      _db.collection('orders').doc(orderId).update(updates);

  Stream<QuerySnapshot> ordersForUserStream(String uid) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createSubscription(Map<String, dynamic> data) async {
    final ref = await _db.collection('subscriptions').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot> subscriptionsForUserStream(String uid) {
    return _db
        .collection('subscriptions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getMealPlansData() async {
    // retrieve the document and handle both formats:
    // 1. { data: { ... } }  (upload method used in code)
    // 2. { kathiyavadi: {...}, desi_rotalo: {...}, ... } (manually pasted)
    final doc = await _db.collection('mealPlans').doc('menus').get();
    if (!doc.exists) return null;
    final raw = doc.data();
    if (raw == null) return null;

    final combinedData = <String, dynamic>{};

    if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      combinedData.addAll(raw['data'] as Map<String, dynamic>);
    }

    // Add root level keys (which represent individual service IDs added by sellers)
    raw.forEach((key, value) {
      if (key != 'data') {
        combinedData[key] = value;
      }
    });

    return combinedData;
  }

  Future<void> uploadMealPlansData() async {
    // This is a one-time method to upload the static data to Firestore
    final data = {
      'kathiyavadi': {
        'veg': {
          'normal': {
            'monday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'tuesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'wednesday': [
              '3 Roti',
              'Main Course',
              'Rice',
              'Dal/Kadhi',
              'Salad'
            ],
            'thursday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'friday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'saturday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'sunday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          },
          'premium': {
            'monday': [
              '3 Roti',
              'Paneer Butter Masala',
              'Jeera Rice',
              'Dal Fry',
              'Salad'
            ],
            'tuesday': ['3 Roti', 'Kaju Curry', 'Jeera Rice', 'Dal', 'Papad'],
            'wednesday': [
              '3 Roti',
              'Paneer Tikka Masala',
              'Veg Fried Rice',
              'Kadhi'
            ],
            'thursday': ['3 Roti', 'Paneer Angara', 'Dal Fry', 'Veg Pulav'],
            'friday': ['3 Roti', 'Paneer Lababdar', 'Jeera Rice', 'Kadhi'],
            'saturday': ['3 Roti', 'Paneer Do Pyaza', 'Veg Pulav', 'Dal Fry'],
            'sunday': ['3 Roti', 'Paneer Bhurji', 'Veg Pulav', 'Kadhi'],
          },
          'deluxe': {
            'monday': [
              '3 Roti',
              'Mix Veg',
              'Pulav',
              'Kadhi',
              'Sweet (Gulab Jamun)'
            ],
            'tuesday': [
              '3 Roti',
              'Veg Kolhapuri',
              'Veg Pulav',
              'Kadhi',
              'Sweet'
            ],
            'wednesday': ['3 Roti', 'Mix Veg Curry', 'Veg Pulav', 'Sweet'],
            'thursday': ['3 Roti', 'Gobi Masala', 'Veg Pulav', 'Sweet'],
            'friday': ['3 Roti', 'Mix Veg Curry', 'Fried Rice', 'Sweet'],
            'saturday': ['3 Roti', 'Mix Veg', 'Jeera Rice', 'Sweet'],
            'sunday': ['3 Roti', 'Veg Korma', 'Jeera Rice', 'Sweet'],
          },
          'gym_diet': {
            'monday': [
              '2 Roti (multigrain)',
              'Boiled Veggies',
              'Brown Rice',
              'Moong Dal'
            ],
            'tuesday': [
              '2 Roti (oat)',
              'Sprout Salad',
              'Boiled Moong',
              'Steamed Rice'
            ],
            'wednesday': ['2 Roti', 'Brown Rice', 'Boiled Chana', 'Soup'],
            'thursday': ['2 Roti', 'Brown Rice', 'Sprout Salad', 'Dal'],
            'friday': ['2 Roti', 'Brown Rice', 'Boiled Veg', 'Soup'],
            'saturday': ['2 Roti', 'Steamed Veg', 'Brown Rice', 'Soup'],
            'sunday': ['2 Roti', 'Moong Dal', 'Brown Rice', 'Salad'],
          },
          'combo': {
            'monday': ['Mix of Normal + Deluxe'],
            'tuesday': ['Mix of Normal + Premium'],
            'wednesday': ['Combo of Normal + Deluxe'],
            'thursday': ['Normal + Premium'],
            'friday': ['Normal + Deluxe'],
            'saturday': ['Special Combo'],
            'sunday': ['Special Combo'],
          },
        },
        'jain': {
          'normal': {
            'monday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'tuesday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'wednesday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'thursday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'friday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'saturday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'sunday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
          },
          'premium': {
            'monday': ['3 Roti', 'Paneer Pasanda', 'Jeera Rice', 'Dal'],
            'tuesday': ['3 Roti', 'Paneer Makhmali', 'Veg Pulav'],
            'wednesday': ['3 Roti', 'Methi Paneer', 'Veg Pulav'],
            'thursday': ['3 Roti', 'Paneer Malai', 'Veg Fried Rice'],
            'friday': ['3 Roti', 'Paneer Bhurji (Jain style)', 'Dal Fry'],
            'saturday': ['3 Roti', 'Paneer Sabji', 'Pulav'],
            'sunday': ['3 Roti', 'Methi Mutter', 'Dal'],
          },
          'deluxe': {
            'monday': ['3 Roti', 'Mix Veg (no onion/garlic)', 'Pulav', 'Sweet'],
            'tuesday': ['3 Roti', 'Gatta Masala', 'Jeera Rice', 'Sweet'],
            'wednesday': ['3 Roti', 'Mix Veg Curry', 'Pulav', 'Sweet'],
            'thursday': ['3 Roti', 'Gatta Sabji', 'Pulav', 'Sweet'],
            'friday': ['3 Roti', 'Gatta Curry', 'Veg Pulav'],
            'saturday': ['3 Roti', 'Veg Korma', 'Rice'],
            'sunday': ['3 Roti', 'Veg Curry', 'Pulav'],
          },
          'gym_diet': {
            'monday': ['2 Roti', 'Brown Rice', 'Moong Curry'],
            'tuesday': ['2 Roti', 'Boiled Veg', 'Brown Rice'],
            'wednesday': ['2 Roti', 'Moong Salad', 'Brown Rice'],
            'thursday': ['2 Roti', 'Moong Dal', 'Brown Rice'],
            'friday': ['2 Roti', 'Brown Rice', 'Soup'],
            'saturday': ['2 Roti', 'Brown Rice', 'Salad'],
            'sunday': ['2 Roti', 'Brown Rice', 'Soup'],
          },
          'combo': {
            'monday': ['Mix of Jain Normal + Deluxe'],
            'tuesday': ['Mix of Jain Normal + Premium'],
            'wednesday': ['Combo of Jain Normal + Deluxe'],
            'thursday': ['Jain Normal + Premium'],
            'friday': ['Jain Normal + Deluxe'],
            'saturday': ['Special Jain Combo'],
            'sunday': ['Special Jain Combo'],
          },
        },
      },
      'desi_rotalo': {
        'veg': {
          'normal': {
            'monday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'tuesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'wednesday': [
              '3 Roti',
              'Main Course',
              'Rice',
              'Dal/Kadhi',
              'Salad'
            ],
            'thursday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'friday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'saturday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'sunday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          },
          'premium': {
            'monday': ['4 Roti', 'Paneer Tawa Masala', 'Veg Pulav', 'Dal Fry'],
            'tuesday': ['4 Roti', 'Paneer Angara', 'Jeera Rice', 'Kadhi'],
            'wednesday': ['4 Roti', 'Kaju Curry', 'Veg Pulav', 'Dal'],
            'thursday': ['4 Roti', 'Paneer Do Pyaza', 'Fried Rice', 'Kadhi'],
            'friday': ['4 Roti', 'Paneer Handi', 'Jeera Rice', 'Dal'],
            'saturday': ['4 Roti', 'Paneer Butter Masala', 'Veg Pulav'],
            'sunday': ['4 Roti', 'Paneer Bhurji', 'Jeera Rice'],
          },
          'deluxe': {
            'monday': ['4 Roti', 'Mix Veg Curry', 'Fried Rice', 'Sweet'],
            'tuesday': ['4 Roti', 'Veg Korma', 'Pulav', 'Sweet'],
            'wednesday': ['4 Roti', 'Mix Veg Curry', 'Pulav', 'Sweet'],
            'thursday': ['4 Roti', 'Veg Kofta Curry', 'Pulav', 'Sweet'],
            'friday': ['4 Roti', 'Mix Veg Curry', 'Pulav'],
            'saturday': ['4 Roti', 'Mix Veg Curry', 'Rice'],
            'sunday': ['4 Roti', 'Mix Veg Curry', 'Pulav'],
          },
          'gym_diet': {
            'monday': ['2 Roti', 'Brown Rice', 'Boiled Veg'],
            'tuesday': ['2 Roti', 'Sprouts', 'Brown Rice', 'Soup'],
            'wednesday': ['2 Roti', 'Moong Salad', 'Brown Rice'],
            'thursday': ['2 Roti', 'Soup', 'Brown Rice'],
            'friday': ['2 Roti', 'Brown Rice', 'Salad'],
            'saturday': ['2 Roti', 'Boiled Veg', 'Soup'],
            'sunday': ['2 Roti', 'Brown Rice', 'Salad'],
          },
          'combo': {
            'monday': ['Roti', 'Rice', 'Dal', 'Ringan Batata'],
            'tuesday': ['Roti', 'Rice', 'Kadhi', 'Bhinda Curry'],
            'wednesday': ['Roti', 'Rice', 'Dal', 'Aloo Capsicum'],
            'thursday': ['Roti', 'Rice', 'Dal', 'Chole Masala'],
            'friday': ['Roti', 'Rice', 'Kadhi', 'Gobi Curry'],
            'saturday': ['Roti', 'Rice', 'Dal', 'Baingan Masala'],
            'sunday': ['Roti', 'Rice', 'Kadhi', 'Aloo Gobi'],
          },
        },
        'jain': {
          'normal': {
            'monday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'tuesday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'wednesday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'thursday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'friday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'saturday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'sunday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
          },
          'premium': {
            'monday': ['4 Roti', 'Paneer Malai', 'Jeera Rice', 'Dal'],
            'tuesday': ['4 Roti', 'Paneer Pasanda', 'Veg Pulav'],
            'wednesday': ['4 Roti', 'Paneer Makhmali', 'Jeera Rice'],
            'thursday': ['4 Roti', 'Paneer Bhurji (Jain)', 'Veg Pulav'],
            'friday': ['4 Roti', 'Paneer Curry', 'Fried Rice'],
            'saturday': ['4 Roti', 'Paneer Tikka (Jain)', 'Veg Pulav'],
            'sunday': ['4 Roti', 'Paneer Korma', 'Jeera Rice'],
          },
          'deluxe': {
            'monday': ['4 Roti', 'Mix Veg (Jain)', 'Pulav', 'Sweet'],
            'tuesday': ['4 Roti', 'Gatta Curry', 'Jeera Rice'],
            'wednesday': ['4 Roti', 'Mix Veg Curry', 'Pulav'],
            'thursday': ['4 Roti', 'Veg Curry', 'Jeera Rice'],
            'friday': ['4 Roti', 'Gatta Masala', 'Pulav'],
            'saturday': ['4 Roti', 'Gobi Curry', 'Pulav'],
            'sunday': ['4 Roti', 'Mix Veg Pulav', 'Kadhi'],
          },
          'gym_diet': {
            'monday': ['2 Roti', 'Brown Rice', 'Soup'],
            'tuesday': ['2 Roti', 'Moong Dal', 'Brown Rice'],
            'wednesday': ['2 Roti', 'Brown Rice', 'Salad'],
            'thursday': ['2 Roti', 'Moong Salad', 'Brown Rice'],
            'friday': ['2 Roti', 'Brown Rice', 'Soup'],
            'saturday': ['2 Roti', 'Brown Rice', 'Salad'],
            'sunday': ['2 Roti', 'Brown Rice', 'Soup'],
          },
          'combo': {
            'monday': ['Roti', 'Rice', 'Kadhi', 'Dudhi Curry'],
            'tuesday': ['Roti', 'Rice', 'Dal', 'Gatta Sabji'],
            'wednesday': ['Roti', 'Rice', 'Dal', 'Bhinda Batata'],
            'thursday': ['Roti', 'Rice', 'Kadhi', 'Cabbage Curry'],
            'friday': ['Roti', 'Rice', 'Dal', 'Methi Mutter'],
            'saturday': ['Roti', 'Rice', 'Kadhi', 'Dudhi Tameta'],
            'sunday': ['Roti', 'Rice', 'Dal', 'Mix Veg Curry'],
          },
        },
      },
      'nani': {
        'veg': {
          'normal': {
            'monday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'tuesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'wednesday': [
              '3 Roti',
              'Main Course',
              'Rice',
              'Dal/Kadhi',
              'Salad'
            ],
            'thursday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'friday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'saturday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'sunday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          },
          'premium': {
            'monday': ['3 Roti', 'Paneer Lababdar', 'Jeera Rice', 'Kadhi'],
            'tuesday': ['3 Roti', 'Paneer Do Pyaza', 'Veg Pulav', 'Dal Fry'],
            'wednesday': ['3 Roti', 'Kaju Curry', 'Jeera Rice', 'Kadhi'],
            'thursday': ['3 Roti', 'Paneer Angara', 'Veg Pulav', 'Kadhi'],
            'friday': [
              '3 Roti',
              'Paneer Butter Masala',
              'Veg Fried Rice',
              'Dal'
            ],
            'saturday': ['3 Roti', 'Paneer Tikka Masala', 'Pulav', 'Kadhi'],
            'sunday': ['3 Roti', 'Paneer Bhurji', 'Veg Pulav', 'Dal'],
          },
          'deluxe': {
            'monday': ['3 Roti', 'Mix Veg Curry', 'Pulav', 'Sweet'],
            'tuesday': ['3 Roti', 'Mix Veg', 'Fried Rice', 'Sweet'],
            'wednesday': ['3 Roti', 'Veg Kolhapuri', 'Pulav', 'Sweet'],
            'thursday': ['3 Roti', 'Mix Veg Curry', 'Fried Rice', 'Sweet'],
            'friday': ['3 Roti', 'Mix Veg Curry', 'Veg Pulav', 'Halwa'],
            'saturday': ['3 Roti', 'Veg Kofta Curry', 'Fried Rice', 'Sweet'],
            'sunday': ['3 Roti', 'Veg Korma', 'Rice', 'Sweet'],
          },
          'gym_diet': {
            'monday': [
              '2 Roti (multigrain)',
              'Brown Rice',
              'Moong Dal',
              'Boiled Veg'
            ],
            'tuesday': ['2 Roti', 'Brown Rice', 'Sprouts', 'Soup'],
            'wednesday': ['2 Roti', 'Brown Rice', 'Soup', 'Boiled Veg'],
            'thursday': ['2 Roti', 'Brown Rice', 'Moong Dal', 'Salad'],
            'friday': ['2 Roti', 'Brown Rice', 'Soup', 'Veg'],
            'saturday': ['2 Roti', 'Moong Salad', 'Brown Rice'],
            'sunday': ['2 Roti', 'Brown Rice', 'Soup', 'Sprouts'],
          },
          'combo': {
            'monday': ['Roti', 'Rice', 'Dal', 'Aloo Mutter'],
            'tuesday': ['Roti', 'Rice', 'Kadhi', 'Gobi Masala'],
            'wednesday': ['Roti', 'Rice', 'Dal', 'Baingan Bharta'],
            'thursday': ['Roti', 'Rice', 'Dal', 'Bhindi Curry'],
            'friday': ['Roti', 'Rice', 'Kadhi', 'Aloo Gobi'],
            'saturday': ['Roti', 'Rice', 'Dal', 'Chole Masala'],
            'sunday': ['Roti', 'Rice', 'Kadhi', 'Aloo Capsicum'],
          },
        },
        'jain': {
          'normal': {
            'monday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'tuesday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'wednesday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'thursday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'friday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'saturday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
            'sunday': [
              '3 Roti',
              'Jain Main Course',
              'Rice',
              'Jain Dal/Kadhi',
              'Salad'
            ],
          },
          'premium': {
            'monday': ['3 Roti', 'Paneer Malai', 'Veg Pulav'],
            'tuesday': ['3 Roti', 'Paneer Pasanda', 'Fried Rice'],
            'wednesday': ['3 Roti', 'Paneer Makhmali', 'Veg Pulav'],
            'thursday': ['3 Roti', 'Paneer Korma', 'Jeera Rice'],
            'friday': ['3 Roti', 'Paneer Bhurji (Jain)', 'Veg Pulav'],
            'saturday': ['3 Roti', 'Paneer Curry (Jain)', 'Veg Fried Rice'],
            'sunday': ['3 Roti', 'Paneer Tikka (Jain)', 'Jeera Rice'],
          },
          'deluxe': {
            'monday': ['3 Roti', 'Mix Veg Curry (Jain)', 'Jeera Rice', 'Sweet'],
            'tuesday': ['3 Roti', 'Gatta Curry', 'Veg Pulav', 'Sweet'],
            'wednesday': ['3 Roti', 'Mix Veg Curry', 'Fried Rice'],
            'thursday': ['3 Roti', 'Gatta Sabji', 'Pulav'],
            'friday': ['3 Roti', 'Mix Veg', 'Fried Rice'],
            'saturday': ['3 Roti', 'Veg Pulav', 'Kadhi'],
            'sunday': ['3 Roti', 'Gatta Curry', 'Pulav'],
          },
          'gym_diet': {
            'monday': ['2 Roti', 'Brown Rice', 'Soup'],
            'tuesday': ['2 Roti', 'Brown Rice', 'Boiled Veg'],
            'wednesday': ['2 Roti', 'Moong Dal', 'Brown Rice'],
            'thursday': ['2 Roti', 'Brown Rice', 'Salad'],
            'friday': ['2 Roti', 'Moong Curry', 'Brown Rice'],
            'saturday': ['2 Roti', 'Brown Rice', 'Moong Salad'],
            'sunday': ['2 Roti', 'Brown Rice', 'Soup'],
          },
          'combo': {
            'monday': ['Roti', 'Rice', 'Kadhi', 'Tindora Curry'],
            'tuesday': ['Roti', 'Rice', 'Dal', 'Methi Mutter'],
            'wednesday': ['Roti', 'Rice', 'Kadhi', 'Bhinda Bataka'],
            'thursday': ['Roti', 'Rice', 'Dal', 'Dudhi Curry'],
            'friday': ['Roti', 'Rice', 'Kadhi', 'Gobi Curry'],
            'saturday': ['Roti', 'Rice', 'Dal', 'Methi Gatta'],
            'sunday': ['Roti', 'Rice', 'Kadhi', 'Mix Veg Curry'],
          },
        },
      },
      'rajwadi': {
        'veg': {
          'normal': {
            'monday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'tuesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'wednesday': [
              '3 Roti',
              'Main Course',
              'Rice',
              'Dal/Kadhi',
              'Salad'
            ],
            'thursday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'friday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'saturday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
            'sunday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          },
          'premium': {
            'monday': ['4 Roti', 'Paneer Angara', 'Jeera Rice', 'Dal'],
            'tuesday': ['4 Roti', 'Paneer Butter Masala', 'Veg Pulav'],
            'wednesday': ['4 Roti', 'Paneer Handi', 'Jeera Rice', 'Dal'],
            'thursday': [
              '4 Roti',
              'Paneer Do Pyaza',
              'Veg Fried Rice',
              'Kadhi'
            ],
            'friday': ['4 Roti', 'Paneer Lababdar', 'Veg Pulav'],
            'saturday': ['4 Roti', 'Paneer Tikka Masala', 'Fried Rice'],
            'sunday': ['4 Roti', 'Paneer Bhurji', 'Veg Pulav'],
          },
          'deluxe': {
            'monday': ['4 Roti', 'Kaju Curry', 'Pulav', 'Sweet'],
            'tuesday': ['4 Roti', 'Mix Veg', 'Fried Rice', 'Sweet'],
            'wednesday': ['4 Roti', 'Mix Veg Curry', 'Pulav', 'Sweet'],
            'thursday': ['4 Roti', 'Mix Veg Curry', 'Pulav', 'Halwa'],
            'friday': ['4 Roti', 'Veg Kolhapuri', 'Jeera Rice', 'Sweet'],
            'saturday': ['4 Roti', 'Mix Veg Curry', 'Pulav'],
            'sunday': ['4 Roti', 'Mix Veg', 'Fried Rice', 'Sweet'],
          },
          'gym_diet': {
            'monday': ['2 Roti', 'Brown Rice', 'Moong Dal'],
            'tuesday': ['2 Roti', 'Brown Rice', 'Sprout Salad'],
            'wednesday': ['2 Roti', 'Brown Rice', 'Moong Soup'],
            'thursday': ['2 Roti', 'Brown Rice', 'Soup', 'Salad'],
            'friday': ['2 Roti', 'Brown Rice', 'Moong Curry'],
            'saturday': ['2 Roti', 'Brown Rice', 'Veg Soup'],
            'sunday': ['2 Roti', 'Brown Rice', 'Soup'],
          },
          'combo': {
            'monday': ['Roti', 'Rice', 'Kadhi', 'Mix Veg Curry'],
            'tuesday': ['Roti', 'Rice', 'Dal', 'Aloo Methi'],
            'wednesday': ['Roti', 'Rice', 'Kadhi', 'Bhindi Masala'],
            'thursday': ['Roti', 'Rice', 'Dal', 'Chole Masala'],
            'friday': ['Roti', 'Rice', 'Kadhi', 'Baingan Masala'],
            'saturday': ['Roti', 'Rice', 'Dal', 'Aloo Capsicum'],
            'sunday': ['Roti', 'Rice', 'Kadhi', 'Gobi Masala'],
          },
        },
        'jain': {
          'normal': {
            'monday': ['3 Roti', 'Methi Gatta', 'Rice', 'Kadhi'],
            'tuesday': ['3 Roti', 'Dudhi Tameta', 'Rice', 'Dal'],
            'wednesday': ['3 Roti', 'Bhinda Bataka', 'Rice', 'Kadhi'],
            'thursday': ['3 Roti', 'Tindora Curry', 'Rice', 'Dal'],
            'friday': ['3 Roti', 'Cabbage Curry', 'Rice', 'Kadhi'],
            'saturday': ['3 Roti', 'Mix Veg Curry', 'Rice'],
            'sunday': ['3 Roti', 'Methi Mutter', 'Rice', 'Dal'],
          },
          'premium': {
            'monday': ['4 Roti', 'Paneer Malai', 'Jeera Rice', 'Dal'],
            'tuesday': ['4 Roti', 'Paneer Pasanda', 'Veg Pulav'],
            'wednesday': ['4 Roti', 'Paneer Bhurji (Jain)', 'Fried Rice'],
            'thursday': ['4 Roti', 'Paneer Korma', 'Veg Pulav'],
            'friday': ['4 Roti', 'Paneer Makhmali', 'Veg Pulav'],
            'saturday': ['4 Roti', 'Paneer Curry (Jain)', 'Fried Rice'],
            'sunday': ['4 Roti', 'Paneer Tikka (Jain)', 'Jeera Rice'],
          },
          'deluxe': {
            'monday': ['4 Roti', 'Mix Veg (Jain)', 'Pulav', 'Sweet'],
            'tuesday': ['4 Roti', 'Gatta Curry', 'Jeera Rice'],
            'wednesday': ['4 Roti', 'Mix Veg Curry', 'Pulav'],
            'thursday': ['4 Roti', 'Veg Curry', 'Jeera Rice'],
            'friday': ['4 Roti', 'Gatta Masala', 'Pulav'],
            'saturday': ['4 Roti', 'Gobi Curry', 'Pulav'],
            'sunday': ['4 Roti', 'Mix Veg Pulav', 'Kadhi'],
          },
          'gym_diet': {
            'monday': ['2 Roti', 'Brown Rice', 'Soup'],
            'tuesday': ['2 Roti', 'Moong Dal', 'Brown Rice'],
            'wednesday': ['2 Roti', 'Brown Rice', 'Salad'],
            'thursday': ['2 Roti', 'Moong Salad', 'Brown Rice'],
            'friday': ['2 Roti', 'Brown Rice', 'Soup'],
            'saturday': ['2 Roti', 'Brown Rice', 'Salad'],
            'sunday': ['2 Roti', 'Brown Rice', 'Soup'],
          },
          'combo': {
            'monday': ['Roti', 'Rice', 'Kadhi', 'Methi Gatta'],
            'tuesday': ['Roti', 'Rice', 'Dal', 'Dudhi Tameta'],
            'wednesday': ['Roti', 'Rice', 'Kadhi', 'Bhinda Bataka'],
            'thursday': ['Roti', 'Rice', 'Dal', 'Tindora Curry'],
            'friday': ['Roti', 'Rice', 'Kadhi', 'Cabbage Curry'],
            'saturday': ['Roti', 'Rice', 'Dal', 'Mix Veg Curry'],
            'sunday': ['Roti', 'Rice', 'Kadhi', 'Methi Mutter'],
          },
        },
      },
    };
    await _db.collection('mealPlans').doc('menus').set({'data': data});
  }
}
