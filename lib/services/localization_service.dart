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
      'are_you_sure_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'not_set': 'Not set',
    },
  };

  String translate(String key) {
    return _localizedStrings[locale]?[key] ?? key;
  }

  // static String getLanguageName(String locale) {
  //   switch (locale) {
  //     case 'gu':
  //       return 'Gujarati';
  //     case 'hi':
  //       return 'Hindi';
  //     case 'en':
  //     default:
  //       return 'English';
  //   }
  // }
}
