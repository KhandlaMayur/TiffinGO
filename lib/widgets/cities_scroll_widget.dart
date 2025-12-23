import 'package:flutter/material.dart';
import 'dart:async';

class CitiesScrollWidget extends StatefulWidget {
  final ScrollController? scrollController;

  const CitiesScrollWidget({super.key, this.scrollController});

  @override
  State<CitiesScrollWidget> createState() => _CitiesScrollWidgetState();
}

class _CitiesScrollWidgetState extends State<CitiesScrollWidget> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _cities = [
    {
      'name': 'Surendranagar',
      'description': 'Authentic Gujarati cuisine with traditional flavors',
      'image': 'assets/images/surendranagar.jpg',
      'services': 'Kathiyavadi, Desi Rotalo, Nani Tiffine',
    },
    {
      'name': 'Rajkot',
      'description': 'Modern city with diverse food options and quick delivery',
      'image': 'assets/images/rajkot.jpg',
      'services': 'Rajwadi, Kathiyavadi, Desi Rotalo',
    },
    {
      'name': 'Ahmedabad',
      'description': 'Metropolitan food scene with premium tiffine services',
      'image': 'assets/images/ahmedabad.jpg',
      'services': 'All services available with premium quality',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  void _onScroll() {
    // Sync city scroll with services scroll
    if (widget.scrollController != null && _pageController.hasClients) {
      final scrollPosition = widget.scrollController!.offset;
      final maxScroll = widget.scrollController!.position.maxScrollExtent;
      if (maxScroll > 0) {
        final scrollRatio = scrollPosition / maxScroll;
        final targetPage = (scrollRatio * _cities.length).floor();
        if (targetPage != _currentIndex && targetPage < _cities.length) {
          _currentIndex = targetPage;
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    // slower auto-scroll so users have time to read content on mobile
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentIndex = (_currentIndex + 1) % _cities.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // make the card height responsive to device height so it looks good on phones
    final double cardHeight = (MediaQuery.of(context).size.height * 0.26)
        .clamp(180.0, 260.0)
        .toDouble();

    return Column(
      children: [
        // Banner under search bar, above scroll container
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: const Text(
            'Tiffine Service Available In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  offset: Offset(0, 0.8),
                  blurRadius: 3,
                  color: Colors.black38,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          height: cardHeight,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return _buildCityCard(city);
                  },
                ),
                // Page indicators (larger on mobile for better affordance)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _cities.length,
                      (index) {
                        final isActive = _currentIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: isActive ? 14 : 10,
                          height: isActive ? 6 : 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityCard(Map<String, dynamic> city) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (with graceful fallback if image is invalid)
          Image.asset(
            city['image'],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[700],
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 56,
                    color: Colors.white70,
                  ),
                ),
              );
            },
          ),

          // Darker overlay to guarantee text contrast across diverse images
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // stronger at the top where the title sits
                  Colors.black.withOpacity(0.60),
                  // still provides contrast at the bottom
                  Colors.black.withOpacity(0.30),
                ],
              ),
            ),
          ),

          // Foreground content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            city['description'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 0.8),
                                  blurRadius: 3,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          city['services'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 0.6),
                                blurRadius: 3,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
