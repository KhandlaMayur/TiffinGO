import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

import '../widgets/account_drawer.dart';
import '../widgets/cities_scroll_widget.dart';
import '../widgets/tiffine_services_list.dart';
import '../widgets/bottom_navigation.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  // show or hide cities on list scroll
  bool _showCities = true;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onMainScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final contact =
          authProvider.currentUser?.contact ?? authProvider.currentUser?.email;
      if (contact != null) {
        Provider.of<SubscriptionProvider>(context, listen: false)
            .syncWithFirestore(contact);
      }
    });
  }

  void _onMainScroll() {
    final offset = _scrollController.offset;
    const threshold = 12; // prevents rapid toggles from small moves

    if (offset > _lastScrollOffset + threshold && _showCities) {
      setState(() => _showCities = false);
    } else if (offset < _lastScrollOffset - threshold && !_showCities) {
      setState(() => _showCities = true);
    }

    _lastScrollOffset = offset;
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onMainScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationProvider.currentLocation,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  icon: const Icon(Icons.account_circle, size: 30),
                );
              },
            ),
          ],
        ),
        endDrawer: const AccountDrawer(),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Tiffine Services...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            // Cities Scroll Widget (animated show/hide when main list scrolls)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showCities
                  ? CitiesScrollWidget(
                      scrollController: _scrollController,
                    )
                  : const SizedBox.shrink(),
            ),
            // Tiffine Services List
            Expanded(
              child: TiffineServicesList(
                searchQuery: _searchQuery,
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
        bottomNavigationBar: const BottomNavigation(),
      ),
    );
  }
}
