import '../models/tiffine_service_model.dart';

class MealPlansData {
  static final Map<String, Map<String, Map<String, Map<String, List<String>>>>>
      _dailyMenus = {
    'kathiyavadi': {
      'veg': {
        'normal': {
          'monday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          'tuesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          'wednesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
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
          'tuesday': ['3 Roti', 'Veg Kolhapuri', 'Veg Pulav', 'Kadhi', 'Sweet'],
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
          'sunday': ['2 Roti', 'Soup', 'Brown Rice'],
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
          'wednesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
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
          'sunday': ['4 Roti', 'Veg Korma', 'Pulav'],
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
          'tuesday': ['4 Roti', 'Veg Curry', 'Fried Rice'],
          'wednesday': ['4 Roti', 'Gatta Masala', 'Pulav'],
          'thursday': ['4 Roti', 'Gobi Curry', 'Pulav'],
          'friday': ['4 Roti', 'Gatta Curry', 'Pulav'],
          'saturday': ['4 Roti', 'Veg Curry', 'Rice'],
          'sunday': ['4 Roti', 'Veg Pulav', 'Dal'],
        },
        'gym_diet': {
          'monday': ['2 Roti', 'Brown Rice', 'Soup'],
          'tuesday': ['2 Roti', 'Moong Dal', 'Brown Rice'],
          'wednesday': ['2 Roti', 'Boiled Veg'],
          'thursday': ['2 Roti', 'Brown Rice', 'Soup'],
          'friday': ['2 Roti', 'Brown Rice', 'Dal'],
          'saturday': ['2 Roti', 'Boiled Veg'],
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
          'wednesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
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
          'friday': ['3 Roti', 'Paneer Butter Masala', 'Veg Fried Rice', 'Dal'],
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
          'wednesday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          'thursday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          'friday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          'saturday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
          'sunday': ['3 Roti', 'Main Course', 'Rice', 'Dal/Kadhi', 'Salad'],
        },
        'premium': {
          'monday': ['4 Roti', 'Paneer Angara', 'Jeera Rice', 'Dal'],
          'tuesday': ['4 Roti', 'Paneer Butter Masala', 'Veg Pulav'],
          'wednesday': ['4 Roti', 'Paneer Handi', 'Jeera Rice', 'Dal'],
          'thursday': ['4 Roti', 'Paneer Do Pyaza', 'Veg Fried Rice', 'Kadhi'],
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

  static List<String> getDailyMenu(
      String service, String menuType, String planType, String day) {
    return _dailyMenus[service]?[menuType]?[planType]?[day.toLowerCase()] ?? [];
  }

  static MealPlan _createMealPlan(String id, String name, String description,
      double vegPrice, double jainPrice) {
    String serviceId = '';
    if (name.toLowerCase().contains('kathiyavadi')) {
      serviceId = 'kathiyavadi';
    } else if (name.toLowerCase().contains('desi rotalo')) {
      serviceId = 'desi_rotalo';
    } else if (name.toLowerCase().contains('nani')) {
      serviceId = 'nani';
    } else if (name.toLowerCase().contains('rajwadi')) {
      serviceId = 'rajwadi';
    }

    bool isJain = name.toLowerCase().contains('jain');

    return MealPlan(
      id: id,
      name: name,
      description: description,
      prices: {'veg': vegPrice, 'jain': jainPrice},
      specialOffer: '10% off on monthly subscription',
      contents: {
        'veg': [
          MealPlanItem(
              name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
          MealPlanItem(
              name: 'Main Course',
              image: 'assets/images/sabji.jpg',
              quantity: 1),
          MealPlanItem(
              name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
          MealPlanItem(
              name: 'Dal/Kadhi', image: 'assets/images/dal.jpg', quantity: 1),
          MealPlanItem(
              name: 'Salad', image: 'assets/images/salad.jpg', quantity: 1),
        ],
        'jain': [
          MealPlanItem(
              name: 'Rotis', image: 'assets/images/chapati.jpg', quantity: 3),
          MealPlanItem(
              name: 'Jain Main Course',
              image: 'assets/images/sabji.jpg',
              quantity: 1),
          MealPlanItem(
              name: 'Rice', image: 'assets/images/rice.jpg', quantity: 1),
          MealPlanItem(
              name: 'Jain Dal/Kadhi',
              image: 'assets/images/dal.jpg',
              quantity: 1),
          MealPlanItem(
              name: 'Salad', image: 'assets/images/salad.jpg', quantity: 1),
        ],
      },
      extraFoodItems: [
        ...getBaseExtraFoodItems(),
        ...getServiceExtraFoodItems(serviceId, isJain: isJain)
      ],
    );
  }

  static List<MealPlan> getVegMealPlans(String serviceId,
      {bool isJain = false}) {
    switch (serviceId) {
      case 'kathiyavadi':
        return [
          _createMealPlan(
            'normal',
            isJain
                ? 'Jain Normal Kathiyavadi Tiffin'
                : 'Normal Kathiyavadi Tiffin',
            isJain
                ? 'Traditional Jain Kathiyavadi meal'
                : 'Traditional Kathiyavadi meal',
            100.0,
            110.0,
          ),
          _createMealPlan(
            'premium',
            isJain
                ? 'Jain Premium Kathiyavadi Tiffin'
                : 'Premium Kathiyavadi Tiffin',
            isJain
                ? 'Premium Jain Kathiyavadi meal'
                : 'Premium Kathiyavadi meal',
            150.0,
            160.0,
          ),
          _createMealPlan(
            'deluxe',
            isJain
                ? 'Jain Deluxe Kathiyavadi Tiffin'
                : 'Deluxe Kathiyavadi Tiffin',
            isJain ? 'Luxury Jain Kathiyavadi meal' : 'Luxury Kathiyavadi meal',
            200.0,
            210.0,
          ),
          _createMealPlan(
            'gym_diet',
            isJain
                ? 'Jain Gym/Diet Kathiyavadi Tiffin'
                : 'Gym/Diet Kathiyavadi Tiffin',
            isJain
                ? 'Healthy Jain Kathiyavadi meal'
                : 'Healthy Kathiyavadi meal',
            180.0,
            190.0,
          ),
        ];

      case 'desi_rotalo':
        return [
          _createMealPlan(
            'normal',
            isJain
                ? 'Jain Normal Desi Rotalo Tiffin'
                : 'Normal Desi Rotalo Tiffin',
            isJain
                ? 'Traditional Jain Desi Rotalo meal'
                : 'Traditional Desi Rotalo meal',
            120.0,
            130.0,
          ),
          _createMealPlan(
            'premium',
            isJain
                ? 'Jain Premium Desi Rotalo Tiffin'
                : 'Premium Desi Rotalo Tiffin',
            isJain
                ? 'Premium Jain Desi Rotalo meal'
                : 'Premium Desi Rotalo meal',
            170.0,
            180.0,
          ),
          _createMealPlan(
            'deluxe',
            isJain
                ? 'Jain Deluxe Desi Rotalo Tiffin'
                : 'Deluxe Desi Rotalo Tiffin',
            isJain ? 'Luxury Jain Desi Rotalo meal' : 'Luxury Desi Rotalo meal',
            220.0,
            230.0,
          ),
          _createMealPlan(
            'gym_diet',
            isJain
                ? 'Jain Gym/Diet Desi Rotalo Tiffin'
                : 'Gym/Diet Desi Rotalo Tiffin',
            isJain
                ? 'Healthy Jain Desi Rotalo meal'
                : 'Healthy Desi Rotalo meal',
            190.0,
            200.0,
          ),
        ];

      case 'rajwadi':
        return [
          _createMealPlan(
            'normal',
            isJain ? 'Jain Normal Rajwadi Tiffin' : 'Normal Rajwadi Tiffin',
            isJain
                ? 'Traditional Jain Rajasthani meal'
                : 'Traditional Rajasthani meal',
            140.0,
            150.0,
          ),
          _createMealPlan(
            'premium',
            isJain ? 'Jain Premium Rajwadi Tiffin' : 'Premium Rajwadi Tiffin',
            isJain ? 'Premium Jain Rajasthani meal' : 'Premium Rajasthani meal',
            190.0,
            200.0,
          ),
          _createMealPlan(
            'deluxe',
            isJain ? 'Jain Deluxe Rajwadi Tiffin' : 'Deluxe Rajwadi Tiffin',
            isJain ? 'Luxury Jain Rajasthani meal' : 'Luxury Rajasthani meal',
            240.0,
            250.0,
          ),
          _createMealPlan(
            'gym_diet',
            isJain ? 'Jain Gym/Diet Rajwadi Tiffin' : 'Gym/Diet Rajwadi Tiffin',
            isJain ? 'Healthy Jain Rajasthani meal' : 'Healthy Rajasthani meal',
            210.0,
            220.0,
          ),
        ];

      case 'nani':
        return [
          _createMealPlan(
            'normal',
            isJain ? 'Jain Normal Nani Tiffin' : 'Normal Nani Tiffin',
            isJain ? 'Traditional Jain meal' : 'Traditional meal',
            130.0,
            140.0,
          ),
          _createMealPlan(
            'premium',
            isJain ? 'Jain Premium Nani Tiffin' : 'Premium Nani Tiffin',
            isJain
                ? 'Premium Jain meal with special items'
                : 'Premium meal with special items',
            180.0,
            190.0,
          ),
          _createMealPlan(
            'deluxe',
            isJain ? 'Jain Deluxe Nani Tiffin' : 'Deluxe Nani Tiffin',
            isJain ? 'Luxury Jain meal with sweets' : 'Luxury meal with sweets',
            230.0,
            240.0,
          ),
          _createMealPlan(
            'gym_diet',
            isJain ? 'Jain Gym/Diet Nani Tiffin' : 'Gym/Diet Nani Tiffin',
            isJain ? 'Healthy Jain meal' : 'Healthy meal',
            200.0,
            210.0,
          ),
        ];

      default:
        return [];
    }
  }

  static List<ExtraFoodItem> getBaseExtraFoodItems() {
    return [
      ExtraFoodItem(
        id: 'roti',
        name: 'Extra Roti',
        description: 'Fresh wheat roti',
        price: 10.0,
        category: 'bread',
        image: 'assets/images/chapati.jpg',
      ),
      ExtraFoodItem(
        id: 'rice',
        name: 'Extra Rice',
        description: 'Steamed rice portion',
        price: 30.0,
        category: 'rice',
        image: 'assets/images/rice.jpg',
      ),
      ExtraFoodItem(
        id: 'dal',
        name: 'Extra Dal',
        description: 'Additional dal portion',
        price: 40.0,
        category: 'dal',
        image: 'assets/images/dal.jpg',
      ),
      ExtraFoodItem(
        id: 'sabji',
        name: 'Extra Sabji',
        description: 'Extra vegetable curry',
        price: 50.0,
        category: 'sabji',
        image: 'assets/images/sabji.jpg',
      ),
      ExtraFoodItem(
        id: 'buttermilk',
        name: 'Butter Milk',
        description: 'Fresh buttermilk',
        price: 20.0,
        category: 'beverage',
        image: 'assets/images/buttermilk.jpg',
      ),
      ExtraFoodItem(
        id: 'sweet',
        name: 'Sweet',
        description: 'Dessert of the day',
        price: 25.0,
        category: 'dessert',
        image: 'assets/images/sweet.jpg',
      ),
      ExtraFoodItem(
        id: 'papad',
        name: 'Papad',
        description: 'Crispy papad',
        price: 10.0,
        category: 'side',
        image: 'assets/images/papad.jpg',
      )
    ];
  }

  static List<ExtraFoodItem> getServiceExtraFoodItems(String serviceId,
      {bool isJain = false}) {
    if (serviceId == 'kathiyavadi') {
      if (isJain) {
        return [
          ExtraFoodItem(
            id: 'k_jain_1',
            name: 'Paneer Makhmali with Plain Paratha',
            description: 'Creamy paneer curry served with plain paratha',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/paneer_paratha.jpg',
          ),
          ExtraFoodItem(
            id: 'k_jain_2',
            name: 'Doodhi Chana Dal with Jeera Rice',
            description: 'Bottle gourd with split chickpeas and cumin rice',
            price: 100.0,
            category: 'special_combo',
            image: 'assets/images/dal_rice.jpg',
          ),
          ExtraFoodItem(
            id: 'k_jain_3',
            name: 'Cabbage Tomato Curry with Phulka',
            description: 'Fresh cabbage curry with soft phulkas',
            price: 90.0,
            category: 'special_combo',
            image: 'assets/images/curry_roti.jpg',
          ),
          ExtraFoodItem(
            id: 'k_jain_4',
            name: 'Methi Mutter Malai with Rice',
            description: 'Creamy fenugreek and peas curry with rice',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/methi_mutter.jpg',
          ),
          ExtraFoodItem(
            id: 'k_jain_5',
            name: 'Gujarati Dal with Ghee Roti',
            description: 'Traditional Gujarati dal with ghee-laden rotis',
            price: 95.0,
            category: 'special_combo',
            image: 'assets/images/dal_roti.jpg',
          ),
          ExtraFoodItem(
            id: 'k_jain_6',
            name: 'Palak Paneer (No onion-garlic) with Jeera Rice',
            description:
                'Jain-style spinach and cottage cheese curry with cumin rice',
            price: 130.0,
            category: 'special_combo',
            image: 'assets/images/palak_paneer.jpg',
          ),
          ExtraFoodItem(
            id: 'k_jain_7',
            name: 'Tomato Sev Sabji with Plain Roti',
            description: 'Jain-style tomato curry with sev and rotis',
            price: 85.0,
            category: 'special_combo',
            image: 'assets/images/tomato_sev.jpg',
          ),
        ];
      } else {
        return [
          ExtraFoodItem(
            id: 'k_veg_1',
            name: 'Bajra Rotla with Ringan nu Bhartu',
            description: 'Pearl millet flatbread with roasted eggplant mash',
            price: 100.0,
            category: 'special_combo',
            image: 'assets/images/rotla_bhartu.jpg',
          ),
          ExtraFoodItem(
            id: 'k_veg_2',
            name: 'Sev Tameta Sabji with Masala Khichdi',
            description:
                'Tomato curry with crunchy sev and spiced rice-lentil porridge',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/sev_khichdi.jpg',
          ),
          ExtraFoodItem(
            id: 'k_veg_3',
            name: 'Bhindi Masala with Kadhi',
            description: 'Spiced okra with yogurt-based curry',
            price: 95.0,
            category: 'special_combo',
            image: 'assets/images/bhindi_kadhi.jpg',
          ),
          ExtraFoodItem(
            id: 'k_veg_4',
            name: 'Lasaniya Bataka with Bajra Roti',
            description: 'Garlic-flavored potatoes with pearl millet flatbread',
            price: 90.0,
            category: 'special_combo',
            image: 'assets/images/bataka_roti.jpg',
          ),
          ExtraFoodItem(
            id: 'k_veg_5',
            name: 'Methi Thepla with Aloo Tamatar',
            description: 'Fenugreek flatbread with potato-tomato curry',
            price: 85.0,
            category: 'special_combo',
            image: 'assets/images/thepla_aloo.jpg',
          ),
          ExtraFoodItem(
            id: 'k_veg_6',
            name: 'Khichu + Kadhi',
            description: 'Rice flour dumplings with spiced yogurt curry',
            price: 80.0,
            category: 'special_combo',
            image: 'assets/images/khichu_kadhi.jpg',
          ),
          ExtraFoodItem(
            id: 'k_veg_7',
            name: 'Kadhi Khichdi with Papad and Pickle',
            description:
                'Rice-lentil porridge with yogurt curry, papad, and pickle',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/khichdi_combo.jpg',
          ),
        ];
      }
    } else if (serviceId == 'desi_rotalo') {
      if (isJain) {
        return [
          ExtraFoodItem(
            id: 'dr_jain_1',
            name: 'Corn Palak with Rice',
            description:
                'Fresh corn and spinach curry served with steamed rice',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/corn_palak.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_jain_2',
            name: 'Lauki Kofta with Chapati',
            description: 'Bottle gourd dumplings in gravy with fresh chapati',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/lauki_kofta.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_jain_3',
            name: 'Methi Gota with Kadhi',
            description: 'Fenugreek fritters served with spiced yogurt curry',
            price: 100.0,
            category: 'special_combo',
            image: 'assets/images/methi_gota.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_jain_4',
            name: 'Tindora Curry with Phulka',
            description: 'Ivy gourd curry served with soft phulkas',
            price: 95.0,
            category: 'special_combo',
            image: 'assets/images/tindora_curry.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_jain_5',
            name: 'Moong Dal Tadka with Rice',
            description: 'Tempered yellow lentils with steamed rice',
            price: 105.0,
            category: 'special_combo',
            image: 'assets/images/moong_dal.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_jain_6',
            name: 'Jain Paneer Butter Masala',
            description: 'Rich paneer curry without onion-garlic',
            price: 140.0,
            category: 'special_combo',
            image: 'assets/images/jain_paneer.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_jain_7',
            name: 'Chole Paneer with Jeera Rice',
            description: 'Chickpea and paneer curry with cumin rice',
            price: 130.0,
            category: 'special_combo',
            image: 'assets/images/chole_paneer.jpg',
          ),
        ];
      } else {
        return [
          ExtraFoodItem(
            id: 'dr_veg_1',
            name: 'Masala Rotlo with Ringan Rasa',
            description: 'Spiced millet flatbread with eggplant curry',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/masala_rotlo.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_veg_2',
            name: 'Sev Bhaji with Masala Rice',
            description: 'Mixed vegetable curry with sev and spiced rice',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/sev_bhaji.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_veg_3',
            name: 'Papdi Tameta Sabji with Khichdi',
            description:
                'Flat beans and tomato curry with spiced rice-lentil porridge',
            price: 115.0,
            category: 'special_combo',
            image: 'assets/images/papdi_tameta.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_veg_4',
            name: 'Rajma Curry with Jeera Rice',
            description: 'Kidney beans curry with cumin rice',
            price: 125.0,
            category: 'special_combo',
            image: 'assets/images/rajma_rice.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_veg_5',
            name: 'Dhokli nu Shaak with Phulka',
            description: 'Traditional Gujarati curry with wheat dumplings',
            price: 105.0,
            category: 'special_combo',
            image: 'assets/images/dhokli.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_veg_6',
            name: 'Dal Dhokli (Kathiyavadi Style)',
            description: 'Spiced lentils with wheat dumplings',
            price: 95.0,
            category: 'special_combo',
            image: 'assets/images/dal_dhokli.jpg',
          ),
          ExtraFoodItem(
            id: 'dr_veg_7',
            name: 'Mix Veg Curry with Bajra Rotlo',
            description: 'Mixed vegetable curry with millet flatbread',
            price: 100.0,
            category: 'special_combo',
            image: 'assets/images/mix_veg_rotlo.jpg',
          ),
        ];
      }
    } else if (serviceId == 'nani') {
      if (isJain) {
        return [
          ExtraFoodItem(
            id: 'n_jain_1',
            name: 'Veg Kofta Curry with Plain Roti',
            description: 'Mixed vegetable dumplings in curry with rotis',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/veg_kofta.jpg',
          ),
          ExtraFoodItem(
            id: 'n_jain_2',
            name: 'Methi Mutter Curry with Rice',
            description: 'Fenugreek and peas curry with steamed rice',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/methi_mutter.jpg',
          ),
          ExtraFoodItem(
            id: 'n_jain_3',
            name: 'Paneer Pasanda (No Onion Garlic)',
            description: 'Stuffed paneer curry without onion-garlic',
            price: 140.0,
            category: 'special_combo',
            image: 'assets/images/paneer_pasanda.jpg',
          ),
          ExtraFoodItem(
            id: 'n_jain_4',
            name: 'Kadhi Pakora Jain Style',
            description: 'Spiced yogurt curry with fritters',
            price: 100.0,
            category: 'special_combo',
            image: 'assets/images/kadhi_pakora.jpg',
          ),
          ExtraFoodItem(
            id: 'n_jain_5',
            name: 'Sweet Corn Curry with Paratha',
            description: 'Creamy corn curry with flaky paratha',
            price: 115.0,
            category: 'special_combo',
            image: 'assets/images/corn_curry.jpg',
          ),
          ExtraFoodItem(
            id: 'n_jain_6',
            name: 'Dal Palak with Jeera Rice',
            description: 'Lentils with spinach and cumin rice',
            price: 105.0,
            category: 'special_combo',
            image: 'assets/images/dal_palak.jpg',
          ),
          ExtraFoodItem(
            id: 'n_jain_7',
            name: 'Bhindi Tomato Curry with Phulka',
            description: 'Okra and tomato curry with soft phulkas',
            price: 95.0,
            category: 'special_combo',
            image: 'assets/images/bhindi_tomato.jpg',
          ),
        ];
      } else {
        return [
          ExtraFoodItem(
            id: 'n_veg_1',
            name: 'Aloo Gobi with Chapati',
            description: 'Potato and cauliflower curry with fresh chapati',
            price: 100.0,
            category: 'special_combo',
            image: 'assets/images/aloo_gobi.jpg',
          ),
          ExtraFoodItem(
            id: 'n_veg_2',
            name: 'Mutter Paneer with Jeera Rice',
            description: 'Peas and cottage cheese curry with cumin rice',
            price: 130.0,
            category: 'special_combo',
            image: 'assets/images/mutter_paneer.jpg',
          ),
          ExtraFoodItem(
            id: 'n_veg_3',
            name: 'Karela Batata with Roti',
            description: 'Bitter gourd and potato curry with roti',
            price: 95.0,
            category: 'special_combo',
            image: 'assets/images/karela_batata.jpg',
          ),
          ExtraFoodItem(
            id: 'n_veg_4',
            name: 'Palak Dal with Khichdi',
            description: 'Spinach lentils with rice-lentil porridge',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/palak_dal.jpg',
          ),
          ExtraFoodItem(
            id: 'n_veg_5',
            name: 'Mix Dal Fry with Rice',
            description: 'Mixed lentils tempered with spices and rice',
            price: 105.0,
            category: 'special_combo',
            image: 'assets/images/mix_dal.jpg',
          ),
          ExtraFoodItem(
            id: 'n_veg_6',
            name: 'Veg Handvo Slice with Chutney',
            description: 'Savory lentil cake with spicy chutney',
            price: 90.0,
            category: 'special_combo',
            image: 'assets/images/handvo.jpg',
          ),
          ExtraFoodItem(
            id: 'n_veg_7',
            name: 'Bharela Ringan with Masala Rotlo',
            description: 'Stuffed eggplant with spiced millet flatbread',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/bharela_ringan.jpg',
          ),
        ];
      }
    } else if (serviceId == 'rajwadi') {
      if (isJain) {
        return [
          ExtraFoodItem(
            id: 'r_jain_1',
            name: 'Jain Shahi Paneer with Naan',
            description: 'Rich paneer curry without onion-garlic with naan',
            price: 150.0,
            category: 'special_combo',
            image: 'assets/images/shahi_paneer.jpg',
          ),
          ExtraFoodItem(
            id: 'r_jain_2',
            name: 'Lauki Methi Curry with Jeera Rice',
            description: 'Bottle gourd and fenugreek curry with cumin rice',
            price: 120.0,
            category: 'special_combo',
            image: 'assets/images/lauki_methi.jpg',
          ),
          ExtraFoodItem(
            id: 'r_jain_3',
            name: 'Dal Makhani (No Onion Garlic)',
            description: 'Creamy black lentils without onion-garlic',
            price: 130.0,
            category: 'special_combo',
            image: 'assets/images/dal_makhani.jpg',
          ),
          ExtraFoodItem(
            id: 'r_jain_4',
            name: 'Mix Veg Handi with Chapati',
            description: 'Mixed vegetables in special gravy with chapati',
            price: 125.0,
            category: 'special_combo',
            image: 'assets/images/mix_veg_handi.jpg',
          ),
          ExtraFoodItem(
            id: 'r_jain_5',
            name: 'Paneer Tikka Masala (Jain Style)',
            description: 'Grilled paneer in spiced gravy without onion-garlic',
            price: 145.0,
            category: 'special_combo',
            image: 'assets/images/paneer_tikka.jpg',
          ),
          ExtraFoodItem(
            id: 'r_jain_6',
            name: 'Tindora Masala with Bajra Rotlo',
            description: 'Spiced ivy gourd with millet flatbread',
            price: 110.0,
            category: 'special_combo',
            image: 'assets/images/tindora_masala.jpg',
          ),
          ExtraFoodItem(
            id: 'r_jain_7',
            name: 'Veg Korma (Jain) with Butter Rice',
            description: 'Mixed vegetable korma with buttered rice',
            price: 135.0,
            category: 'special_combo',
            image: 'assets/images/veg_korma.jpg',
          ),
        ];
      } else {
        return [
          ExtraFoodItem(
            id: 'r_veg_1',
            name: 'Rajwadi Paneer with Masala Paratha',
            description: 'Spicy paneer curry with flaky spiced paratha',
            price: 160.0,
            category: 'special_combo',
            image: 'assets/images/rajwadi_paneer.jpg',
          ),
          ExtraFoodItem(
            id: 'r_veg_2',
            name: 'Dum Aloo with Kashmiri Rice',
            description: 'Baby potatoes in rich gravy with aromatic rice',
            price: 140.0,
            category: 'special_combo',
            image: 'assets/images/dum_aloo.jpg',
          ),
          ExtraFoodItem(
            id: 'r_veg_3',
            name: 'Veg Korma with Naan',
            description: 'Mixed vegetable curry in rich gravy with naan',
            price: 150.0,
            category: 'special_combo',
            image: 'assets/images/veg_korma_naan.jpg',
          ),
          ExtraFoodItem(
            id: 'r_veg_4',
            name: 'Shahi Bhindi with Butter Roti',
            description: 'Royal okra curry with buttered flatbread',
            price: 130.0,
            category: 'special_combo',
            image: 'assets/images/shahi_bhindi.jpg',
          ),
          ExtraFoodItem(
            id: 'r_veg_5',
            name: 'Gatte ki Sabji with Jeera Rice',
            description: 'Gram flour dumplings curry with cumin rice',
            price: 135.0,
            category: 'special_combo',
            image: 'assets/images/gatte_sabji.jpg',
          ),
          ExtraFoodItem(
            id: 'r_veg_6',
            name: 'Veg Jalfrezi with Pulao',
            description: 'Mixed vegetable stir-fry with spiced rice',
            price: 145.0,
            category: 'special_combo',
            image: 'assets/images/veg_jalfrezi.jpg',
          ),
          ExtraFoodItem(
            id: 'r_veg_7',
            name: 'Veg Kolhapuri with Lachha Paratha',
            description: 'Spicy mixed vegetable curry with layered flatbread',
            price: 155.0,
            category: 'special_combo',
            image: 'assets/images/veg_kolhapuri.jpg',
          ),
        ];
      }
    }
    return getBaseExtraFoodItems();
  }
}
