/// NETWORK MONITORING IMPLEMENTATION GUIDE
///
/// This file contains comprehensive examples of how to use the new
/// network monitoring system in your Flutter app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/network_provider.dart';
import 'services/offline_operation_service.dart';
import 'services/network_operation_interceptor.dart';

/// ============================================================================
/// EXAMPLE 1: Check Network Status Before Operation
/// ============================================================================
///
/// Use this pattern when you need to verify connection before starting
/// any network-dependent operation.

Future<void> exampleCheckNetworkStatus() async {
  // Get network provider from context or inject it
  // final networkProvider = Provider.of<NetworkProvider>(context, listen: false);

  // Check if connection is good
  // if (networkProvider.canProceed()) {
  //   // Safe to proceed with operations
  //   await performNetworkOperation();
  // } else {
  //   // Show error to user
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(networkProvider.getErrorMessage())),
  //   );
  // }
}

/// ============================================================================
/// EXAMPLE 2: Execute Operation with Network Check
/// ============================================================================
///
/// This pattern prevents operations from running without connection
/// and provides automatic error handling.

Future<void> exampleExecuteWithNetworkCheck(
  NetworkProvider networkProvider,
) async {
  try {
    final result = await NetworkOperationInterceptor.executeWithNetworkCheck(
      operation: () => _fetchUserData(),
      operationName: 'Fetch User Data',
      networkProvider: networkProvider,
      onNetworkError: () {
        print('Network error occurred - user will see overlay');
      },
    );
    print('Success: $result');
  } on NetworkException catch (e) {
    print('Operation failed: ${e.message}');
  }
}

/// ============================================================================
/// EXAMPLE 3: Execute Operation and Queue if Offline
/// ============================================================================
///
/// This pattern allows operations to proceed online, and queues them
/// for sync when offline. Critical for operations you don't want to lose.

Future<void> exampleExecuteWithOfflineSupport(
  NetworkProvider networkProvider,
  OfflineOperationService offlineService,
) async {
  try {
    final result = await NetworkOperationInterceptor.executeWithOfflineSupport(
      operation: () => _placeOrder(
        orderId: '12345',
        items: ['item1', 'item2'],
      ),
      operationName: 'Place Order',
      operationType: 'order_placement',
      operationData: {
        'orderId': '12345',
        'items': ['item1', 'item2'],
        'timestamp': DateTime.now().toIso8601String(),
      },
      networkProvider: networkProvider,
      offlineService: offlineService,
      onNetworkError: () {
        print('Operation queued for offline sync');
      },
    );

    if (result != null) {
      print('Order placed successfully: $result');
    } else {
      print('Order queued for offline sync');
    }
  } catch (e) {
    print('Error: $e');
  }
}

/// ============================================================================
/// EXAMPLE 4: Wait for Connection Then Execute
/// ============================================================================
///
/// This pattern waits for a good connection before executing,
/// useful for critical operations that must succeed.

Future<void> exampleWaitForConnection(
  NetworkProvider networkProvider,
) async {
  try {
    final result = await NetworkOperationInterceptor.executeWhenConnected(
      operation: () => _syncCriticalData(),
      operationName: 'Sync Critical Data',
      networkProvider: networkProvider,
      maxWaitTime: const Duration(minutes: 5),
    );
    print('Critical data synced: $result');
  } on NetworkException catch (e) {
    print('Failed after waiting for connection: ${e.message}');
  }
}

/// ============================================================================
/// EXAMPLE 5: Listen to Network Status Changes
/// ============================================================================
///
/// This pattern provides real-time updates of network status changes
/// throughout your app.

void exampleListenToNetworkChanges(NetworkProvider networkProvider) {
  // Add callback for network status changes
  networkProvider.addStatusCallback((isConnected, isPoor) {
    print('Connection status changed:');
    print('  - Connected: $isConnected');
    print('  - Poor connection: $isPoor');
    print('  - Status: ${networkProvider.statusMessage}');

    // You can trigger syncs, UI updates, etc. here
    if (isConnected && !isPoor) {
      print('Good connection - syncing queued operations');
      // syncQueuedOperations();
    }
  });
}

/// ============================================================================
/// EXAMPLE 6: Use in Widget with Consumer
/// ============================================================================
///
/// This pattern is best for displaying network status in UI

class ExampleNetworkAwareWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkProvider, OfflineOperationService>(
      builder: (context, networkProvider, offlineService, child) {
        // Show different UI based on connection
        if (!networkProvider.hasConnection) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('No Connection'),
              ],
            ),
          );
        }

        if (networkProvider.isPoor) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.signal_cellular_connected_no_internet_0_bar,
                  size: 48,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text('Poor Connection - ${networkProvider.speedMbps} Mbps'),
              ],
            ),
          );
        }

        // Proceed with normal UI
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              SizedBox(height: 16),
              Text('Good Connection - ${networkProvider.speedMbps} Mbps'),
              if (offlineService.hasPendingOperations) ...[
                SizedBox(height: 16),
                Text(
                  'Pending operations: ${offlineService.pendingCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================================
/// EXAMPLE 7: Sync Queued Operations When Connection Restored
/// ============================================================================
///
/// This pattern ensures no data is lost by syncing operations when
/// connection is restored.

Future<void> exampleSyncQueuedOperations(
  NetworkProvider networkProvider,
  OfflineOperationService offlineService,
) async {
  // Monitor for good connection
  networkProvider.addStatusCallback((isConnected, isPoor) {
    if (isConnected && !isPoor) {
      print('Good connection restored - syncing pending operations');
      _syncAllQueuedOperations(offlineService);
    }
  });
}

Future<void> _syncAllQueuedOperations(
  OfflineOperationService offlineService,
) async {
  print('Starting sync of ${offlineService.pendingCount} pending operations');

  for (final operation in offlineService.pendingOperations) {
    try {
      // Handle different operation types
      switch (operation.operationType) {
        case 'order_placement':
          await _syncOrderPlacement(operation.data);
          break;
        case 'subscription_update':
          await _syncSubscriptionUpdate(operation.data);
          break;
        case 'profile_update':
          await _syncProfileUpdate(operation.data);
          break;
      }

      // Mark as synced after successful completion
      await offlineService.markAsSynced(operation.id);
      print('Operation synced: ${operation.id}');
    } catch (e) {
      // Mark as failed if sync fails
      await offlineService.markAsFailed(operation.id, e.toString());
      print('Failed to sync operation ${operation.id}: $e');
    }
  }

  print('Sync completed');
}

/// ============================================================================
/// EXAMPLE 8: Prevent UI Interaction During Network Issues
/// ============================================================================
///
/// The NetworkPoorOverlay automatically handles this by showing
/// a centered container that blocks all interaction.
/// But here's how to manually disable buttons/forms:

class ExampleFormWithNetworkCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        final isEnabled = networkProvider.isGood;

        return Column(
          children: [
            TextField(
              enabled: isEnabled,
              decoration: InputDecoration(
                hintText: 'Enter data',
                suffixIcon: isEnabled
                    ? null
                    : Tooltip(
                        message: 'Network unavailable',
                        child: Icon(Icons.signal_cellular_off),
                      ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isEnabled
                  ? () => _submitForm(context, networkProvider)
                  : null,
              child: Text(isEnabled ? 'Submit' : 'No Connection'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm(
    BuildContext context,
    NetworkProvider networkProvider,
  ) async {
    try {
      if (!networkProvider.canProceed()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(networkProvider.getErrorMessage())),
        );
        return;
      }

      // Proceed with submission
      print('Form submitted successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// ============================================================================
/// EXAMPLE 9: Query Offline Operations
/// ============================================================================

void exampleQueryOfflineOperations(OfflineOperationService offlineService) {
  // Get pending operations
  final pending = offlineService.pendingOperations;
  print('Pending operations: ${pending.length}');

  // Get operations by type
  final orders = offlineService.getPendingByType('order_placement');
  print('Pending orders: ${orders.length}');

  // Get retry info
  if (pending.isNotEmpty) {
    final retryInfo = offlineService.getRetryInfo(pending.first.id);
    print('Retry info: $retryInfo');
  }

  // Clear synced operations to save storage
  offlineService.clearSyncedOperations();

  print('Offline operations queried');
}

/// ============================================================================
/// EXAMPLE 10: Best Practices Summary
/// ============================================================================

/// BEST PRACTICES:
///
/// 1. NETWORK CHECKS:
///    - Always check networkProvider.canProceed() before important operations
///    - Use executeWithNetworkCheck for safe, automatic handling
///    - Use executeWithOfflineSupport for operations you want to preserve
///
/// 2. USER FEEDBACK:
///    - The NetworkPoorOverlay automatically shows when connection is poor
///    - Provide additional in-app feedback for better UX
///    - Show pending operation count to users
///
/// 3. DATA PERSISTENCE:
///    - Queue critical operations using offlineService.queueOperation()
///    - Sync when connection restored
///    - Implement retry logic for failed syncs
///
/// 4. OPERATION TYPES:
///    - Categorize operations ('order', 'subscription', 'profile', etc.)
///    - Handle each type separately during sync
///    - Log operation status for debugging
///
/// 5. ERROR HANDLING:
///    - Catch NetworkException for network-specific errors
///    - Catch TimeoutException for slow connections
///    - Provide meaningful error messages to users
///
/// 6. MONITORING:
///    - Use addStatusCallback() to monitor connection changes
///    - Listen to pending operation changes
///    - Log network events for debugging
///
/// 7. CLEANUP:
///    - Clear synced operations periodically to save storage
///    - Remove status callbacks when no longer needed
///    - Properly dispose of resources
///
/// 8. TESTING:
///    - Test with network enabled (networkProvider.isGood)
///    - Test with network disabled (networkProvider.isPoor)
///    - Test operation queuing and syncing
///    - Verify no data loss during transitions

// Placeholder functions for examples
Future<String> _fetchUserData() async => 'user_data';
Future<String> _placeOrder({
  required String orderId,
  required List<String> items,
}) async =>
    'order_placed';
Future<String> _syncCriticalData() async => 'synced';
Future<void> _syncOrderPlacement(Map<String, dynamic> data) async {}
Future<void> _syncSubscriptionUpdate(Map<String, dynamic> data) async {}
Future<void> _syncProfileUpdate(Map<String, dynamic> data) async {}
