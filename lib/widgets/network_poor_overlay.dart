import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_provider.dart';

/// Enhanced network monitoring overlay that displays a centered container
/// with "Poor Connection" message when the network is slow or unavailable.
///
/// Features:
/// - Centered container with "Poor Connection" message
/// - Blocks all user interaction with modal barrier
/// - Shows connection status and speed details
/// - Manual retry button for immediate connection check
/// - Auto-retries periodically
/// - Smooth fade in/out animations
/// - Prevents app operations without valid connection
class NetworkPoorOverlay extends StatefulWidget {
  const NetworkPoorOverlay({super.key});

  @override
  State<NetworkPoorOverlay> createState() => _NetworkPoorOverlayState();
}

class _NetworkPoorOverlayState extends State<NetworkPoorOverlay>
    with TickerProviderStateMixin {
  bool _isVisible = false;
  Timer? _retryTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  /// Handles network status changes
  void _handleNetworkStatusChange(NetworkProvider network) {
    final shouldShow = network.isPoor;

    if (shouldShow && !_isVisible) {
      _showOverlay(network);
    } else if (!shouldShow && _isVisible) {
      _hideOverlay();
    }
  }

  /// Shows the overlay with fade animation
  void _showOverlay(NetworkProvider network) {
    if (_isVisible) return;

    _isVisible = true;
    _fadeController.forward();
    _scheduleAutoRetry(network);

    debugPrint('[Network] Poor connection overlay shown');
  }

  /// Hides the overlay with fade animation
  void _hideOverlay() {
    if (!_isVisible) return;

    _isVisible = false;
    _fadeController.reverse();
    _retryTimer?.cancel();

    debugPrint('[Network] Poor connection overlay hidden');
  }

  /// Schedules automatic retry check
  void _scheduleAutoRetry(NetworkProvider network) {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isVisible) {
        debugPrint('[Network] Auto-retry triggered');
        network.performCheck();
      }
    });
  }

  /// Manual retry triggered by user
  Future<void> _manualRetry(NetworkProvider network) async {
    debugPrint('[Network] Manual retry triggered');
    await network.performCheck();

    if (mounted) {
      if (!network.isPoor) {
        _hideOverlay();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Connection restored!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _scheduleAutoRetry(network);
      }
    }
  }

  /// Builds status detail text
  Widget _buildStatusDetails(NetworkProvider network) {
    String status = network.statusMessage;
    String? speedText;

    if (network.speedMbps != null) {
      speedText = '${network.speedMbps!.toStringAsFixed(2)} Mbps';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          status,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (speedText != null)
          Text(
            'Speed: $speedText',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Text(
            'Checking connection...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, network, child) {
        _handleNetworkStatusChange(network);

        if (!_isVisible) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Semi-transparent barrier that blocks user interaction
              ModalBarrier(
                color: Colors.black54,
                dismissible: false,
                onDismiss: () {},
              ),
              // Centered container with "Poor Connection" message
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            network.hasConnection
                                ? Icons
                                    .signal_cellular_connected_no_internet_0_bar
                                : Icons.wifi_off,
                            size: 56,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Main heading
                        Text(
                          'Poor Connection',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Status details
                        _buildStatusDetails(network),
                        const SizedBox(height: 12),
                        // Helper message
                        Text(
                          'The app requires a stable internet connection to continue.\n'
                          'Please check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 28),
                        // Action buttons
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _manualRetry(network),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Auto-retrying in 15 seconds...',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
