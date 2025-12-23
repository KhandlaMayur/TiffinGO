import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../screens/auth/login_screen.dart';
import 'edit_profile_dialog.dart';
import 'address_section.dart';

class AccountDrawer extends StatefulWidget {
  const AccountDrawer({super.key});

  @override
  State<AccountDrawer> createState() => _AccountDrawerState();
}

class _AccountDrawerState extends State<AccountDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer2<AuthProvider, FirebaseAuthProvider>(
        builder: (context, authProvider, firebaseAuthProvider, child) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]),
                    child: SafeArea(
                      child: Stack(
                        children: [
                          // Back button at top left
                          Positioned(
                            left: 8,
                            top: 8,
                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          // Profile content
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        // Prefer Firebase user doc if available, else local authProvider
                                        (firebaseAuthProvider
                                                    .userDoc?['fullName']
                                                as String?) ??
                                            (firebaseAuthProvider
                                                .userDoc?['name'] as String?) ??
                                            (firebaseAuthProvider
                                                    .userDoc?['displayName']
                                                as String?) ??
                                            authProvider
                                                .currentUser?.fullName ??
                                            'User',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        (firebaseAuthProvider.userDoc?['phone']
                                                as String?) ??
                                            (firebaseAuthProvider
                                                    .userDoc?['contact']
                                                as String?) ??
                                            authProvider.currentUser?.contact ??
                                            'Contact',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // User Details Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Account Details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _showEditProfileDialog(context, authProvider);
                              },
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(context).primaryColor,
                                size: 18,
                              ),
                              label: Text(
                                'Edit',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Column(
                          children: [
                            _buildDetailRow(
                              Icons.person,
                              'Full Name',
                              (firebaseAuthProvider
                                      .userDoc?['fullName'] as String?) ??
                                  (firebaseAuthProvider.userDoc?['name']
                                      as String?) ??
                                  (firebaseAuthProvider.userDoc?['displayName']
                                      as String?) ??
                                  authProvider.currentUser?.fullName ??
                                  'Not Set',
                            ),
                            _buildDetailRow(
                              Icons.email,
                              'Email',
                              (firebaseAuthProvider.userDoc?['email']
                                      as String?) ??
                                  authProvider.currentUser?.email ??
                                  'Not Set',
                            ),
                            _buildDetailRow(
                              Icons.phone,
                              'Contact',
                              (firebaseAuthProvider.userDoc?['phone']
                                      as String?) ??
                                  (firebaseAuthProvider.userDoc?['contact']
                                      as String?) ??
                                  authProvider.currentUser?.contact ??
                                  'Not Set',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Preferences Section (Theme & Language)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferences',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 15),
                        // Theme Toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        themeProvider.isDarkMode
                                            ? Icons.dark_mode
                                            : Icons.light_mode,
                                        color: Theme.of(context).primaryColor,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        themeProvider.isDarkMode
                                            ? 'Dark Mode'
                                            : 'Light Mode',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: themeProvider.isDarkMode,
                                    onChanged: (_) {
                                      themeProvider.toggleTheme();
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // My Account Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Account',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 15),
                        // Favorite Tiffine Services
                        Consumer<OrderProvider>(
                          builder: (context, orderProvider, child) {
                            return Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Favorite Services',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (orderProvider.favoriteServices.isEmpty)
                                    Text(
                                      'No favorite services yet',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    )
                                  else
                                    ...orderProvider.favoriteServices
                                        .map(
                                          (service) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.restaurant,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    service,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Address Section
                        const AddressSection(),
                        const SizedBox(height: 20),
                        // Terms & Conditions Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _showTermsAndConditions(context),
                            icon: Icon(
                              Icons.description_outlined,
                              color: Theme.of(context).primaryColor,
                            ),
                            label: Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showLogoutDialog(context, authProvider);
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(authProvider: authProvider),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: AlertDialog(
            title: Text(
              'TiffinGO - Terms & Conditions',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '1. Service Usage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'TiffinGO provides a platform for ordering and delivering tiffin services. Users must be 18 years or older to use our services.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '2. Order & Delivery',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'Orders are subject to availability and delivery location. Delivery times are approximate and may vary based on location and traffic conditions.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '3. Payment & Refunds',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'All payments are processed securely. Refunds are subject to our refund policy and must be requested within 24 hours of delivery.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '4. Privacy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'We protect your personal information and use it only for service delivery and account management purposes.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
