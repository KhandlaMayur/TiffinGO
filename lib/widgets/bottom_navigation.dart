import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../screens/subscription_screen.dart';
import 'order_history_screen.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            label: 'Home',
            onTap: () {
              // Already on home screen
            },
            isActive: true,
          ),
          _buildNavItem(
            context,
            icon: Icons.history,
            label: 'History',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
            isActive: false,
          ),
          _buildNavItem(
            context,
            icon: Icons.favorite,
            label: 'Favorites',
            onTap: () {
              _showFavoritesDialog(context);
            },
            isActive: false,
          ),
          _buildNavItem(
            context,
            icon: Icons.subscriptions,
            label: 'Subscription',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            isActive: false,
          ),
          _buildNavItem(
            context,
            icon: Icons.support_agent,
            label: 'Support',
            onTap: () {
              _showSupportDialog(context);
            },
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFavoritesDialog(BuildContext context) {
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
            title: const Text(
              'Favorite Services',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.favoriteServices.isEmpty) {
                  return const Text('No favorite services yet.');
                }
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderProvider.favoriteServices.length,
                    itemBuilder: (context, index) {
                      final service = orderProvider.favoriteServices[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.restaurant,
                          color: Color(0xFF1E3A8A),
                        ),
                        title: Text(service),
                        trailing: IconButton(
                          onPressed: () {
                            orderProvider.removeFromFavorites(service);
                          },
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupportDialog(BuildContext context) {
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
            title: const Text(
              'Support',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact Information:'),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.phone, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text('+91 9316161597'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text('tiffingo13@tiffineservice.com'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text('24/7 Customer Support'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
