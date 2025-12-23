class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static const List<String> supportedLocales = ['en', 'gu', 'hi'];

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'account': 'Account',
      'account_details': 'Account Details',
      'edit': 'Edit',
      'full_name': 'Full Name',
      'email': 'Email',
      'contact': 'Contact',
      'my_account': 'My Account',
      'favorite_services': 'Favorite Tiffine Services',
      'no_favorites': 'No favorite services yet',
      'address': 'Address',
      'terms_conditions': 'Terms & Conditions',
      'logout': 'Logout',
      'preferences': 'Preferences',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'language': 'Language',
      'english': 'English',
      'gujarati': 'Gujarati',
      'hindi': 'Hindi',
      'are_you_sure_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'not_set': 'Not set',
    },
    'gu': {
      'account': 'ખાતું',
      'account_details': 'ખાતાની વિગતો',
      'edit': 'સંપાદિત કરો',
      'full_name': 'સંપૂર્ણ નામ',
      'email': 'ઈમેઈલ',
      'contact': 'સંપર્ક',
      'my_account': 'મારું ખાતું',
      'favorite_services': 'પ્રિય ટિફિન સેવાઓ',
      'no_favorites': 'હજુ કોઈ પ્રિય સેવાઓ નથી',
      'address': 'સરનામું',
      'terms_conditions': 'શરતો અને શરતો',
      'logout': 'લોગ આઉટ',
      'preferences': 'પ્રાધાન્યતાઓ',
      'theme': 'થીમ',
      'dark_mode': 'ડાર્ક મોડ',
      'light_mode': 'લાઇટ મોડ',
      'language': 'ભાષા',
      'english': 'English',
      'gujarati': 'ગુજરાતી',
      'hindi': 'हिन्दी',
      'are_you_sure_logout': 'શું તમે ચોક્કસ છો કે તમે લોગ આઉટ કરવા માંગો છો?',
      'cancel': 'રદ કરો',
      'not_set': 'સેટ કર્યું નથી',
    },
    'hi': {
      'account': 'खाता',
      'account_details': 'खाता विवरण',
      'edit': 'संपादित करें',
      'full_name': 'पूरा नाम',
      'email': 'ईमेल',
      'contact': 'संपर्क',
      'my_account': 'मेरा खाता',
      'favorite_services': 'पसंदीदा टिफिन सेवाएं',
      'no_favorites': 'अभी तक कोई पसंदीदा सेवाएं नहीं',
      'address': 'पता',
      'terms_conditions': 'नियम और शर्तें',
      'logout': 'लॉग आउट',
      'preferences': 'प्राथमिकताएं',
      'theme': 'थीम',
      'dark_mode': 'डार्क मोड',
      'light_mode': 'लाइट मोड',
      'language': 'भाषा',
      'english': 'English',
      'gujarati': 'ગુજરાતી',
      'hindi': 'हिन्दी',
      'are_you_sure_logout':
          'क्या आप निश्चित हैं कि आप लॉग आउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'not_set': 'सेट नहीं',
    },
  };

  String translate(String key) {
    return _localizedStrings[locale]?[key] ?? key;
  }

  static String getLanguageName(String locale) {
    switch (locale) {
      case 'gu':
        return 'Gujarati';
      case 'hi':
        return 'Hindi';
      case 'en':
      default:
        return 'English';
    }
  }
}
